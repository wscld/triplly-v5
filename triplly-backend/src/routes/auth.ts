import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { sign } from 'hono/jwt';
import bcrypt from 'bcryptjs';
import { AppDataSource } from '../data-source.js';
import { User } from '../entities/index.js';
import { authMiddleware, getAuth } from '../middleware/index.js';
import { uploadProfilePhoto } from '../services/storage.js';

const auth = new Hono();

const registerSchema = z.object({
    email: z.string().email(),
    password: z.string().min(6),
    name: z.string().min(1),
});

const loginSchema = z.object({
    email: z.string().email(),
    password: z.string(),
});

const updateProfileSchema = z.object({
    name: z.string().min(1).optional(),
});

// POST /auth/register
auth.post('/register', zValidator('json', registerSchema), async (c) => {
    const { email, password, name } = c.req.valid('json');
    const userRepo = AppDataSource.getRepository(User);

    // Check if user exists
    const existing = await userRepo.findOne({ where: { email } });
    if (existing) {
        return c.json({ error: 'Email already registered' }, 400);
    }

    // Hash password and create user
    const passwordHash = await bcrypt.hash(password, 10);
    const user = userRepo.create({ email, passwordHash, name });
    await userRepo.save(user);

    // Generate token
    const token = await sign(
        { sub: user.id, email: user.email },
        process.env.JWT_SECRET!
    );

    return c.json({
        user: { id: user.id, email: user.email, name: user.name },
        token,
    }, 201);
});

// POST /auth/login
auth.post('/login', zValidator('json', loginSchema), async (c) => {
    const { email, password } = c.req.valid('json');
    const userRepo = AppDataSource.getRepository(User);

    const user = await userRepo.findOne({ where: { email } });
    if (!user) {
        return c.json({ error: 'Invalid credentials' }, 401);
    }

    const valid = await bcrypt.compare(password, user.passwordHash);
    if (!valid) {
        return c.json({ error: 'Invalid credentials' }, 401);
    }

    const token = await sign(
        { sub: user.id, email: user.email },
        process.env.JWT_SECRET!
    );

    return c.json({
        user: { id: user.id, email: user.email, name: user.name },
        token,
    });
});

// GET /auth/me
auth.get('/me', authMiddleware, async (c) => {
    const { userId } = getAuth(c);
    const userRepo = AppDataSource.getRepository(User);

    const user = await userRepo.findOne({ where: { id: userId } });
    if (!user) {
        return c.json({ error: 'User not found' }, 404);
    }

    return c.json({
        id: user.id,
        email: user.email,
        name: user.name,
        profilePhotoUrl: user.profilePhotoUrl,
        createdAt: user.createdAt,
    });
});

// PATCH /auth/me - Update profile
auth.patch('/me', authMiddleware, zValidator('json', updateProfileSchema), async (c) => {
    const { userId } = getAuth(c);
    const data = c.req.valid('json');
    const userRepo = AppDataSource.getRepository(User);

    const user = await userRepo.findOne({ where: { id: userId } });
    if (!user) {
        return c.json({ error: 'User not found' }, 404);
    }

    if (data.name !== undefined) {
        user.name = data.name;
    }

    await userRepo.save(user);

    return c.json({
        id: user.id,
        email: user.email,
        name: user.name,
        profilePhotoUrl: user.profilePhotoUrl,
        createdAt: user.createdAt,
    });
});

// POST /auth/me/photo - Upload profile photo
auth.post('/me/photo', authMiddleware, async (c) => {
    const { userId } = getAuth(c);
    const userRepo = AppDataSource.getRepository(User);

    const user = await userRepo.findOne({ where: { id: userId } });
    if (!user) {
        return c.json({ error: 'User not found' }, 404);
    }

    const formData = await c.req.formData();
    const file = formData.get('file');

    if (!file || !(file instanceof File)) {
        return c.json({ error: 'No file provided' }, 400);
    }

    // Validate file type
    const validTypes = ['image/jpeg', 'image/png', 'image/webp', 'image/heic'];
    if (!validTypes.includes(file.type)) {
        return c.json({ error: 'Invalid file type. Allowed: JPEG, PNG, WebP, HEIC' }, 400);
    }

    // Validate file size (5MB max)
    if (file.size > 5 * 1024 * 1024) {
        return c.json({ error: 'File too large. Maximum size is 5MB' }, 400);
    }

    try {
        const ext = file.name.split('.').pop() || 'jpg';
        const path = `${userId}/${Date.now()}.${ext}`;

        const publicUrl = await uploadProfilePhoto(file, path);
        if (!publicUrl) {
            return c.json({ error: 'Failed to upload photo' }, 500);
        }

        user.profilePhotoUrl = publicUrl;
        await userRepo.save(user);

        return c.json({
            id: user.id,
            email: user.email,
            name: user.name,
            profilePhotoUrl: user.profilePhotoUrl,
            createdAt: user.createdAt,
        });
    } catch (error) {
        console.error('Failed to upload profile photo:', error);
        return c.json({ error: 'Failed to upload photo' }, 500);
    }
});

export default auth;
