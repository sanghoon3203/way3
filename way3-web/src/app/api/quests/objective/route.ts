//
import { NextRequest, NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { getCurrentUser } from '@/lib/current-user';

/**
 * POST /api/quests/objective
 * 퀘스트 목표 완료 처리
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

        const { questId, objectiveId } = await request.json();
        if (!questId || !objectiveId) {
            return NextResponse.json(
                { success: false, error: 'questId와 objectiveId가 필요합니다.' },
                { status: 400 }
            );
        }

        // 현재 유저 퀘스트 조회
        const userQuest = await prisma.userQuest.findUnique({
            where: {
                userId_questId: {
                    userId,
                    questId,
                },
            },
        });

        if (!userQuest) {
            return NextResponse.json(
                { success: false, error: '퀘스트를 찾을 수 없습니다.' },
                { status: 404 }
            );
        }

        // completedObjectiveIds 업데이트
        const completedIds: string[] = JSON.parse(userQuest.completedObjectiveIds || '[]');
        if (!completedIds.includes(objectiveId)) {
            completedIds.push(objectiveId);
        }

        const updatedQuest = await prisma.userQuest.update({
            where: { id: userQuest.id },
            data: {
                completedObjectiveIds: JSON.stringify(completedIds),
            },
        });

        return NextResponse.json({
            success: true,
            data: {
                questId: updatedQuest.questId,
                completedObjectiveIds: completedIds,
            },
            message: '목표가 완료되었습니다.',
        });
    } catch (error) {
        console.error('목표 완료 처리 실패:', error);
        return NextResponse.json(
            { success: false, error: '목표 완료 처리에 실패했습니다.' },
            { status: 500 }
        );
    }
}
