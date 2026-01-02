
import { NextResponse } from 'next/server';
import type { NextRequest } from 'next/server';
import { verifyJwt } from '@/lib/auth';

// Paths that do not require authentication
const PUBLIC_PATHS = [
    '/login',
    '/register',
    '/api/auth/login',
    '/api/auth/register',
    '/api/auth/find-id',
    '/api/auth/find-password',
    '/_next', // Static files
    '/favicon.ico',
    '/images', // Public images
];

export async function middleware(req: NextRequest) {
    const { pathname } = req.nextUrl;

    // 1. Check if public path
    const isPublic = PUBLIC_PATHS.some(path => pathname.startsWith(path));
    if (isPublic) {
        return NextResponse.next();
    }

    // 2. Check for Token
    const token = req.cookies.get('auth_token')?.value;

    if (!token) {
        // No token -> Redirect to Login
        const loginUrl = new URL('/login', req.url);
        // Optional: Add ?returnUrl=...
        return NextResponse.redirect(loginUrl);
    }

    try {
        // 3. Verify Token
        // We verify here to ensure it's not just a garbage cookie
        // Note: Jose verifyJwt returns promise
        // But middleware runs on Edge runtime in some hosting.
        // Ensure 'jose' works in Edge. (It does)
        await verifyJwt(token);
        return NextResponse.next();
    } catch (error) {
        // Invalid token -> Delete cookie and Redirect
        const response = NextResponse.redirect(new URL('/login', req.url));
        response.cookies.delete('auth_token');
        return response;
    }
}

export const config = {
    matcher: [
        /*
         * Match all request paths except for the ones starting with:
         * - api (API routes - Warning: We DO want to protect some APIs, handled in logic above)
         * - _next/static (static files)
         * - _next/image (image optimization files)
         * - favicon.ico (favicon file)
         */
        '/((?!_next/static|_next/image|favicon.ico).*)',
    ],
};
