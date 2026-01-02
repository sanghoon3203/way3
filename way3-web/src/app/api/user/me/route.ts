
import { NextResponse } from 'next/server';
import prisma from '@/lib/prisma';
import { getCurrentUser } from '@/lib/current-user';

export async function GET(req: Request) {
    try {
        const userPayload = await getCurrentUser();

        if (!userPayload) {
            return NextResponse.json(
                { error: '로그인이 필요합니다.' },
                { status: 401 }
            );
        }

        // DB에서 최신 정보 조회 (인벤토리 포함)
        const user = await prisma.user.findUnique({
            where: { id: userPayload.id },
            include: {
                inventory: true,
                quests: true,
            },
        });

        if (!user) {
            return NextResponse.json(
                { error: '사용자 정보를 찾을 수 없습니다.' },
                { status: 404 }
            );
        }

        // 비밀번호 제외
        const { password: _, ...userInfo } = user;

        return NextResponse.json({ user: userInfo }, { status: 200 });
    } catch (error: any) {
        console.error('Fetch User error:', error);
        return NextResponse.json(
            {
                error: '사용자 정보를 불러오는 중 오류가 발생했습니다.',
                details: error.message
            },
            { status: 500 }
        );
    }
}
