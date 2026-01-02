
import { NextResponse } from 'next/server';
import { z } from 'zod';
import bcrypt from 'bcryptjs';
import prisma from '@/lib/prisma';

// 입력값 검증 스키마 (Zod)
const registerSchema = z.object({
    username: z.string().min(3, '아이디는 3글자 이상이어야 합니다.'),
    email: z.string().email('유효하지 않은 이메일 형식입니다.'),
    password: z.string().min(6, '비밀번호는 6글자 이상이어야 합니다.'),
});

export async function POST(req: Request) {
    try {
        const body = await req.json();

        // 1. 유효성 검사
        const validation = registerSchema.safeParse(body);
        if (!validation.success) {
            return NextResponse.json(
                { error: validation.error.issues[0].message },
                { status: 400 }
            );
        }

        const { username, email, password } = validation.data;

        // 2. 중복 체크
        const existingUser = await prisma.user.findFirst({
            where: {
                OR: [{ username }, { email }],
            },
        });

        if (existingUser) {
            return NextResponse.json(
                { error: '이미 존재하는 아이디 또는 이메일입니다.' },
                { status: 409 }
            );
        }

        // 3. 비밀번호 해싱
        const hashedPassword = await bcrypt.hash(password, 10);

        // 4. DB 저장
        const newUser = await prisma.user.create({
            data: {
                username,
                email,
                password: hashedPassword,
                // 초기 챕터/설정은 default 값 사용
            },
        });

        // 비밀번호 제외하고 반환
        const { password: _, ...userWithoutPassword } = newUser;

        return NextResponse.json(userWithoutPassword, { status: 201 });
    } catch (error: any) {
        console.error('Registration error:', error);
        require('fs').appendFileSync('error.log', `Registration error: ${JSON.stringify(error, Object.getOwnPropertyNames(error))}\n`);
        return NextResponse.json(
            {
                error: '회원가입 중 오류가 발생했습니다.',
                details: error.message,
                stack: error.stack
            },
            { status: 500 }
        );
    }
}
