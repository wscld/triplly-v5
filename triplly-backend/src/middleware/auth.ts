import type { Context, Next } from 'hono';
import { verify } from 'hono/jwt';

export interface AuthPayload {
    sub: string;
    email: string;
}

export async function authMiddleware(c: Context, next: Next) {
    const authHeader = c.req.header('Authorization');

    if (!authHeader?.startsWith('Bearer ')) {
        return c.json({ error: 'Unauthorized' }, 401);
    }

    try {
        const token = authHeader.slice(7);
        const payload = await verify(token, process.env.JWT_SECRET!, 'HS256');
        c.set('auth', { userId: payload.sub as string, email: payload.email as string });
        await next();
    } catch {
        return c.json({ error: 'Invalid token' }, 401);
    }
}

export function getAuth(c: Context): { userId: string; email: string } {
    return c.get('auth');
}

