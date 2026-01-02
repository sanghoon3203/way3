
import { NextResponse } from 'next/server';
import { z } from 'zod';
import prisma from '@/lib/prisma';

const findPwSchema = z.object({
    username: z.string().min(1, '아이디를 입력해주세요.'),
    email: z.string().email('유효하지 않은 이메일 형식입니다.'),
});

export async function POST(req: Request) {
    try {
        const body = await req.json();
        const validation = findPwSchema.safeParse(body);

        if (!validation.success) {
            return NextResponse.json(
                { error: validation.error.issues[0].message },
                { status: 400 }
            );
        }

        const { username, email } = validation.data;

        const user = await prisma.user.findFirst({
            where: {
                username,
                email,
            },
        });

        if (!user) {
            return NextResponse.json(
                { error: '일치하는 회원 정보를 찾을 수 없습니다.' },
                { status: 404 }
            );
        }

        // 실제로는 이메일 발송 로직이 들어가야 함
        // 여기서는 성공 메시지만 반환 (Mock)
        console.log(`[Mock Email Sent] Password reset link for ${email}`);

        return NextResponse.json({
            message: '비밀번호 재설정 링크를 이메일로 발송했습니다. (실제 발송은 미구현)'
        });
    } catch (error) {
        console.error('Find Password error:', error);
        return NextResponse.json(
            { error: '비밀번호 찾기 중 오류가 발생했습니다.' },
            { status: 500 }
        );
    }
}
