//
import { NextRequest, NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { getCurrentUser } from '@/lib/current-user';

/**
 * POST /api/quests/activate
 * 퀘스트를 활성화 (시작)
 */
export async function POST(request: NextRequest) {
    try {
        // 인증 확인 (쿠키 기반)
        const userPayload = await getCurrentUser();

        if (!userPayload) {
            console.log(`[API] Quest activation failed: No user payload`);
            return NextResponse.json(
                { success: false, error: '인증이 필요합니다.' },
                { status: 401 }
            );
        }

        const userId = userPayload.id;
        const { questId } = await request.json();

        console.log(`[API] Activating quest: ${questId} for user: ${userId}`);

        if (!questId) {
            return NextResponse.json(
                { success: false, error: 'questId가 필요합니다.' },
                { status: 400 }
            );
        }

        // upsert로 퀘스트 상태 업데이트 또는 생성
        const userQuest = await prisma.userQuest.upsert({
            where: {
                userId_questId: {
                    userId,
                    questId,
                },
            },
            update: {
                status: 'ACTIVE',
                startedAt: new Date(),
            },
            create: {
                userId,
                questId,
                status: 'ACTIVE',
                startedAt: new Date(),
                completedObjectiveIds: '[]',
            },
        });

        console.log(`[API] Quest activated successfully: ${questId}`);

        return NextResponse.json({
            success: true,
            data: {
                questId: userQuest.questId,
                status: userQuest.status,
                startedAt: userQuest.startedAt,
            },
            message: '퀘스트가 활성화되었습니다.',
        });
    } catch (error) {
        console.error('퀘스트 활성화 실패:', error);
        return NextResponse.json(
            { success: false, error: '퀘스트 활성화에 실패했습니다.' },
            { status: 500 }
        );
    }
}
