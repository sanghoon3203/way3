'use client';
import { useState, useEffect } from 'react';
import styles from './StoryPanel.module.css';
import TabBar from '@/components/ui/TabBar';
import VNEngine from '@/components/story/VNEngine';
import ChapterSelect from '@/components/story/ChapterSelect';
import StorySelect from '@/components/story/StorySelect';
import type { StoryChapter } from '@/lib/types/story';
import { useGPSStore, type Merchant } from '@/lib/store/gpsStore';
import InventoryGrid from '@/components/inventory/InventoryGrid';
import InventoryTooltip from '@/components/inventory/InventoryTooltip';
import { useMinigameStore } from '@/lib/store/minigameStore';
import { useUser } from '@/lib/hooks/useUser';
import { useQuestStore } from '@/lib/store/questStore';
import CharacterChat from '@/components/chat/CharacterChat';
import { hasSubstory } from '@/data/substoryMap';

// 스토리 데이터 import
import prologueData from '@/data/story/prologue.json';
import gangnamData from '@/data/story/gangnam.json';
import seochoData from '@/data/story/seocho.json';
import songpaData from '@/data/story/songpa.json';
import gangdongData from '@/data/story/gangdong.json';

// 서브스토리 데이터 import
import seoyenaSubstory from '@/data/story/substories/seoyena.json';
import alicegangSubstory from '@/data/story/substories/alicegang.json';
import aniparkSubstory from '@/data/story/substories/anipark.json';
import jinbaekhoSubstory from '@/data/story/substories/jinbaekho.json';
import jubulsuSubstory from '@/data/story/substories/jubulsu.json';

// 서브스토리 파일 매핑
const substoryDataMap: Record<string, StoryChapter> = {
    'seoyena.json': seoyenaSubstory as StoryChapter,
    'alicegang.json': alicegangSubstory as StoryChapter,
    'anipark.json': aniparkSubstory as StoryChapter,
    'jinbaekho.json': jinbaekhoSubstory as StoryChapter,
    'jubulsu.json': jubulsuSubstory as StoryChapter,
};

type TabType = 'people' | 'story' | 'inventory' | 'mypage';

// 챕터 ID 매핑 (숫자 -> 문자열)
const chapterIdMap: Record<number, string> = {
    0: 'prologue',
    1: 'gangnam',
    2: 'seocho',
    3: 'songpa',
    4: 'gangdong',
};

// 스토리 파일 매핑
const storyDataMap: Record<string, StoryChapter> = {
    'prologue.json': prologueData as StoryChapter,
    'gangnam.json': gangnamData as StoryChapter,
    'seocho.json': seochoData as StoryChapter,
    'songpa.json': songpaData as StoryChapter,
    'gangdong.json': gangdongData as StoryChapter,
};

export default function StoryPanel() {
    const [activeTab, setActiveTab] = useState<TabType>('story');
    const [selectedChapterId, setSelectedChapterId] = useState<number | null>(null);
    const [showStorySelect, setShowStorySelect] = useState(false);
    const [chapter, setChapter] = useState<StoryChapter | null>(null);
    const [selectedMerchant, setSelectedMerchant] = useState<Merchant | null>(null);
    const { merchants } = useGPSStore();
    const { startGame } = useMinigameStore();
    const { fetchUser } = useUser();
    const { loadQuests } = useQuestStore();

    // 캐릭터 클릭 핸들러
    const handleMerchantClick = (merchant: Merchant) => {
        if (hasSubstory(merchant.id)) {
            setSelectedMerchant(merchant);
        }
    };

    // 채팅에서 돌아오기
    const handleBackFromChat = () => {
        setSelectedMerchant(null);
    };

    useEffect(() => {
        // 선택된 챕터에 따라 데이터 로드
        if (selectedChapterId === 0) {
            // 프롤로그는 바로 스토리 시작
            setChapter(prologueData as StoryChapter);
            setShowStorySelect(false);
        } else if (selectedChapterId !== null && selectedChapterId > 0) {
            // 다른 챕터는 StorySelect 표시
            setShowStorySelect(true);
            setChapter(null);
        } else {
            setChapter(null);
            setShowStorySelect(false);
        }
    }, [selectedChapterId]);

    const handleSelectChapter = (chapterId: number) => {
        setSelectedChapterId(chapterId);
    };

    const handleBackToChapterSelect = () => {
        setSelectedChapterId(null);
        setChapter(null);
        setShowStorySelect(false);
    };

    const handleSelectStory = (storyFile: string, startNodeId: string) => {
        const storyData = storyDataMap[storyFile];
        if (storyData) {
            setChapter(storyData);
            setShowStorySelect(false);
        }
    };

    const handleBackToStorySelect = () => {
        setChapter(null);
        setShowStorySelect(true);
    };

    const handleStoryComplete = () => {
        // 스토리 완료 시 처리
        setSelectedChapterId(null);
        setChapter(null);
        setShowStorySelect(false);
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

                // 스토리 선택 화면 (프롤로그 제외)
                if (showStorySelect && selectedChapterId !== null) {
                    const chapterKey = chapterIdMap[selectedChapterId] || 'gangnam';
                    return (
                        <StorySelect
                            chapterId={chapterKey}
                            onSelectStory={handleSelectStory}
                            onBack={handleBackToChapterSelect}
                        />
                    );
                }

                // 챕터가 선택되었으면 VNEngine 표시
                return chapter ? (
                    <div className={styles.storyContainer}>
                        <button
                            className={styles.backButton}
                            onClick={selectedChapterId === 0 ? handleBackToChapterSelect : handleBackToStorySelect}
                        >
                            ← {selectedChapterId === 0 ? '챕터 선택' : '스토리 선택'}
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
                // 채팅이 활성화되어 있으면 채팅 화면 표시
                if (selectedMerchant) {
                    return (
                        <CharacterChat
                            merchant={selectedMerchant}
                            substoryData={substoryDataMap}
                            onBack={handleBackFromChat}
                        />
                    );
                }

                return (
                    <div className={styles.peopleList}>
                        {merchants.map((merchant) => (
                            <div
                                key={merchant.id}
                                className={`${styles.personItem} ${hasSubstory(merchant.id) ? styles.hasStory : ''}`}
                                onClick={() => handleMerchantClick(merchant)}
                            >
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
                                    {hasSubstory(merchant.id) && (
                                        <span className={styles.storyBadge}>📖 스토리</span>
                                    )}
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
