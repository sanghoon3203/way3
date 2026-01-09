import { NextResponse } from 'next/server';
import { z } from 'zod';
import bcrypt from 'bcryptjs';
import { signJwt } from '@/lib/auth';
import prisma from '@/lib/prisma';

const loginSchema = z.object({
    username: z.string().min(1, '아이디를 입력해주세요.'),
    password: z.string().min(1, '비밀번호를 입력해주세요.'),
});

export async function POST(req: Request) {
    try {
        const body = await req.json();
        const validation = loginSchema.safeParse(body);

        if (!validation.success) {
            return NextResponse.json(
                { error: validation.error.issues[0].message },
                { status: 400 }
            );
        }

        const { username, password } = validation.data;

        // 사용자 조회
        const user = await prisma.user.findUnique({
            where: { username },
        });

        if (!user) {
            return NextResponse.json(
                { error: '아이디 또는 비밀번호가 올바르지 않습니다.' },
                { status: 401 }
            );
        }

        // 비밀번호 비교
        const match = await bcrypt.compare(password, user.password);
        if (!match) {
            return NextResponse.json(
                { error: '아이디 또는 비밀번호가 올바르지 않습니다.' },
                { status: 401 }
            );
        }

        // JWT 생성
        const token = await signJwt({
            id: user.id,
            username: user.username,
            role: 'user', // 추후 관리자 기능 확장 가능
        });

        // 쿠키 설정과 함께 응답
        const response = NextResponse.json(
            {
                message: '로그인 성공',
                user: {
                    id: user.id,
                    username: user.username,
                    currentChapter: user.currentChapter
                }
            },
            { status: 200 }
        );

        // HttpOnly 쿠키 설정
        response.cookies.set({
            name: 'auth_token',
            value: token,
            httpOnly: true,
            secure: process.env.NODE_ENV === 'production',
            sameSite: 'lax',
            maxAge: 60 * 60 * 24, // 1일
            path: '/',
        });

        return response;

    } catch (error: any) {
        console.error('Login error:', error);
        console.error('Error stack:', error.stack);
        return NextResponse.json(
            {
                error: '로그인 중 오류가 발생했습니다.',
                details: error.message,
                stack: error.stack,
                name: error.name
            },
            { status: 500 }
        );
    }
}
