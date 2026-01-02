import { useEffect, useRef, useCallback } from 'react';
import { useStoryStore } from '../store/storyStore';

interface TypewriterOptions {
    baseSpeed?: number;
    slowSpeed?: number;
    fastSpeed?: number;
    onCharacter?: (currentSpeed: number) => void;  // 현재 타이핑 속도 전달
    onComplete?: () => void;
}

/**
 * 타이프라이터 효과 훅
 * 
 * 스토어의 cleanedText를 사용하여 태그가 제거된 텍스트를 타이핑합니다.
 */
export function useTypewriter(options: TypewriterOptions = {}) {
    const {
        baseSpeed = 50,
        slowSpeed = 100,
        fastSpeed = 25,
        onCharacter,
        onComplete,
    } = options;

    const {
        fullText,
        cleanedText,
        isTyping,
        displayedText,
        updateDisplayedText,
        setTypingComplete
    } = useStoryStore();

    const timeoutRef = useRef<number | null>(null);
    const indexRef = useRef(0);
    const speedRef = useRef(baseSpeed);

    // 현재 인덱스까지의 속도 계산 (원본 텍스트의 태그 기준)
    const calculateSpeedAtIndex = useCallback((rawText: string, targetCleanIndex: number): number => {
        let rawIndex = 0;
        let cleanIndex = 0;
        let currentSpeed = baseSpeed;

        while (cleanIndex < targetCleanIndex && rawIndex < rawText.length) {
            if (rawText[rawIndex] === '<') {
                const remaining = rawText.slice(rawIndex);

                if (remaining.match(/^<[sS]>/)) {
                    currentSpeed = slowSpeed;
                    rawIndex += 3;
                    continue;
                } else if (remaining.match(/^<[nN]>/)) {
                    currentSpeed = baseSpeed;
                    rawIndex += 3;
                    continue;
                } else if (remaining.match(/^<[fF]>/)) {
                    currentSpeed = fastSpeed;
                    rawIndex += 3;
                    continue;
                } else if (remaining.match(/^<[tT]>/)) {
                    rawIndex += 3;
                    continue;
                } else if (remaining.match(/^<\/[stnfSTNF]>/)) {
                    rawIndex += 4;
                    continue;
                }
            }

            rawIndex++;
            cleanIndex++;
        }

        return currentSpeed;
    }, [baseSpeed, slowSpeed, fastSpeed]);

    // 타이핑 시작
    useEffect(() => {
        if (!isTyping || !cleanedText) return;

        // 타이틀 태그(<t>로 시작)면 즉시 표시
        if (fullText.match(/^<[tT]>/)) {
            updateDisplayedText(cleanedText);
            setTypingComplete();
            onComplete?.();
            return;
        }

        indexRef.current = 0;
        speedRef.current = baseSpeed;

        const type = () => {
            if (indexRef.current >= cleanedText.length) {
                setTypingComplete();
                onComplete?.();
                return;
            }

            // 현재 위치의 속도 계산
            speedRef.current = calculateSpeedAtIndex(fullText, indexRef.current);

            // 다음 글자 추가
            indexRef.current++;
            updateDisplayedText(cleanedText.slice(0, indexRef.current));

            // 글자 타이핑 콜백 (사운드용) - 현재 속도 전달
            onCharacter?.(speedRef.current);

            timeoutRef.current = window.setTimeout(type, speedRef.current);
        };

        type();

        return () => {
            if (timeoutRef.current) {
                clearTimeout(timeoutRef.current);
            }
        };
    }, [fullText, cleanedText, isTyping, baseSpeed, calculateSpeedAtIndex, updateDisplayedText, setTypingComplete, onCharacter, onComplete]);

    // 스킵 함수
    const skip = useCallback(() => {
        if (timeoutRef.current) {
            clearTimeout(timeoutRef.current);
        }
        updateDisplayedText(cleanedText);
        setTypingComplete();
        onComplete?.();
    }, [cleanedText, updateDisplayedText, setTypingComplete, onComplete]);

    return {
        displayedText,
        isTyping,
        skip,
    };
}
