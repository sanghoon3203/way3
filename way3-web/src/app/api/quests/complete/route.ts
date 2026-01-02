//
import { NextRequest, NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { getCurrentUser } from '@/lib/current-user';
import questData from '@/data/quests/main_quests.json';
import type { Quest } from '@/lib/types/quest';

/**
 * POST /api/quests/complete
 * 퀘스트 완료 처리 및 다음 퀘스트 해금
 */
export async function POST(request: NextRequest) {
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

        const { questId } = await request.json();
        if (!questId) {
            return NextResponse.json(
                { success: false, error: 'questId가 필요합니다.' },
                { status: 400 }
            );
        }

        // 퀘스트 완료 처리
        const userQuest = await prisma.userQuest.update({
            where: {
                userId_questId: {
                    userId,
                    questId,
                },
            },
            data: {
                status: 'COMPLETED',
                completedAt: new Date(),
            },
        });

        // JSON에서 퀘스트 정의 찾기
        const questDef = (questData.quests as Quest[]).find(q => q.id === questId);
        const unlockedQuestIds: string[] = [];

        // 다음 퀘스트 해금
        if (questDef?.unlocksQuestIds) {
            for (const unlockId of questDef.unlocksQuestIds) {
                await prisma.userQuest.upsert({
                    where: {
                        userId_questId: {
                            userId,
                            questId: unlockId,
                        },
                    },
                    update: {
                        status: 'UNLOCKED',
                    },
                    create: {
                        userId,
                        questId: unlockId,
                        status: 'UNLOCKED',
                        completedObjectiveIds: '[]',
                    },
                });
                unlockedQuestIds.push(unlockId);
            }
        }

        // 보상 지급 (크레딧)
        if (questDef?.rewards?.money) {
            await prisma.user.update({
                where: { id: userId },
                data: {
                    credits: { increment: questDef.rewards.money },
                },
            });
        }

        // 구역 해금 처리
        const unlockedDistrictIds: string[] = [];
        if (questDef?.unlocksDistricts && questDef.unlocksDistricts.length > 0) {
            // 현재 유저의 해금된 구역 목록 조회
            const user = await prisma.user.findUnique({
                where: { id: userId },
            }) as unknown as { unlockedDistricts: string } | null;

            const currentDistricts: string[] = JSON.parse(user?.unlockedDistricts || '[]');

            // 새로운 구역들 추가 (중복 제거)
            for (const districtId of questDef.unlocksDistricts) {
                if (!currentDistricts.includes(districtId)) {
                    currentDistricts.push(districtId);
                    unlockedDistrictIds.push(districtId);
                }
            }

            // DB 업데이트
            if (unlockedDistrictIds.length > 0) {
                await (prisma.user as any).update({
                    where: { id: userId },
                    data: {
                        unlockedDistricts: JSON.stringify(currentDistricts),
                    },
                });
                console.log(`[Quest Complete] Unlocked districts: ${unlockedDistrictIds.join(', ')}`);
            }
        }

        return NextResponse.json({
            success: true,
            data: {
                questId: userQuest.questId,
                status: userQuest.status,
                completedAt: userQuest.completedAt,
                unlockedQuestIds,
                unlockedDistrictIds,
                rewards: questDef?.rewards,
            },
            message: '퀘스트가 완료되었습니다!',
        });
    } catch (error) {
        console.error('퀘스트 완료 처리 실패:', error);
        return NextResponse.json(
            { success: false, error: '퀘스트 완료 처리에 실패했습니다.' },
            { status: 500 }
        );
    }
}
