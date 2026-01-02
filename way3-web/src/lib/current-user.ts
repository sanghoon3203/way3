
import { cookies } from 'next/headers';
import { verifyJwt } from '@/lib/auth';

export async function getCurrentUser() {
    const cookieStore = await cookies();
    const token = cookieStore.get('auth_token')?.value;

    if (!token) return null;

    try {
        const payload = await verifyJwt(token);
        return payload as { id: string; username: string; role: string };
    } catch (error) {
        return null;
    }
}
