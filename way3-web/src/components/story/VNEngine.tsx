'use client';
import { useEffect, useRef, useCallback } from 'react';
import { useStoryStore } from '@/lib/store/storyStore';
import { useTypewriter } from '@/lib/hooks/useTypewriter';
import { useVNSound } from '@/lib/hooks/useVNSound';
import type { StoryChapter } from '@/lib/types/story';
import styles from './VNEngine.module.css';

interface VNEngineProps {
    chapter: StoryChapter;
    onComplete?: () => void;
}

// 캐릭터 이름 매핑
const CHARACTER_NAMES: Record<string, string> = {
    'player': '나',
    'typer_narrator': '내레이터',
    '기주리': '기주리',
    'Kijuri': '기주리',
    'NPC': '시스템',
    'AniPark': '애니',
    'Alicegang': '앨리스강',
    'Julbulsu': '주불수',
    'Jinbaekho': '진백호',
    'CoffeeShopManager': '커피집사장',
    'CarDealer': '자동차 딜러',
    '???': '???',
    '': '',
};

// 캐릭터 성별 매핑 (blip 사운드용)
const CHARACTER_GENDER: Record<string, 'male' | 'female' | 'neutral'> = {
    'player': 'male',
    'typer_narrator': 'neutral',
    '기주리': 'female',
    'Kijuri': 'female',
    'NPC': 'male',
    'AniPark': 'female',
    'Alicegang': 'female',
    'Julbulsu': 'male',
    'Jinbaekho': 'male',
    'CoffeeShopManager': 'male',
    'CarDealer': 'male',
    '???': 'neutral',
};

function getCharacterName(characterId: string | null): string {
    if (!characterId) return '';
    return CHARACTER_NAMES[characterId] || characterId;
}

function getCharacterGender(characterId: string | null): 'male' | 'female' | 'neutral' {
    if (!characterId) return 'neutral';
    return CHARACTER_GENDER[characterId] || 'neutral';
}

export default function VNEngine({ chapter, onComplete }: VNEngineProps) {
    const {
        loadChapter,
        currentNode,
        isPlaying,
        isTyping,
        nextNode,
        currentBackground,
        currentCharacterSprite,
    } = useStoryStore();

    const { playBlip, playSFX } = useVNSound({ volume: 0.3 });
    const charCountRef = useRef(0);

    // blip 재생 콜백 - 타이핑 속도에 따라 재생 빈도 조절
    const handleCharacter = useCallback((currentSpeed: number) => {
        charCountRef.current++;

        // 속도에 따라 N번째 글자마다 재생
        // fastSpeed (18ms) → 5글자마다, baseSpeed (35ms) → 3글자마다, slowSpeed (70ms+) → 2글자마다
        let playEveryN = 3; // 기본값
        if (currentSpeed <= 20) {
            playEveryN = 5;  // 빠른 속도: 5글자마다
        } else if (currentSpeed <= 40) {
            playEveryN = 3;  // 보통 속도: 3글자마다
        } else {
            playEveryN = 2;  // 느린 속도: 2글자마다
        }

        if (charCountRef.current % playEveryN === 0) {
            const gender = getCharacterGender(currentNode?.character_id || null);
            playBlip(gender);
        }
    }, [currentNode?.character_id, playBlip]);

    // 노드 변경 시 카운터 리셋
    useEffect(() => {
        charCountRef.current = 0;
    }, [currentNode?.node_id]);

    const { displayedText, skip } = useTypewriter({
        baseSpeed: 35,
        slowSpeed: 70,
        fastSpeed: 18,
        onCharacter: handleCharacter,
    });

    // 챕터 로드
    useEffect(() => {
        loadChapter(chapter);
    }, [chapter, loadChapter]);

    // 효과음 재생
    useEffect(() => {
        if (currentNode?.sound_effect) {
            playSFX(currentNode.sound_effect);
        }
    }, [currentNode?.sound_effect, playSFX]);

    // 퀘스트 해금 및 활성화
    const unlockedQuestsRef = useRef<Set<string>>(new Set());

    useEffect(() => {
        if (currentNode?.unlockQuestIds && currentNode.unlockQuestIds.length > 0) {
            currentNode.unlockQuestIds.forEach(questId => {
                if (unlockedQuestsRef.current.has(questId)) return;

                // 퀘스트 활성화 API 호출 (쿠키 인증 포함)
                fetch('/api/quests/activate', {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    credentials: 'include',
                    body: JSON.stringify({ questId })
                }).then(res => {
                    if (res.ok) {
                        unlockedQuestsRef.current.add(questId);
                        console.log(`Quest activated: ${questId}`);
                    }
                }).catch(err => {
                    console.error(`Failed to activate quest ${questId}:`, err);
                    alert(`퀘스트[${questId}] 활성화 실패! 로그를 확인하세요.`);
                });
            });
        }
    }, [currentNode?.node_id, currentNode?.unlockQuestIds]);

    // 클릭 핸들러
    const handleClick = useCallback(() => {
        if (isTyping) {
            skip();
        } else {
            nextNode();
        }
    }, [isTyping, skip, nextNode]);

    // 키보드 핸들러
    useEffect(() => {
        const handleKeyDown = (e: KeyboardEvent) => {
            if (e.key === ' ' || e.key === 'Enter') {
                e.preventDefault();
                handleClick();
            }
        };

        window.addEventListener('keydown', handleKeyDown);
        return () => window.removeEventListener('keydown', handleKeyDown);
    }, [handleClick]);

    if (!currentNode || !isPlaying) {
        return (
            <div className={styles.endScreen}>
                <div className={styles.endContent}>
                    <span className={styles.endIcon}>🎭</span>
                    <h2 className={styles.endTitle}>스토리 종료</h2>
                    <p className={styles.endText}>{chapter.title} 완료</p>
                    {onComplete && (
                        <button
                            className={styles.completeButton}
                            onClick={onComplete}
                        >
                            퀘스트 확인하기
                        </button>
                    )}
                </div>
            </div>
        );
    }

    const speakerName = getCharacterName(currentNode.character_id);
    const isNarration = !speakerName || speakerName === '' || speakerName === '내레이터';

    return (
        <div className={styles.container} onClick={handleClick}>
            {/* Background Layer */}
            <div className={styles.backgroundLayer}>
                {currentBackground ? (
                    <div
                        className={styles.backgroundImage}
                        style={{
                            backgroundImage: `url(${currentBackground.startsWith('/') ? currentBackground : `/images/backgrounds/${currentBackground}`})`,
                        }}
                    />
                ) : (
                    <div className={styles.defaultBackground}>
                        <span className={styles.chapterIcon}>🎭</span>
                        <span className={styles.chapterTitle}>{chapter.title}</span>
                    </div>
                )}
            </div>

            {/* Character Layer */}
            <div className={styles.characterLayer}>
                {currentCharacterSprite && (
                    <div className={styles.characterSprite}>
                        <img
                            src={currentCharacterSprite.startsWith('/') ? currentCharacterSprite : `/merchants/${currentCharacterSprite}`}
                            alt="Character"
                            className={styles.characterImage}
                            onError={(e) => {
                                e.currentTarget.style.display = 'none';
                            }}
                        />
                    </div>
                )}
            </div>

            {/* Dialogue Layer */}
            <div className={styles.dialogueLayer}>
                <div className={`${styles.dialogueBox} ${isNarration ? styles.narration : ''}`}>
                    {!isNarration && (
                        <div className={styles.speakerName}>{speakerName}</div>
                    )}
                    <div className={styles.dialogueText}>
                        {displayedText.split('\n').map((line, i) => (
                            <span key={i}>
                                {line}
                                {i < displayedText.split('\n').length - 1 && <br />}
                            </span>
                        ))}
                        {isTyping && <span className={styles.cursor}>|</span>}
                    </div>
                </div>
            </div>

            {/* Progress Indicator */}
            <div className={styles.progressIndicator}>
                <span className={styles.nodeIndex}>
                    {chapter.nodes.findIndex(n => n.node_id === currentNode.node_id) + 1} / {chapter.nodeCount}
                </span>
                {!isTyping && (
                    <span className={styles.clickHint}>▼ Click to continue</span>
                )}
            </div>
        </div>
    );
}
