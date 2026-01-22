import { verify } from 'hono/jwt';
export async function authMiddleware(c, next) {
    const authHeader = c.req.header('Authorization');
    if (!authHeader?.startsWith('Bearer ')) {
        return c.json({ error: 'Unauthorized' }, 401);
    }
    try {
        const token = authHeader.slice(7);
        const payload = await verify(token, process.env.JWT_SECRET, 'HS256');
        c.set('auth', { userId: payload.sub, email: payload.email });
        await next();
    }
    catch {
        return c.json({ error: 'Invalid token' }, 401);
    }
}
export function getAuth(c) {
    return c.get('auth');
}
