import { create } from 'zustand';
import type { Quest, QuestObjective } from '../types/quest';

// ============================================================
// 퀘스트 스토어 타입
// ============================================================

interface QuestState {
    // 전체 퀘스트 목록
    allQuests: Quest[];

    // 상태별 퀘스트
    activeQuests: Quest[];      // 진행 중
    completedQuests: Quest[];   // 완료됨
    unlockedQuests: Quest[];    // 해금됨 (시작 가능)
    lockedQuests: Quest[];      // 잠금됨

    // 현재 선택된 퀘스트
    currentQuest: Quest | null;

    // 로딩 상태
    isLoading: boolean;

    // 액션
    loadQuests: () => Promise<void>;
    selectQuest: (questId: string) => void;

    // 목표 완료 체크
    checkGPSObjective: (lat: number, lng: number) => void;
    checkStoryObjective: (nodeId: string) => void;

    // 퀘스트 상태 변경 (API 연동)
    completeObjective: (questId: string, objectiveId: string) => Promise<void>;
    completeQuest: (questId: string) => Promise<void>;
    unlockQuest: (questId: string) => void;
    activateQuest: (questId: string) => Promise<void>;

    // 유틸리티
    getQuestById: (questId: string) => Quest | undefined;
    getObjectiveProgress: (questId: string) => { completed: number; total: number };
}

// ============================================================
// 쿠키 기반 인증 사용 (credentials: 'include')
// ============================================================

// ============================================================
// 거리 계산 함수
// ============================================================

function calculateDistance(lat1: number, lng1: number, lat2: number, lng2: number): number {
    const R = 6371000; // 지구 반경 (미터)
    const φ1 = lat1 * Math.PI / 180;
    const φ2 = lat2 * Math.PI / 180;
    const Δφ = (lat2 - lat1) * Math.PI / 180;
    const Δλ = (lng2 - lng1) * Math.PI / 180;

    const a = Math.sin(Δφ / 2) * Math.sin(Δφ / 2) +
        Math.cos(φ1) * Math.cos(φ2) *
        Math.sin(Δλ / 2) * Math.sin(Δλ / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return R * c;
}

// ============================================================
// 퀘스트 분류 함수
// ============================================================

function categorizeQuests(quests: Quest[]) {
    const active: Quest[] = [];
    const completed: Quest[] = [];
    const unlocked: Quest[] = [];
    const locked: Quest[] = [];

    quests.forEach(quest => {
        if (quest.isCompleted) {
            completed.push(quest);
        } else if (quest.isActive) {
            active.push(quest);
        } else if (quest.isUnlocked) {
            unlocked.push(quest);
        } else {
            locked.push(quest);
        }
    });

    return { active, completed, unlocked, locked };
}

// ============================================================
// 퀘스트 스토어
// ============================================================

export const useQuestStore = create<QuestState>((set, get) => ({
    // 초기 상태
    allQuests: [],
    activeQuests: [],
    completedQuests: [],
    unlockedQuests: [],
    lockedQuests: [],
    currentQuest: null,
    isLoading: false,

    // 퀘스트 로드 (API 호출 - 쿠키 인증)
    loadQuests: async () => {
        set({ isLoading: true });

        try {
            const response = await fetch('/api/quests', {
                credentials: 'include',
            });

            if (!response.ok) {
                throw new Error('퀘스트 로드 실패');
            }

            const result = await response.json();
            if (!result.success) {
                throw new Error(result.error || '퀘스트 로드 실패');
            }

            const quests = result.data.quests as Quest[];
            const { active, completed, unlocked, locked } = categorizeQuests(quests);

            // 첫 번째 활성 퀘스트를 현재 퀘스트로 설정
            const currentQuest = active[0] || unlocked[0] || null;

            set({
                allQuests: quests,
                activeQuests: active,
                completedQuests: completed,
                unlockedQuests: unlocked,
                lockedQuests: locked,
                currentQuest,
                isLoading: false,
            });

            console.log(`📋 퀘스트 로드 완료: ${quests.length}개`);
        } catch (error) {
            console.error('❌ 퀘스트 로드 실패:', error);
            set({ isLoading: false });
        }
    },

    // 퀘스트 선택
    selectQuest: (questId) => {
        const quest = get().allQuests.find(q => q.id === questId);
        if (quest) {
            set({ currentQuest: quest });
        }
    },

    // GPS 목표 체크
    checkGPSObjective: (lat, lng) => {
        const { activeQuests, completeObjective } = get();

        activeQuests.forEach(quest => {
            quest.objectives.forEach(objective => {
                if (
                    objective.type === 'gps_location' &&
                    !objective.completed &&
                    objective.targetLat !== undefined &&
                    objective.targetLng !== undefined
                ) {
                    const distance = calculateDistance(
                        lat, lng,
                        objective.targetLat,
                        objective.targetLng
                    );
                    const radius = objective.targetRadius || 100;

                    if (distance <= radius) {
                        console.log(`📍 GPS 목표 달성: ${objective.description} (${Math.round(distance)}m)`);
                        completeObjective(quest.id, objective.id);
                    }
                }
            });
        });
    },

    // 스토리 목표 체크
    checkStoryObjective: (nodeId) => {
        const { activeQuests, completeObjective } = get();

        activeQuests.forEach(quest => {
            quest.objectives.forEach(objective => {
                if (
                    objective.type === 'story_completion' &&
                    !objective.completed &&
                    objective.storyNodeEnd === nodeId
                ) {
                    console.log(`💬 스토리 목표 달성: ${objective.description}`);
                    completeObjective(quest.id, objective.id);
                }
            });
        });
    },

    // 목표 완료 (API 연동 - 쿠키 인증)
    completeObjective: async (questId, objectiveId) => {
        try {
            // 로컬 상태 먼저 업데이트
            set(state => {
                const updatedQuests = state.allQuests.map(quest => {
                    if (quest.id !== questId) return quest;

                    const updatedObjectives = quest.objectives.map(obj =>
                        obj.id === objectiveId ? { ...obj, completed: true } : obj
                    );

                    return {
                        ...quest,
                        objectives: updatedObjectives,
                    };
                });

                const { active, completed, unlocked, locked } = categorizeQuests(updatedQuests);
                const currentQuest = state.currentQuest?.id === questId
                    ? updatedQuests.find(q => q.id === questId) || state.currentQuest
                    : state.currentQuest;

                return {
                    allQuests: updatedQuests,
                    activeQuests: active,
                    completedQuests: completed,
                    unlockedQuests: unlocked,
                    lockedQuests: locked,
                    currentQuest,
                };
            });

            // API 호출로 DB 동기화 (쿠키 인증)
            await fetch('/api/quests/objective', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                credentials: 'include',
                body: JSON.stringify({ questId, objectiveId }),
            });

            // 모든 목표 완료 시 퀘스트 완료 처리
            const quest = get().allQuests.find(q => q.id === questId);
            if (quest && quest.objectives.every(obj => obj.completed)) {
                setTimeout(() => get().completeQuest(questId), 100);
            }
        } catch (error) {
            console.error('목표 완료 처리 실패:', error);
        }
    },

    // 퀘스트 완료 (API 연동 - 쿠키 인증)
    completeQuest: async (questId) => {
        try {
            // API 호출 (쿠키 인증)
            const response = await fetch('/api/quests/complete', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                credentials: 'include',
                body: JSON.stringify({ questId }),
            });

            const result = await response.json();
            if (!result.success) {
                throw new Error(result.error);
            }

            console.log(`🏆 퀘스트 완료: ${questId}`);
            console.log(`💰 보상:`, result.data.rewards);

            // 퀘스트 목록 다시 로드 (상태 동기화)
            await get().loadQuests();

        } catch (error) {
            console.error('퀘스트 완료 처리 실패:', error);
        }
    },

    // 퀘스트 해금
    unlockQuest: (questId) => {
        set(state => {
            const updatedQuests = state.allQuests.map(quest => {
                if (quest.id !== questId) return quest;
                return { ...quest, isUnlocked: true };
            });

            const { active, completed, unlocked, locked } = categorizeQuests(updatedQuests);

            return {
                allQuests: updatedQuests,
                activeQuests: active,
                completedQuests: completed,
                unlockedQuests: unlocked,
                lockedQuests: locked,
            };
        });
    },

    // 퀘스트 활성화 (API 연동 - 쿠키 인증)
    activateQuest: async (questId) => {
        try {
            // API 호출 (쿠키 인증)
            await fetch('/api/quests/activate', {
                method: 'POST',
                headers: {
                    'Content-Type': 'application/json',
                },
                credentials: 'include',
                body: JSON.stringify({ questId }),
            });

            // 로컬 상태 업데이트
            set(state => {
                const updatedQuests = state.allQuests.map(quest => {
                    if (quest.id !== questId) return quest;
                    return { ...quest, isActive: true };
                });

                const { active, completed, unlocked, locked } = categorizeQuests(updatedQuests);
                const currentQuest = updatedQuests.find(q => q.id === questId) || state.currentQuest;

                return {
                    allQuests: updatedQuests,
                    activeQuests: active,
                    completedQuests: completed,
                    unlockedQuests: unlocked,
                    lockedQuests: locked,
                    currentQuest,
                };
            });

            console.log(`▶️ 퀘스트 활성화: ${questId}`);
        } catch (error) {
            console.error('퀘스트 활성화 실패:', error);
        }
    },

    // 퀘스트 조회
    getQuestById: (questId) => {
        return get().allQuests.find(q => q.id === questId);
    },

    // 목표 진행률
    getObjectiveProgress: (questId) => {
        const quest = get().allQuests.find(q => q.id === questId);
        if (!quest) return { completed: 0, total: 0 };

        const completed = quest.objectives.filter(obj => obj.completed).length;
        const total = quest.objectives.length;

        return { completed, total };
    },
}));
