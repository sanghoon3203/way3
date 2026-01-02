/**
 * WAY3 Quest System Types
 * 2-Type System: Delivery (GPS) + Dialogue (Story)
 */

// ============================================================
// 퀘스트 타입 (2가지)
// ============================================================

export type QuestType = 'delivery' | 'dialogue';

// ============================================================
// 퀘스트 목표 타입
// ============================================================

export type ObjectiveType = 'gps_location' | 'story_completion';

export interface QuestObjective {
    id: string;
    type: ObjectiveType;
    description: string;
    completed: boolean;
    sortOrder?: number;

    // GPS 위치 관련 (delivery 타입)
    targetLat?: number;
    targetLng?: number;
    targetRadius?: number; // 미터 단위
    locationName?: string;

    // 스토리 관련 (dialogue 타입)
    storyNodeStart?: string;
    storyNodeEnd?: string;
}

// ============================================================
// 퀘스트 보상
// ============================================================

export interface QuestRewardItem {
    itemId: string;
    itemName?: string;
    quantity: number;
    description?: string;
}

export interface QuestReward {
    money?: number;
    exp?: number;
    items?: QuestRewardItem[];
}

// ============================================================
// 퀘스트 요구사항
// ============================================================

export interface QuestRequirement {
    type: 'level' | 'quest_completed' | 'item' | 'episode';
    value: string | number;
}

// ============================================================
// 퀘스트 정의
// ============================================================

export interface Quest {
    id: string;
    title: string;
    description: string;
    questType: QuestType;
    chapterId: string;
    districtId?: string;
    merchantId?: string;

    // 목표 (여러 개 가능)
    objectives: QuestObjective[];

    // 보상
    rewards: QuestReward;

    // 요구사항
    requirements?: QuestRequirement[];

    // 체인 시스템
    unlocksQuestIds?: string[];
    unlocksDistricts?: string[];  // 이 퀘스트 완료 시 해금되는 구역들
    requiresQuestIds?: string[];

    // 상태
    isActive: boolean;
    isCompleted: boolean;
    isUnlocked: boolean;

    // 메타데이터
    isMainQuest?: boolean;
    sortOrder?: number;
    storySummary?: string;
}

// ============================================================
// 퀘스트 상태 (플레이어 진행도)
// ============================================================

export interface QuestProgress {
    questId: string;
    completedObjectiveIds: string[];
    isCompleted: boolean;
    completedAt?: string;
}

// ============================================================
// API 응답 타입 (서버 연동용)
// ============================================================

export interface QuestListResponse {
    success: boolean;
    data: {
        quests: Quest[];
        totalCount: number;
    };
    error?: string;
}

export interface QuestActionResponse {
    success: boolean;
    message?: string;
    data?: {
        questId: string;
        updatedQuest: Quest;
        unlockedQuests?: Quest[];
    };
    error?: string;
}
