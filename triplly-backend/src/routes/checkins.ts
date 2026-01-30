import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { AppDataSource } from '../data-source.js';
import { CheckIn, Activity, TravelMember } from '../entities/index.js';
import { authMiddleware, getAuth } from '../middleware/index.js';
import { findOrCreatePlace } from '../services/places.js';

const checkins = new Hono();

checkins.use('*', authMiddleware);

const createCheckInSchema = z.object({
    activityId: z.string().uuid(),
});

function formatCheckIn(ci: CheckIn) {
    return {
        id: ci.id,
        placeId: ci.placeId,
        userId: ci.userId,
        activityId: ci.activityId,
        createdAt: ci.createdAt,
        place: ci.place ? {
            id: ci.place.id,
            name: ci.place.name,
            latitude: ci.place.latitude,
            longitude: ci.place.longitude,
            address: ci.place.address,
        } : undefined,
        user: ci.user ? {
            id: ci.user.id,
            name: ci.user.name,
            profilePhotoUrl: ci.user.profilePhotoUrl,
        } : undefined,
    };
}

// POST /checkins - Check in at activity's place
checkins.post('/', async (c) => {
    const { userId } = getAuth(c);

    let body: any;
    try {
        body = await c.req.json();
    } catch {
        return c.json({ error: 'Invalid JSON body' }, 400);
    }

    const activityId = body?.activityId;
    if (!activityId || typeof activityId !== 'string') {
        return c.json({ error: 'activityId is required' }, 400);
    }

    const activityRepo = AppDataSource.getRepository(Activity);
    const checkInRepo = AppDataSource.getRepository(CheckIn);

    // Find activity
    const activity = await activityRepo.findOne({ where: { id: activityId } });
    if (!activity) {
        return c.json({ error: 'Activity not found' }, 404);
    }

    // Verify user is a member of the travel
    const memberRepo = AppDataSource.getRepository(TravelMember);
    const member = await memberRepo.findOne({
        where: { travelId: activity.travelId, userId },
    });
    if (!member) {
        return c.json({ error: 'Not a member of this travel' }, 403);
    }

    // Ensure activity has a place; auto-create if needed
    let placeId = activity.placeId;
    if (!placeId) {
        try {
            const place = await findOrCreatePlace({
                name: activity.title,
                latitude: activity.latitude,
                longitude: activity.longitude,
                address: activity.address,
            });
            placeId = place.id;
            activity.placeId = place.id;
            await activityRepo.save(activity);
        } catch (err) {
            console.error('Failed to create place for check-in:', err);
            return c.json({ error: 'Failed to create place' }, 500);
        }
    }

    // Check for existing check-in — return it instead of erroring (idempotent)
    const existing = await checkInRepo.findOne({
        where: { placeId, userId },
        relations: ['place', 'user'],
    });
    if (existing) {
        return c.json(formatCheckIn(existing));
    }

    const checkIn = checkInRepo.create({
        placeId,
        userId,
        activityId,
    });
    await checkInRepo.save(checkIn);

    // Return with relations
    const result = await checkInRepo.findOne({
        where: { id: checkIn.id },
        relations: ['place', 'user'],
    });

    return c.json(formatCheckIn(result!), 201);
});

// GET /checkins/activity/:activityId - Get all check-ins for activity's place
checkins.get('/activity/:activityId', async (c) => {
    const { userId } = getAuth(c);
    const activityId = c.req.param('activityId');

    const activityRepo = AppDataSource.getRepository(Activity);
    const activity = await activityRepo.findOne({ where: { id: activityId } });
    if (!activity) {
        return c.json({ error: 'Activity not found' }, 404);
    }

    // Verify membership
    const memberRepo = AppDataSource.getRepository(TravelMember);
    const member = await memberRepo.findOne({
        where: { travelId: activity.travelId, userId },
    });
    if (!member) {
        return c.json({ error: 'Not a member of this travel' }, 403);
    }

    if (!activity.placeId) {
        return c.json([]);
    }

    const checkInRepo = AppDataSource.getRepository(CheckIn);
    const checkIns = await checkInRepo.find({
        where: { placeId: activity.placeId },
        relations: ['user'],
        order: { createdAt: 'DESC' },
    });

    return c.json(checkIns.map((ci) => ({
        id: ci.id,
        placeId: ci.placeId,
        userId: ci.userId,
        activityId: ci.activityId,
        createdAt: ci.createdAt,
        user: {
            id: ci.user.id,
            name: ci.user.name,
            profilePhotoUrl: ci.user.profilePhotoUrl,
        },
    })));
});

// GET /checkins/me - Get all of current user's check-ins
checkins.get('/me', async (c) => {
    const { userId } = getAuth(c);
    const checkInRepo = AppDataSource.getRepository(CheckIn);

    const checkIns = await checkInRepo.find({
        where: { userId },
        relations: ['place'],
        order: { createdAt: 'DESC' },
    });

    return c.json(checkIns.map((ci) => ({
        id: ci.id,
        placeId: ci.placeId,
        userId: ci.userId,
        activityId: ci.activityId,
        createdAt: ci.createdAt,
        place: {
            id: ci.place.id,
            name: ci.place.name,
            latitude: ci.place.latitude,
            longitude: ci.place.longitude,
            address: ci.place.address,
        },
    })));
});

export default checkins;
