'use client';
import { useState } from 'react';
import styles from './ChapterSelect.module.css';
import ConfirmDialog from '@/components/ui/ConfirmDialog';

interface Chapter {
    id: number;
    title: string;
    subtitle: string;
    icon: string;
    isUnlocked: boolean;
    isInProgress: boolean;
}

const chapters: Chapter[] = [
    {
        id: 0,
        title: '프롤로그',
        subtitle: 'PROLOGUE',
        icon: '📖',
        isUnlocked: true,
        isInProgress: true,
    },
    {
        id: 1,
        title: '강남권',
        subtitle: 'GANGNAM',
        icon: '🏙️',
        isUnlocked: false,
        isInProgress: false,
    },
    {
        id: 2,
        title: '서북권',
        subtitle: 'NORTHWEST',
        icon: '🌲',
        isUnlocked: false,
        isInProgress: false,
    },
    {
        id: 3,
        title: '동북권',
        subtitle: 'NORTHEAST',
        icon: '⛰️',
        isUnlocked: false,
        isInProgress: false,
    },
    {
        id: 4,
        title: '서남권',
        subtitle: 'SOUTHWEST',
        icon: '🌊',
        isUnlocked: false,
        isInProgress: false,
    },
];

interface ChapterSelectProps {
    onSelectChapter: (chapterId: number) => void;
}

export default function ChapterSelect({ onSelectChapter }: ChapterSelectProps) {
    const [selectedChapter, setSelectedChapter] = useState<Chapter | null>(null);
    const [showConfirmDialog, setShowConfirmDialog] = useState(false);

    const handleChapterClick = (chapter: Chapter) => {
        if (chapter.isUnlocked) {
            setSelectedChapter(chapter);
            setShowConfirmDialog(true);
        }
    };

    const handleConfirm = () => {
        if (selectedChapter) {
            onSelectChapter(selectedChapter.id);
        }
        setShowConfirmDialog(false);
        setSelectedChapter(null);
    };

    const handleCancel = () => {
        setShowConfirmDialog(false);
        setSelectedChapter(null);
    };

    return (
        <div className={styles.container}>
            <div className={styles.header}>
                <h2 className={styles.title}>📚 스토리 선택</h2>
                <p className={styles.subtitle}>CHAPTER SELECT</p>
            </div>

            <div className={styles.chapterGrid}>
                {chapters.map((chapter) => (
                    <button
                        key={chapter.id}
                        className={`${styles.chapterCard} ${chapter.isUnlocked ? styles.unlocked : styles.locked
                            } ${chapter.isInProgress ? styles.inProgress : ''}`}
                        onClick={() => handleChapterClick(chapter)}
                        disabled={!chapter.isUnlocked}
                    >
                        <div className={styles.cardIcon}>{chapter.icon}</div>
                        <div className={styles.cardContent}>
                            <span className={styles.chapterNumber}>
                                {chapter.id === 0 ? 'PROLOGUE' : `CHAPTER ${chapter.id}`}
                            </span>
                            <span className={styles.chapterTitle}>{chapter.title}</span>
                            <span className={styles.chapterSubtitle}>{chapter.subtitle}</span>
                        </div>

                        {/* 상태 배지 */}
                        {chapter.isInProgress && (
                            <div className={styles.statusBadge}>
                                <span className={styles.statusDot}></span>
                                진행 중
                            </div>
                        )}
                        {!chapter.isUnlocked && (
                            <div className={styles.lockOverlay}>
                                <span className={styles.lockIcon}>🔒</span>
                            </div>
                        )}
                    </button>
                ))}
            </div>

            <div className={styles.hint}>
                <span>💡 프롤로그를 완료하면 다음 챕터가 해금됩니다</span>
            </div>

            {/* 챕터 시작 확인 다이얼로그 */}
            <ConfirmDialog
                isOpen={showConfirmDialog}
                title="챕터 시작"
                message={`"${selectedChapter?.title || ''}"을(를) 시작하시겠습니까?`}
                confirmText="시작"
                cancelText="취소"
                onConfirm={handleConfirm}
                onCancel={handleCancel}
            />
        </div>
    );
}

