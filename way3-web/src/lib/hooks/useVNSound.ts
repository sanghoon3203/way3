import { useRef, useCallback } from 'react';

interface SoundOptions {
    volume?: number;
}

/**
 * VN 사운드 관리 훅
 * 대화 blip 사운드, 효과음 관리
 */
export function useVNSound(options: SoundOptions = {}) {
    const { volume = 0.3 } = options;

    const blipAudioRef = useRef<HTMLAudioElement | null>(null);
    const sfxAudioRef = useRef<HTMLAudioElement | null>(null);

    // blip 사운드 파일 경로
    const blipSounds = {
        male: '/Sound/sfx-blipmale.wav',
        female: '/Sound/sfx-blipfemale.wav',
        neutral: '/Sound/sfx-blipmale.wav', // Default to male for neutral
    };

    // blip 사운드 재생 (타이핑 시)
    const playBlip = useCallback((gender: 'male' | 'female' | 'neutral' = 'neutral') => {
        try {
            const soundPath = blipSounds[gender];
            const audio = new Audio(soundPath);
            audio.volume = volume;

            // 짧은 재생을 위해 무작위 피치 조절은 HTML Audio에서 어렵으므로 생략하거나
            // playbackRate를 살짝 조절하여 변화를 줄 수 있음
            audio.playbackRate = 0.9 + Math.random() * 0.2; // 0.9 ~ 1.1 Variation

            // 이전 오디오가 있으면 정지? (겹치는 게 자연스러울 수 있음)
            // 타이핑 속도가 빠르면 겹치는 게 나으므로 새로운 인스턴스 생성
            audio.play().catch(() => {
                // 자동 재생 정책 등으로 실패 시 무시
            });
        } catch (e) {
            console.warn('Audio play failed', e);
        }
    }, [volume]);

    // 효과음 재생
    const playSFX = useCallback((soundPath: string) => {
        if (!soundPath) return;

        try {
            if (sfxAudioRef.current) {
                sfxAudioRef.current.pause();
            }

            const audio = new Audio(`/sounds/${soundPath}`);
            audio.volume = volume;
            sfxAudioRef.current = audio;
            audio.play().catch(() => {
                // 자동 재생 실패 무시
            });
        } catch (e) {
            console.warn('Failed to play SFX:', soundPath);
        }
    }, [volume]);

    // 정지
    const stopAll = useCallback(() => {
        if (blipAudioRef.current) {
            blipAudioRef.current.pause();
        }
        if (sfxAudioRef.current) {
            sfxAudioRef.current.pause();
        }
    }, []);

    return {
        playBlip,
        playSFX,
        stopAll,
    };
}
