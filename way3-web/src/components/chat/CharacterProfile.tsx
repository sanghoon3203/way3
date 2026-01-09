'use client';
import styles from './CharacterProfile.module.css';
import type { Merchant } from '@/lib/store/gpsStore';
import { hasSubstory } from '@/data/substoryMap';

interface CharacterProfileProps {
    merchant: Merchant;
}

export default function CharacterProfile({ merchant }: CharacterProfileProps) {
    const hasStory = hasSubstory(merchant.id);

    return (
        <div className={styles.container}>
            {/* 프로필 이미지 */}
            <div className={styles.imageWrapper}>
                <img
                    src={merchant.faceshot || '/images/default_avatar.png'}
                    alt={merchant.name}
                    className={styles.profileImage}
                    onError={(e) => {
                        (e.target as HTMLImageElement).src = '/images/default_avatar.png';
                    }}
                />
            </div>

            {/* 이름 */}
            <h2 className={styles.name}>{merchant.name}</h2>

            {/* 정보 테이블 */}
            <div className={styles.infoTable}>
                <div className={styles.infoRow}>
                    <span className={styles.infoLabel}>지역</span>
                    <span className={styles.infoValue}>{merchant.district || '미정'}</span>
                </div>
                <div className={styles.infoRow}>
                    <span className={styles.infoLabel}>상태</span>
                    <span className={styles.infoValue}>
                        {hasStory ? '📖 스토리 있음' : '🔒 스토리 없음'}
                    </span>
                </div>
            </div>

            {/* 인사말 */}
            <div className={styles.greeting}>
                <span className={styles.greetingLabel}>인사말</span>
                <p className={styles.greetingText}>
                    {getGreeting(merchant.id)}
                </p>
            </div>
        </div>
    );
}

// 캐릭터별 인사말 (추후 데이터화 가능)
function getGreeting(merchantId: string): string {
    const greetings: Record<string, string> = {
        'seoyena': '안녕하세요. 저는 서예나입니다. 정보는 제가 드릴게요.',
        'jubulsu': '불길이 타오르는 곳에서 진정한 무기가 탄생하지.',
        'anipark': '롯데월드에 오신 걸 환영해요~!',
        'jinbaekho': '강동의 호랑이라 불리는 진백호다.',
        'alicegang': '비밀의 무언가를 찾고 있나요?',
    };
    return greetings[merchantId] || '반갑습니다.';
}
