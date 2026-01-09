'use client';
import { useRef, useEffect, useState } from 'react';
import styles from './CharacterChat.module.css';
import type { Merchant } from '@/lib/store/gpsStore';
import type { StoryChapter } from '@/lib/types/story';
import VNEngine from '@/components/story/VNEngine';
import chatMessagesData from '@/data/chatMessages.json';

interface Episode {
    id: string;
    title: string;
    file: string;
    unlocked: boolean;
}

interface CharacterChatData {
    greeting: string;
    episodes: Episode[];
}

interface CharacterChatProps {
    merchant: Merchant;
    substoryData: Record<string, StoryChapter>;
    onBack: () => void;
}

export default function CharacterChat({ merchant, substoryData, onBack }: CharacterChatProps) {
    const messagesEndRef = useRef<HTMLDivElement>(null);
    const [showConfirmPopup, setShowConfirmPopup] = useState(false);
    const [selectedEpisode, setSelectedEpisode] = useState<Episode | null>(null);
    const [isPlayingStory, setIsPlayingStory] = useState(false);
    const [currentChapter, setCurrentChapter] = useState<StoryChapter | null>(null);

    // 캐릭터 채팅 데이터 가져오기
    const chatData = (chatMessagesData as Record<string, CharacterChatData>)[merchant.id];

    // 메시지 추가시 스크롤
    useEffect(() => {
        messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
    }, []);

    // 에피소드 클릭 핸들러
    const handleEpisodeClick = (episode: Episode) => {
        setSelectedEpisode(episode);
        setShowConfirmPopup(true);
    };

    // 스토리 시작 확인
    const handleConfirmStart = () => {
        if (selectedEpisode && substoryData[selectedEpisode.file]) {
            setCurrentChapter(substoryData[selectedEpisode.file]);
            setIsPlayingStory(true);
            setShowConfirmPopup(false);
        }
    };

    // 스토리 완료 시 채팅으로 복귀
    const handleStoryComplete = () => {
        setIsPlayingStory(false);
        setCurrentChapter(null);
        setSelectedEpisode(null);
    };

    // VN 엔진 재생 중일 때
    if (isPlayingStory && currentChapter) {
        return (
            <div className={styles.vnContainer}>
                <VNEngine
                    chapter={currentChapter}
                    onComplete={handleStoryComplete}
                />
            </div>
        );
    }

    return (
        <div className={styles.container}>
            {/* 헤더 */}
            <div className={styles.header}>
                <button className={styles.backButton} onClick={onBack}>
                    ←
                </button>
                <h1 className={styles.title}>{merchant.name}와의 대화</h1>
                <div className={styles.headerSpacer} />
            </div>

            {/* 채팅 영역 */}
            <div className={styles.chatArea}>
                {/* 캐릭터 인사 메시지 */}
                {chatData && (
                    <div className={styles.messageRow}>
                        <img
                            src={merchant.faceshot || '/images/default_avatar.png'}
                            alt={merchant.name}
                            className={styles.avatar}
                            onError={(e) => {
                                (e.target as HTMLImageElement).src = '/images/default_avatar.png';
                            }}
                        />
                        <div className={styles.messageBubble}>
                            {chatData.greeting}
                        </div>
                    </div>
                )}

                {/* 에피소드 버블들 */}
                {chatData?.episodes.map((episode) => (
                    <div key={episode.id} className={styles.messageRow}>
                        <img
                            src={merchant.faceshot || '/images/default_avatar.png'}
                            alt={merchant.name}
                            className={styles.avatar}
                            onError={(e) => {
                                (e.target as HTMLImageElement).src = '/images/default_avatar.png';
                            }}
                        />
                        <div
                            className={`${styles.messageBubble} ${styles.storyBubble}`}
                            onClick={() => handleEpisodeClick(episode)}
                        >
                            📖 {episode.title}
                        </div>
                    </div>
                ))}

                <div ref={messagesEndRef} />
            </div>

            {/* 확인 팝업 */}
            {showConfirmPopup && selectedEpisode && (
                <div className={styles.popupOverlay}>
                    <div className={styles.popup}>
                        <p className={styles.popupText}>
                            "{selectedEpisode.title}"을(를) 시작하시겠습니까?
                        </p>
                        <div className={styles.popupButtons}>
                            <button
                                className={styles.popupButtonNo}
                                onClick={() => setShowConfirmPopup(false)}
                            >
                                아니오
                            </button>
                            <button
                                className={styles.popupButtonYes}
                                onClick={handleConfirmStart}
                            >
                                예
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
}
