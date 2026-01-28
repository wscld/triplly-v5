import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { sign } from 'hono/jwt';
import bcrypt from 'bcryptjs';
import * as jose from 'jose';
import { AppDataSource } from '../data-source.js';
import { User } from '../entities/index.js';
import { authMiddleware, getAuth } from '../middleware/index.js';
import { uploadProfilePhoto } from '../services/storage.js';

// Apple's public key endpoint
const APPLE_KEYS_URL = 'https://appleid.apple.com/auth/keys';

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
    username: z.string().min(3).max(30).regex(/^[a-z0-9_]+$/).optional(),
});

const appleSignInSchema = z.object({
    identityToken: z.string(),
    name: z.string().optional(),
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
        user: { id: user.id, email: user.email, name: user.name, username: user.username },
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

    if (!user.passwordHash) {
        return c.json({ error: 'Please sign in with Apple' }, 401);
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
        user: { id: user.id, email: user.email, name: user.name, username: user.username },
        token,
    });
});

// POST /auth/apple - Sign in with Apple
auth.post('/apple', zValidator('json', appleSignInSchema), async (c) => {
    const { identityToken, name } = c.req.valid('json');
    const userRepo = AppDataSource.getRepository(User);

    try {
        // Fetch Apple's public keys
        const JWKS = jose.createRemoteJWKSet(new URL(APPLE_KEYS_URL));

        // Verify the identity token
        const { payload } = await jose.jwtVerify(identityToken, JWKS, {
            issuer: 'https://appleid.apple.com',
            audience: process.env.APPLE_CLIENT_ID || 'wescld.com.Triplly',
        });

        const appleId = payload.sub;
        const email = payload.email as string | undefined;

        if (!appleId) {
            return c.json({ error: 'Invalid Apple identity token' }, 401);
        }

        // Find existing user by appleId
        let user = await userRepo.findOne({ where: { appleId } });

        if (!user && email) {
            // Check if user exists with this email (link accounts)
            user = await userRepo.findOne({ where: { email } });
            if (user) {
                // Link Apple ID to existing account
                user.appleId = appleId;
                await userRepo.save(user);
            }
        }

        if (!user) {
            // Create new user
            const userName = name || email?.split('@')[0] || 'User';
            user = userRepo.create({
                email: email || `${appleId}@privaterelay.appleid.com`,
                appleId,
                name: userName,
                passwordHash: null,
            });
            await userRepo.save(user);
        }

        // Generate JWT token
        const token = await sign(
            { sub: user.id, email: user.email },
            process.env.JWT_SECRET!
        );

        return c.json({
            user: { id: user.id, email: user.email, name: user.name, username: user.username },
            token,
        });
    } catch (error) {
        console.error('Apple sign in error:', error);
        return c.json({ error: 'Failed to verify Apple identity' }, 401);
    }
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
        username: user.username,
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

    if (data.username !== undefined) {
        // Check uniqueness
        const existing = await userRepo.findOne({ where: { username: data.username } });
        if (existing && existing.id !== user.id) {
            return c.json({ error: 'Username already taken' }, 400);
        }
        user.username = data.username;
    }

    await userRepo.save(user);

    return c.json({
        id: user.id,
        email: user.email,
        name: user.name,
        username: user.username,
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
            username: user.username,
            profilePhotoUrl: user.profilePhotoUrl,
            createdAt: user.createdAt,
        });
    } catch (error) {
        console.error('Failed to upload profile photo:', error);
        return c.json({ error: 'Failed to upload photo' }, 500);
    }
});

export default auth;
