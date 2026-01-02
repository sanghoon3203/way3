//
import { NextRequest, NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { getCurrentUser } from '@/lib/current-user';

/**
 * POST /api/quests/seed
 * 테스트용 퀘스트 데이터 시딩
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

        // 기본 퀘스트 시딩: prologue_main_001을 ACTIVE로 추가
        const initialQuest = await prisma.userQuest.upsert({
            where: {
                userId_questId: {
                    userId,
                    questId: 'prologue_main_001',
                },
            },
            update: {
                status: 'ACTIVE',
                startedAt: new Date(),
            },
            create: {
                userId,
                questId: 'prologue_main_001',
                status: 'ACTIVE',
                startedAt: new Date(),
                completedObjectiveIds: '[]',
            },
        });

        console.log(`[Quest Seed] Created/Updated quest for user ${userId}:`, initialQuest);

        // 모든 유저 퀘스트 조회
        const allUserQuests = await prisma.userQuest.findMany({
            where: { userId },
        });

        return NextResponse.json({
            success: true,
            data: {
                seededQuest: initialQuest,
                totalQuests: allUserQuests.length,
                allQuests: allUserQuests,
            },
            message: '테스트 퀘스트 데이터가 시딩되었습니다.',
        });
    } catch (error) {
        console.error('퀘스트 시딩 실패:', error);
        return NextResponse.json(
            { success: false, error: '퀘스트 시딩에 실패했습니다.' },
            { status: 500 }
        );
    }
}
