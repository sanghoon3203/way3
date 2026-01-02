
import { SignJWT, jwtVerify } from 'jose';

const SECRET_KEY = process.env.JWT_SECRET_KEY || 'way3-secret-key-dev-only-do-not-use-in-prod';
const key = new TextEncoder().encode(SECRET_KEY);

export async function signJwt(payload: any) {
    return await new SignJWT(payload)
        .setProtectedHeader({ alg: 'HS256' })
        .setIssuedAt()
        .setExpirationTime('24h') // 24시간 유효
        .sign(key);
}

export async function verifyJwt(token: string) {
    try {
        const { payload } = await jwtVerify(token, key);
        return payload;
    } catch (error) {
        return null;
    }
}
