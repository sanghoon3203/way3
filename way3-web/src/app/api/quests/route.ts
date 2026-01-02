//
import { NextRequest, NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { getCurrentUser } from '@/lib/current-user';
import questData from '@/data/quests/main_quests.json';
import type { Quest } from '@/lib/types/quest';

/**
 * GET /api/quests
 * 유저의 퀘스트 목록을 반환 (JSON 정의 + DB 상태 병합)
 */
export async function GET(request: NextRequest) {
    try {
        // 쿠키 기반 인증 확인
        const userPayload = await getCurrentUser();

        if (!userPayload) {
            return NextResponse.json(
                { success: false, error: '인증이 필요합니다.' },
                { status: 401 }
            );
        }

        const userId = userPayload.id;

        // DB에서 유저의 퀘스트 진행 상태 가져오기
        const userQuests = await prisma.userQuest.findMany({
            where: { userId },
        });

        // JSON 퀘스트 정의와 DB 상태 병합
        const quests = (questData.quests as Quest[]).map(quest => {
            const userQuest = userQuests.find((uq: { questId: string }) => uq.questId === quest.id);

            if (userQuest) {
                // DB에 상태가 있으면 병합
                const completedObjectiveIds: string[] = JSON.parse(userQuest.completedObjectiveIds || '[]');

                return {
                    ...quest,
                    isActive: userQuest.status === 'ACTIVE',
                    isCompleted: userQuest.status === 'COMPLETED',
                    isUnlocked: userQuest.status !== 'LOCKED',
                    objectives: quest.objectives.map(obj => ({
                        ...obj,
                        completed: completedObjectiveIds.includes(obj.id),
                    })),
                };
            }

            // DB에 상태가 없으면 기본값 사용 (첫 퀘스트만 해금)
            const isFirstQuest = quest.id === 'prologue_main_001';
            return {
                ...quest,
                isActive: isFirstQuest,
                isCompleted: false,
                isUnlocked: isFirstQuest,
            };
        });

        return NextResponse.json({
            success: true,
            data: {
                quests,
                totalCount: quests.length,
            },
        });
    } catch (error) {
        console.error('퀘스트 조회 실패:', error);
        return NextResponse.json(
            { success: false, error: '퀘스트 조회에 실패했습니다.' },
            { status: 500 }
        );
    }
}
