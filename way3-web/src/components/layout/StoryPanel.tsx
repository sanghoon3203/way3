'use client';
import { useState, useEffect } from 'react';
import styles from './StoryPanel.module.css';
import TabBar from '@/components/ui/TabBar';
import VNEngine from '@/components/story/VNEngine';
import ChapterSelect from '@/components/story/ChapterSelect';
import type { StoryChapter } from '@/lib/types/story';
import { useGPSStore } from '@/lib/store/gpsStore';
import InventoryGrid from '@/components/inventory/InventoryGrid';
import InventoryTooltip from '@/components/inventory/InventoryTooltip';
import { useMinigameStore } from '@/lib/store/minigameStore';
import { useUser } from '@/lib/hooks/useUser';
import { useQuestStore } from '@/lib/store/questStore';

// 프롤로그 데이터 import
import prologueData from '@/data/story/prologue.json';

type TabType = 'people' | 'story' | 'inventory' | 'mypage';

export default function StoryPanel() {
    const [activeTab, setActiveTab] = useState<TabType>('story');
    const [selectedChapterId, setSelectedChapterId] = useState<number | null>(null);
    const [chapter, setChapter] = useState<StoryChapter | null>(null);
    const { merchants } = useGPSStore();
    const { startGame } = useMinigameStore();
    const { fetchUser } = useUser();
    const { loadQuests } = useQuestStore();

    useEffect(() => {
        // 선택된 챕터에 따라 데이터 로드
        if (selectedChapterId === 0) {
            setChapter(prologueData as StoryChapter);
        } else {
            setChapter(null);
        }
    }, [selectedChapterId]);

    const handleSelectChapter = (chapterId: number) => {
        setSelectedChapterId(chapterId);
    };

    const handleBackToChapterSelect = () => {
        setSelectedChapterId(null);
        setChapter(null);
    };

    const handleStoryComplete = () => {
        // 스토리 완료 시 처리
        setSelectedChapterId(null);
        setChapter(null);
        fetchUser(); // 유저 정보 갱신
        console.log("Story complete, reloading quests...");
        loadQuests(); // 퀘스트 패널 갱신
    };

    const renderContent = () => {
        switch (activeTab) {
            case 'story':
                // 챕터가 선택되지 않았으면 ChapterSelect 표시
                if (selectedChapterId === null) {
                    return <ChapterSelect onSelectChapter={handleSelectChapter} />;
                }
                // 챕터가 선택되었으면 VNEngine 표시
                return chapter ? (
                    <div className={styles.storyContainer}>
                        <button
                            className={styles.backButton}
                            onClick={handleBackToChapterSelect}
                        >
                            ← 챕터 선택
                        </button>
                        <VNEngine
                            chapter={chapter}
                            onComplete={handleStoryComplete}
                        />
                    </div>
                ) : (
                    <div className={styles.loading}>
                        <span className={styles.loadingIcon}>⏳</span>
                        <span>로딩 중...</span>
                    </div>
                );

            case 'people':
                return (
                    <div className={styles.peopleList}>
                        {merchants.map((merchant) => (
                            <div key={merchant.id} className={styles.personItem}>
                                <img
                                    src={merchant.faceshot || '/images/default_avatar.png'}
                                    alt={merchant.name}
                                    className={styles.profileImage}
                                    onError={(e) => {
                                        (e.target as HTMLImageElement).src = '/images/default_avatar.png';
                                    }}
                                />
                                <div className={styles.personInfo}>
                                    <span className={styles.personName}>{merchant.name}</span>
                                    <span className={styles.personDistrict}>{merchant.district}</span>
                                </div>
                            </div>
                        ))}
                    </div>
                );

            case 'inventory':
                return <InventoryGrid />;

            case 'mypage':
                return (
                    <div className={styles.placeholder}>
                        <span className={styles.placeholderIcon}>👤</span>
                        <span className={styles.placeholderText}>마이페이지</span>
                        <button
                            onClick={() => startGame('carousel')}
                            style={{
                                marginTop: '20px',
                                padding: '10px 20px',
                                background: '#4d94ff',
                                border: 'none',
                                borderRadius: '8px',
                                color: 'white',
                                cursor: 'pointer'
                            }}
                        >
                            🎢 회전목마 수리 (Test)
                        </button>
                        <button
                            onClick={() => startGame('roasting')}
                            style={{
                                marginTop: '10px',
                                padding: '10px 20px',
                                background: '#e67e22',
                                border: 'none',
                                borderRadius: '8px',
                                color: 'white',
                                cursor: 'pointer'
                            }}
                        >
                            ☕ 커피 로스팅 (Test)
                        </button>
                        <button
                            onClick={() => startGame('rhythm')}
                            style={{
                                marginTop: '10px',
                                padding: '10px 20px',
                                background: '#c0392b',
                                border: 'none',
                                borderRadius: '8px',
                                color: 'white',
                                cursor: 'pointer'
                            }}
                        >
                            ⚔️ 대장간 리듬 (Test)
                        </button>
                        <button
                            onClick={() => startGame('constellation')}
                            style={{
                                marginTop: '10px',
                                padding: '10px 20px',
                                background: '#8e44ad',
                                border: 'none',
                                borderRadius: '8px',
                                color: 'white',
                                cursor: 'pointer'
                            }}
                        >
                            ✨ 별자리 순례 (Test)
                        </button>
                    </div>
                );

            default:
                return null;
        }
    };

    return (
        <div className={`${styles.container} panel halftone-bg`}>
            {/* Content Area */}
            <div className={styles.content}>
                <InventoryTooltip />
                {renderContent()}
            </div>

            {/* Tab Navigation */}
            <div className={styles.tabContainer}>
                <TabBar activeTab={activeTab} onTabChange={setActiveTab} />
            </div>
        </div>
    );
}
