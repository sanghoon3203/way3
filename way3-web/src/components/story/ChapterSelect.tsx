'use client';
import { useState, useEffect } from 'react';
import styles from './ChapterSelect.module.css';
import ConfirmDialog from '@/components/ui/ConfirmDialog';

interface Chapter {
    id: string;  // 'prologue', 'gangnam', etc.
    numericId: number;
    title: string;
    subtitle: string;
    icon: string;
    isUnlocked: boolean;
    isInProgress: boolean;
}

// 기본 챕터 정의 (해금 상태는 동적으로 설정됨)
const defaultChapters: Omit<Chapter, 'isUnlocked' | 'isInProgress'>[] = [
    {
        id: 'prologue',
        numericId: 0,
        title: '프롤로그',
        subtitle: 'PROLOGUE',
        icon: '📖',
    },
    {
        id: 'gangnam',
        numericId: 1,
        title: '강남권',
        subtitle: 'GANGNAM',
        icon: '🏙️',
    },
    {
        id: 'seocho',
        numericId: 2,
        title: '서초권',
        subtitle: 'SEOCHO',
        icon: '🌲',
    },
    {
        id: 'songpa',
        numericId: 3,
        title: '송파권',
        subtitle: 'SONGPA',
        icon: '⛰️',
    },
    {
        id: 'gangdong',
        numericId: 4,
        title: '강동권',
        subtitle: 'GANGDONG',
        icon: '🌊',
    },
];

interface ChapterSelectProps {
    onSelectChapter: (chapterId: number) => void;
}

export default function ChapterSelect({ onSelectChapter }: ChapterSelectProps) {
    const [selectedChapter, setSelectedChapter] = useState<Chapter | null>(null);
    const [showConfirmDialog, setShowConfirmDialog] = useState(false);
    const [chapters, setChapters] = useState<Chapter[]>([]);
    const [isLoading, setIsLoading] = useState(true);
    const [currentChapter, setCurrentChapter] = useState<string>('prologue');

    // 유저 정보 가져오기
    useEffect(() => {
        const fetchUserData = async () => {
            try {
                const response = await fetch('/api/user/me', {
                    credentials: 'include',
                });

                if (!response.ok) {
                    // 로그인 안 된 상태 - 프롤로그만 해금
                    setChapters(defaultChapters.map(ch => ({
                        ...ch,
                        isUnlocked: ch.id === 'prologue',
                        isInProgress: ch.id === 'prologue',
                    })));
                    setIsLoading(false);
                    return;
                }

                const data = await response.json();
                const user = data.user;

                // unlockedDistricts 파싱 (JSON 문자열)
                const unlockedDistricts: string[] = JSON.parse(user.unlockedDistricts || '[]');
                const userCurrentChapter = user.currentChapter || 'prologue';
                setCurrentChapter(userCurrentChapter);

                // 챕터 상태 설정
                const updatedChapters: Chapter[] = defaultChapters.map(ch => ({
                    ...ch,
                    // 프롤로그는 항상 해금, 나머지는 unlockedDistricts 체크
                    isUnlocked: ch.id === 'prologue' || unlockedDistricts.includes(ch.id),
                    // 현재 진행 중인 챕터 표시
                    isInProgress: ch.id === userCurrentChapter,
                }));

                setChapters(updatedChapters);
            } catch (error) {
                console.error('Failed to fetch user data:', error);
                // 에러 시 프롤로그만 해금
                setChapters(defaultChapters.map(ch => ({
                    ...ch,
                    isUnlocked: ch.id === 'prologue',
                    isInProgress: ch.id === 'prologue',
                })));
            } finally {
                setIsLoading(false);
            }
        };

        fetchUserData();
    }, []);

    const handleChapterClick = (chapter: Chapter) => {
        if (chapter.isUnlocked) {
            setSelectedChapter(chapter);
            setShowConfirmDialog(true);
        }
    };

    const handleConfirm = () => {
        if (selectedChapter) {
            onSelectChapter(selectedChapter.numericId);
        }
        setShowConfirmDialog(false);
        setSelectedChapter(null);
    };

    const handleCancel = () => {
        setShowConfirmDialog(false);
        setSelectedChapter(null);
    };

    if (isLoading) {
        return (
            <div className={styles.container}>
                <div className={styles.header}>
                    <h2 className={styles.title}>📚 스토리 선택</h2>
                    <p className={styles.subtitle}>CHAPTER SELECT</p>
                </div>
                <div className={styles.loading}>
                    <span>로딩 중...</span>
                </div>
            </div>
        );
    }

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
                                {chapter.numericId === 0 ? 'PROLOGUE' : `CHAPTER ${chapter.numericId}`}
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
                <span>💡 퀘스트를 완료하면 다음 챕터가 해금됩니다</span>
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
