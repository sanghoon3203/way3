'use client';
import { useState, useEffect } from 'react';
import styles from './StorySelect.module.css';
import ConfirmDialog from '@/components/ui/ConfirmDialog';
import storyIndex from '@/data/story/story-index.json';

interface Story {
    id: string;
    title: string;
    description: string;
    merchantId?: string;
    storyFile: string;
    startNodeId: string;
    requiresQuestId?: string | null;
    isMainStory?: boolean;
}

interface District {
    id: string;
    name: string;
    stories: Story[];
}

interface ChapterStories {
    id: string;
    title: string;
    subtitle: string;
    districts: District[];
}

interface StorySelectProps {
    chapterId: string;  // 'gangnam', 'seocho', etc.
    onSelectStory: (storyFile: string, startNodeId: string) => void;
    onBack: () => void;
}

export default function StorySelect({ chapterId, onSelectStory, onBack }: StorySelectProps) {
    const [selectedStory, setSelectedStory] = useState<Story | null>(null);
    const [showConfirmDialog, setShowConfirmDialog] = useState(false);
    const [chapterData, setChapterData] = useState<ChapterStories | null>(null);

    // 챕터 데이터 로드
    useEffect(() => {
        const chapters = storyIndex.chapters as Record<string, ChapterStories>;
        const data = chapters[chapterId];
        if (data) {
            setChapterData(data);
        }
    }, [chapterId]);

    const handleStoryClick = (story: Story) => {
        setSelectedStory(story);
        setShowConfirmDialog(true);
    };

    const handleConfirm = () => {
        if (selectedStory) {
            onSelectStory(selectedStory.storyFile, selectedStory.startNodeId);
        }
        setShowConfirmDialog(false);
        setSelectedStory(null);
    };

    const handleCancel = () => {
        setShowConfirmDialog(false);
        setSelectedStory(null);
    };

    if (!chapterData) {
        return (
            <div className={styles.container}>
                <div className={styles.loading}>
                    <span>로딩 중...</span>
                </div>
            </div>
        );
    }

    return (
        <div className={styles.container}>
            {/* Header */}
            <div className={styles.header}>
                <button className={styles.backBtn} onClick={onBack}>
                    ← 챕터 선택
                </button>
                <div className={styles.headerTitle}>
                    <h2 className={styles.title}>📚 {chapterData.title} 스토리</h2>
                    <p className={styles.subtitle}>{chapterData.subtitle} STORIES</p>
                </div>
            </div>

            {/* District List */}
            <div className={styles.districtList}>
                {chapterData.districts.map((district) => (
                    <div key={district.id} className={styles.districtSection}>
                        <div className={styles.districtHeader}>
                            <span className={styles.districtIcon}>📍</span>
                            <span className={styles.districtName}>{district.name}</span>
                        </div>

                        <div className={styles.storyList}>
                            {district.stories.map((story) => (
                                <button
                                    key={story.id}
                                    className={`${styles.storyCard} ${story.isMainStory ? styles.mainStory : ''}`}
                                    onClick={() => handleStoryClick(story)}
                                >
                                    <div className={styles.storyCardContent}>
                                        <div className={styles.storyHeader}>
                                            <span className={styles.storyIcon}>📖</span>
                                            <span className={styles.storyTitle}>{story.title}</span>
                                            {story.isMainStory && (
                                                <span className={styles.mainBadge}>메인</span>
                                            )}
                                        </div>
                                        <p className={styles.storyDescription}>{story.description}</p>
                                    </div>
                                    <span className={styles.playIcon}>▶</span>
                                </button>
                            ))}
                        </div>
                    </div>
                ))}
            </div>

            {/* Hint */}
            <div className={styles.hint}>
                <span>💡 스토리를 선택하여 진행하세요</span>
            </div>

            {/* Confirm Dialog */}
            <ConfirmDialog
                isOpen={showConfirmDialog}
                title="스토리 시작"
                message={`"${selectedStory?.title || ''}" 스토리를 시작하시겠습니까?`}
                confirmText="시작"
                cancelText="취소"
                onConfirm={handleConfirm}
                onCancel={handleCancel}
            />
        </div>
    );
}
