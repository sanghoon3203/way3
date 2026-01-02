'use client';

import { useUser } from '@/lib/hooks/useUser';
import styles from './QuestList.module.css';
import questData from '@/data/quests/main_quests.json';

// 퀘스트 데이터 타입 정의 (임시)
interface QuestDef {
    id: string;
    title: string;
    description: string;
}

export default function QuestList() {
    const { user } = useUser();

    // 유저 퀘스트 상태 파싱 (UserQuest[] 타입이 있다고 가정)
    // 실제로는 user.quests 배열이 있을 것임.
    // 하지만 user 객체 타입 정의를 확인해야 함. useUser.ts에서는 quests가 아직 정의 안 되어 있을 수 있음.
    // 일단 user.quests가 있다고 가정하고 any로 처리하거나 타입을 보강해야 함.

    // useUser의 user 객체에 quests가 포함되어 있다고 가정 (api/user/me에서 include: quests 했으므로)
    const userQuests = (user as any)?.quests || [];

    // 퀘스트 정의와 유저 상태 병합
    const allQuests = (questData.quests as QuestDef[]).map(quest => {
        const uq = userQuests.find((q: any) => q.questId === quest.id);
        return {
            ...quest,
            status: uq ? uq.status : 'LOCKED',
            isUnlocked: uq && uq.status !== 'LOCKED'
        };
    }).filter(q => q.isUnlocked); // 해금된 퀘스트만 표시

    if (!user || allQuests.length === 0) {
        return (
            <div className={styles.emptyState}>
                <span className={styles.emptyIcon}>📜</span>
                <p>수행 중인 퀘스트가 없습니다.</p>
            </div>
        );
    }

    return (
        <div className={styles.container}>
            {allQuests.map((quest) => (
                <div
                    key={quest.id}
                    className={`${styles.questItem} ${quest.status === 'COMPLETED' ? styles.completed : styles.active}`}
                >
                    <div className={styles.questHeader}>
                        <span className={styles.questTitle}>{quest.title}</span>
                        <span className={styles.questStatus}>
                            {quest.status === 'COMPLETED' ? '완료됨' : '진행 중'}
                        </span>
                    </div>
                    <p className={styles.questDesc}>{quest.description}</p>
                </div>
            ))}
        </div>
    );
}
