'use client';
import { useEffect, useState } from 'react';
import { useQuestStore } from '@/lib/store/questStore';
import { useStoryStore } from '@/lib/store/storyStore';
import type { Quest, QuestObjective } from '@/lib/types/quest';
import styles from './QuestPanel.module.css';

// 뷰 모드 타입
type ViewMode = 'detail' | 'list';

// 퀘스트 타입 아이콘
function getQuestTypeIcon(questType: string): string {
    switch (questType) {
        case 'delivery': return '📍';
        case 'dialogue': return '💬';
        default: return '📋';
    }
}

// 목표 타입 아이콘
function getObjectiveTypeIcon(objectiveType: string): string {
    switch (objectiveType) {
        case 'gps_location': return '📍';
        case 'story_completion': return '💬';
        default: return '•';
    }
}

// 챕터 이름 변환
function getChapterName(chapterId: string): string {
    switch (chapterId) {
        case 'prologue': return '프롤로그';
        case 'gangnam': return '강남';
        case 'seocho': return '서초';
        case 'songpa': return '송파';
        case 'gangdong': return '강동';
        default: return chapterId;
    }
}

// 퀘스트 카드 컴포넌트 (목록용)
function QuestCard({ quest, onClick }: { quest: Quest; onClick: () => void }) {
    const { getObjectiveProgress } = useQuestStore();
    const { completed, total } = getObjectiveProgress(quest.id);
    const progress = total > 0 ? Math.round((completed / total) * 100) : 0;

    return (
        <div className={styles.questCard} onClick={onClick}>
            <div className={styles.questCardHeader}>
                <span className={styles.questCardIcon}>
                    {getQuestTypeIcon(quest.questType)}
                </span>
                <h4 className={styles.questCardTitle}>{quest.title}</h4>
                {quest.isMainQuest && (
                    <span className={styles.mainQuestBadge}>메인</span>
                )}
            </div>
            <div className={styles.questCardProgress}>
                <div className={styles.progressBar}>
                    <div
                        className={styles.progressFill}
                        style={{ width: `${progress}%` }}
                    />
                </div>
                <span className={styles.questCardProgressText}>{progress}%</span>
            </div>
            <div className={styles.questCardChapter}>
                <span className={styles.chapterIcon}>📖</span>
                <span className={styles.chapterName}>{getChapterName(quest.chapterId)}</span>
            </div>
        </div>
    );
}

export default function QuestPanel() {
    const {
        currentQuest,
        activeQuests,
        completedQuests,
        loadQuests,
        isLoading,
        getObjectiveProgress,
        selectQuest,
    } = useQuestStore();

    const { currentNode } = useStoryStore();

    // 뷰 모드 상태 (detail: 상세 뷰, list: 목록 뷰)
    const [viewMode, setViewMode] = useState<ViewMode>('detail');

    // 컴포넌트 마운트 시 퀘스트 로드
    useEffect(() => {
        loadQuests();
    }, [loadQuests]);

    // 퀘스트 선택 시 상세 뷰로 전환
    const handleSelectQuest = (questId: string) => {
        selectQuest(questId);
        setViewMode('detail');
    };

    // 목록 뷰로 전환
    const handleShowList = () => {
        setViewMode('list');
    };

    // 로딩 상태
    if (isLoading) {
        return (
            <div className={`${styles.container} panel halftone-bg`}>
                <div className={styles.header}>
                    <div className={styles.headerLeft}>
                        <span className={styles.icon}>📋</span>
                        <h3 className={styles.title}>현재 퀘스트</h3>
                    </div>
                </div>
                <div className={styles.emptyState}>
                    <span className={styles.emptyIcon}>⏳</span>
                    <p className={styles.emptyText}>퀘스트 로딩 중...</p>
                </div>
            </div>
        );
    }

    // 목록 뷰 렌더링
    if (viewMode === 'list') {
        return (
            <div className={`${styles.container} panel halftone-bg`}>
                <div className={styles.header}>
                    <div className={styles.headerLeft}>
                        <span className={styles.icon}>📋</span>
                        <h3 className={styles.title}>진행중인 퀘스트</h3>
                        <button
                            onClick={() => loadQuests()}
                            className={styles.refreshBtn}
                            title="새로고침"
                            style={{ marginLeft: '8px', background: 'none', border: 'none', cursor: 'pointer', fontSize: '1.2rem' }}
                        >
                            ↻
                        </button>
                    </div>
                    <div className={styles.progressBadge}>
                        {activeQuests.length}개 진행 중
                    </div>
                </div>

                <div className={styles.questListContent}>
                    {activeQuests.length === 0 ? (
                        <div className={styles.emptyState}>
                            <span className={styles.emptyIcon}>✨</span>
                            <p className={styles.emptyText}>진행 중인 퀘스트가 없습니다</p>
                        </div>
                    ) : (
                        <div className={styles.questCardList}>
                            {activeQuests.map((quest) => (
                                <QuestCard
                                    key={quest.id}
                                    quest={quest}
                                    onClick={() => handleSelectQuest(quest.id)}
                                />
                            ))}
                        </div>
                    )}
                </div>

                {/* Footer */}
                <div className={styles.questStats}>
                    <div
                        className={`${styles.statItem} ${styles.statItemActive}`}
                    >
                        <span className={styles.statLabel}>진행 중</span>
                        <span className={styles.statValue}>{activeQuests.length}</span>
                    </div>
                    <div className={styles.statItem}>
                        <span className={styles.statLabel}>완료됨</span>
                        <span className={styles.statValue}>{completedQuests.length}</span>
                    </div>
                </div>
            </div>
        );
    }

    // 상세 뷰 - 퀘스트가 없는 경우
    if (!currentQuest) {
        return (
            <div className={`${styles.container} panel halftone-bg`}>
                <div className={styles.header}>
                    <div className={styles.headerLeft}>
                        <span className={styles.icon}>📋</span>
                        <h3 className={styles.title}>현재 퀘스트</h3>
                    </div>
                </div>
                <div className={styles.emptyState}>
                    <span className={styles.emptyIcon}>✨</span>
                    <p className={styles.emptyText}>진행 중인 퀘스트가 없습니다</p>
                </div>
                {/* Footer with clickable stats */}
                <div className={styles.questStats}>
                    <div
                        className={`${styles.statItem} ${styles.statItemClickable}`}
                        onClick={handleShowList}
                    >
                        <span className={styles.statLabel}>진행 중</span>
                        <span className={styles.statValue}>{activeQuests.length}</span>
                    </div>
                    <div className={styles.statItem}>
                        <span className={styles.statLabel}>완료됨</span>
                        <span className={styles.statValue}>{completedQuests.length}</span>
                    </div>
                </div>
            </div>
        );
    }

    const { completed: completedCount, total: totalCount } = getObjectiveProgress(currentQuest.id);
    const progress = totalCount > 0 ? Math.round((completedCount / totalCount) * 100) : 0;

    // 상세 뷰 렌더링
    return (
        <div className={`${styles.container} panel halftone-bg`}>
            {/* Header */}
            <div className={styles.header}>
                <div className={styles.headerLeft}>
                    <span className={styles.icon}>📋</span>
                    <h3 className={styles.title}>현재 퀘스트</h3>
                    <button
                        onClick={() => loadQuests()}
                        className={styles.refreshBtn}
                        title="새로고침"
                        style={{ marginLeft: '8px', background: 'none', border: 'none', cursor: 'pointer', fontSize: '1.2rem' }}
                    >
                        ↻
                    </button>
                </div>
                <div className={styles.progressBadge}>
                    {completedCount}/{totalCount} 완료
                </div>
            </div>

            {/* Content */}
            <div className={styles.content}>
                {/* Quest Info */}
                <div className={styles.questInfo}>
                    <div className={styles.questTypeRow}>
                        <span className={styles.questTypeIcon}>
                            {getQuestTypeIcon(currentQuest.questType)}
                        </span>
                        <span className={styles.questTypeBadge}>
                            {currentQuest.questType === 'delivery' ? '배달' : '대화'}
                        </span>
                        {currentQuest.isMainQuest && (
                            <span className={styles.mainQuestBadge}>메인</span>
                        )}
                    </div>
                    <h4 className={styles.questName}>{currentQuest.title}</h4>
                    <p className={styles.questDescription}>{currentQuest.description}</p>
                </div>

                {/* Progress Bar */}
                <div className={styles.progressSection}>
                    <div className={styles.progressHeader}>
                        <span className={styles.progressLabel}>진행률</span>
                        <span className={styles.progressValue}>{progress}%</span>
                    </div>
                    <div className={styles.progressBar}>
                        <div
                            className={styles.progressFill}
                            style={{ width: `${progress}%` }}
                        />
                    </div>
                </div>

                {/* Two Column Layout */}
                <div className={styles.twoColumn}>
                    {/* Objectives */}
                    <div className={styles.objectivesSection}>
                        <h5 className={styles.sectionTitle}>목표</h5>
                        <div className={styles.objectivesList}>
                            {currentQuest.objectives.map((objective) => (
                                <div
                                    key={objective.id}
                                    className={`${styles.objectiveItem} ${objective.completed ? styles.completed : ''}`}
                                >
                                    <div className={styles.checkbox}>
                                        {objective.completed ? (
                                            <span className={styles.checkmark}>✓</span>
                                        ) : (
                                            <span className={styles.objectiveIcon}>
                                                {getObjectiveTypeIcon(objective.type)}
                                            </span>
                                        )}
                                    </div>
                                    <div className={styles.objectiveContent}>
                                        <span className={styles.objectiveText}>{objective.description}</span>
                                        {objective.locationName && !objective.completed && (
                                            <span className={styles.objectiveHint}>
                                                📍 {objective.locationName}
                                            </span>
                                        )}
                                    </div>
                                </div>
                            ))}
                        </div>
                    </div>

                    {/* Info Cards */}
                    <div className={styles.infoSection}>
                        {/* Chapter Card */}
                        <div className={styles.infoCard}>
                            <h5 className={styles.sectionTitle}>챕터</h5>
                            <div className={styles.chapterInfo}>
                                <span className={styles.chapterIcon}>📖</span>
                                <span className={styles.chapterName}>
                                    {getChapterName(currentQuest.chapterId)}
                                </span>
                            </div>
                        </div>

                        {/* Reward Card */}
                        {currentQuest.rewards && (
                            <div className={styles.infoCard}>
                                <h5 className={styles.sectionTitle}>보상</h5>
                                <div className={styles.rewardInfo}>
                                    {currentQuest.rewards.money && (
                                        <div className={styles.rewardItem}>
                                            <span className={styles.rewardIcon}>💰</span>
                                            <span className={styles.rewardValue}>
                                                {currentQuest.rewards.money.toLocaleString()} 골드
                                            </span>
                                        </div>
                                    )}
                                    {currentQuest.rewards.exp && (
                                        <div className={styles.rewardItem}>
                                            <span className={styles.rewardIcon}>⭐</span>
                                            <span className={styles.rewardValue}>
                                                {currentQuest.rewards.exp} EXP
                                            </span>
                                        </div>
                                    )}
                                    {currentQuest.rewards.items && currentQuest.rewards.items.length > 0 && (
                                        <div className={styles.rewardItem}>
                                            <span className={styles.rewardIcon}>🎁</span>
                                            <span className={styles.rewardValue}>
                                                아이템 {currentQuest.rewards.items.length}개
                                            </span>
                                        </div>
                                    )}
                                </div>
                            </div>
                        )}
                    </div>
                </div>

            </div>

            {/* Quest Stats Footer - 클릭 가능 */}
            <div className={styles.questStats}>
                <div
                    className={`${styles.statItem} ${styles.statItemClickable}`}
                    onClick={handleShowList}
                >
                    <span className={styles.statLabel}>진행 중</span>
                    <span className={styles.statValue}>{activeQuests.length}</span>
                </div>
                <div className={styles.statItem}>
                    <span className={styles.statLabel}>완료됨</span>
                    <span className={styles.statValue}>{completedQuests.length}</span>
                </div>
            </div>
        </div >
    );
}
