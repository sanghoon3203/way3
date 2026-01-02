'use client';
import { useEffect } from 'react';
import { useQuestStore } from '@/lib/store/questStore';
import { useStoryStore } from '@/lib/store/storyStore';
import type { Quest, QuestObjective } from '@/lib/types/quest';
import styles from './QuestPanel.module.css';

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

export default function QuestPanel() {
    const {
        currentQuest,
        activeQuests,
        completedQuests,
        loadQuests,
        isLoading,
        getObjectiveProgress,
    } = useQuestStore();

    const { currentNode } = useStoryStore();

    // 컴포넌트 마운트 시 퀘스트 로드
    useEffect(() => {
        loadQuests();
    }, [loadQuests]);

    // 현재 퀘스트가 없으면 빈 상태 표시
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
            </div>
        );
    }

    const { completed: completedCount, total: totalCount } = getObjectiveProgress(currentQuest.id);
    const progress = totalCount > 0 ? Math.round((completedCount / totalCount) * 100) : 0;

    return (
        <div className={`${styles.container} panel halftone-bg`}>
            {/* Header */}
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
                                    {currentQuest.chapterId === 'prologue' ? '프롤로그' :
                                        currentQuest.chapterId === 'gangnam' ? '강남' :
                                            currentQuest.chapterId}
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

            {/* Quest Stats Footer */}
            <div className={styles.questStats}>
                <div className={styles.statItem}>
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
