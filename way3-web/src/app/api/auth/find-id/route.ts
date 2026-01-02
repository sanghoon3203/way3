
import { NextResponse } from 'next/server';
import { z } from 'zod';
import prisma from '@/lib/prisma';

const findIdSchema = z.object({
    email: z.string().email('유효하지 않은 이메일 형식입니다.'),
});

export async function POST(req: Request) {
    try {
        const body = await req.json();
        const validation = findIdSchema.safeParse(body);

        if (!validation.success) {
            return NextResponse.json(
                { error: validation.error.issues[0].message },
                { status: 400 }
            );
        }

        const { email } = validation.data;

        const user = await prisma.user.findUnique({
            where: { email },
        });

        if (!user) {
            // 보안을 위해 사용자가 없어도 모호한 메시지 또는 404
            return NextResponse.json(
                { error: '해당 이메일로 가입된 계정을 찾을 수 없습니다.' },
                { status: 404 }
            );
        }

        // 아이디 일부 가리기 (예: use***)
        const maskedUsername = user.username.length > 3
            ? user.username.slice(0, 3) + '*'.repeat(user.username.length - 3)
            : user.username;

        return NextResponse.json({ username: user.username, message: `회원님의 아이디는 ${user.username} 입니다.` });
    } catch (error) {
        console.error('Find ID error:', error);
        return NextResponse.json(
            { error: '아이디 찾기 중 오류가 발생했습니다.' },
            { status: 500 }
        );
    }
}
