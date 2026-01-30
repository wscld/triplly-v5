import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { AppDataSource } from '../data-source.js';
import { Activity, Itinerary, TravelMember } from '../entities/index.js';
import { authMiddleware, getAuth } from '../middleware/index.js';
import { findOrCreatePlace } from '../services/places.js';

const activities = new Hono();

// All routes require authentication
activities.use('*', authMiddleware);

const createActivitySchema = z.object({
    travelId: z.string().uuid(),
    itineraryId: z.string().uuid().nullable().optional(), // null = wishlist
    title: z.string().min(1),
    description: z.string().nullable().optional(),
    latitude: z.number(),
    longitude: z.number(),
    googlePlaceId: z.string().nullable().optional(),
    address: z.string().nullable().optional(),
    startTime: z.string().nullable().optional(),
    externalPlaceId: z.string().nullable().optional(),
    placeProvider: z.string().nullable().optional(),
});

const updateActivitySchema = z.object({
    title: z.string().min(1).optional(),
    description: z.string().nullable().optional(),
    latitude: z.number().optional(),
    longitude: z.number().optional(),
    googlePlaceId: z.string().nullable().optional(),
});

const reorderSchema = z.object({
    activityId: z.string().uuid(),
    afterActivityId: z.string().uuid().nullable(),
    beforeActivityId: z.string().uuid().nullable(),
});

const assignSchema = z.object({
    itineraryId: z.string().uuid().nullable(), // null = move back to wishlist
});

// Helper to check travel access
async function checkTravelAccess(userId: string, travelId: string, minRole: 'viewer' | 'editor') {
    const memberRepo = AppDataSource.getRepository(TravelMember);
    const member = await memberRepo.findOne({ where: { travelId, userId } });

    if (!member) {
        return { error: 'Not a member of this travel', status: 403 as const };
    }

    const roleLevel = { viewer: 1, editor: 2, owner: 3 };
    if (roleLevel[member.role] < roleLevel[minRole]) {
        return { error: 'Insufficient permissions', status: 403 as const };
    }

    return { member, travelId };
}

// Helper to check access via activity -> travel
async function checkActivityAccess(userId: string, activityId: string, minRole: 'viewer' | 'editor') {
    const activityRepo = AppDataSource.getRepository(Activity);
    const memberRepo = AppDataSource.getRepository(TravelMember);

    const activity = await activityRepo.findOne({ where: { id: activityId } });
    if (!activity) {
        return { error: 'Activity not found', status: 404 as const };
    }

    const member = await memberRepo.findOne({
        where: { travelId: activity.travelId, userId },
    });

    if (!member) {
        return { error: 'Not a member of this travel', status: 403 as const };
    }

    const roleLevel = { viewer: 1, editor: 2, owner: 3 };
    if (roleLevel[member.role] < roleLevel[minRole]) {
        return { error: 'Insufficient permissions', status: 403 as const };
    }

    return { activity, member };
}

// Helper to check access via itinerary
async function checkItineraryAccess(userId: string, itineraryId: string, minRole: 'viewer' | 'editor') {
    const itineraryRepo = AppDataSource.getRepository(Itinerary);
    const memberRepo = AppDataSource.getRepository(TravelMember);

    const itinerary = await itineraryRepo.findOne({ where: { id: itineraryId } });
    if (!itinerary) {
        return { error: 'Itinerary not found', status: 404 as const };
    }

    const member = await memberRepo.findOne({
        where: { travelId: itinerary.travelId, userId },
    });

    if (!member) {
        return { error: 'Not a member of this travel', status: 403 as const };
    }

    const roleLevel = { viewer: 1, editor: 2, owner: 3 };
    if (roleLevel[member.role] < roleLevel[minRole]) {
        return { error: 'Insufficient permissions', status: 403 as const };
    }

    return { itinerary, member };
}

function calculateNewIndex(before: number | null, after: number | null): number {
    if (before === null && after === null) return 1000;
    if (before === null) return after! / 2;
    if (after === null) return before + 1000;
    return (before + after) / 2;
}

// GET /activities/travel/:travelId/wishlist - Get wishlist activities for a travel
activities.get('/travel/:travelId/wishlist', async (c) => {
    const { userId } = getAuth(c);
    const travelId = c.req.param('travelId');

    const result = await checkTravelAccess(userId, travelId, 'viewer');
    if ('error' in result) {
        return c.json({ error: result.error }, result.status);
    }

    const activityRepo = AppDataSource.getRepository(Activity);
    const wishlistActivities = await activityRepo
        .createQueryBuilder('activity')
        .where('activity.travelId = :travelId', { travelId })
        .andWhere('activity.itineraryId IS NULL')
        .orderBy('activity.orderIndex', 'ASC')
        .getMany();

    return c.json(wishlistActivities);
});

// PATCH /activities/reorder - Reorder activity within an itinerary or wishlist
activities.patch('/reorder', zValidator('json', reorderSchema), async (c) => {
    const { userId } = getAuth(c);
    const { activityId, afterActivityId, beforeActivityId } = c.req.valid('json');

    const result = await checkActivityAccess(userId, activityId, 'editor');
    if ('error' in result) {
        return c.json({ error: result.error }, result.status);
    }

    const activityRepo = AppDataSource.getRepository(Activity);
    const { activity } = result;

    // For wishlist activities, check by travelId and null itineraryId
    // For itinerary activities, check by itineraryId
    const isWishlist = !activity.itineraryId;

    let afterIndex: number | null = null;
    let beforeIndex: number | null = null;

    if (afterActivityId) {
        const whereClause = isWishlist
            ? { id: afterActivityId, travelId: activity.travelId }
            : { id: afterActivityId, itineraryId: activity.itineraryId! };
        const afterActivity = await activityRepo.findOne({ where: whereClause });
        if (!afterActivity) {
            return c.json({ error: 'After activity not found' }, 404);
        }
        // For wishlist, ensure it's also a wishlist activity
        if (isWishlist && afterActivity.itineraryId) {
            return c.json({ error: 'After activity is not in wishlist' }, 400);
        }
        afterIndex = afterActivity.orderIndex;
    }

    if (beforeActivityId) {
        const whereClause = isWishlist
            ? { id: beforeActivityId, travelId: activity.travelId }
            : { id: beforeActivityId, itineraryId: activity.itineraryId! };
        const beforeActivity = await activityRepo.findOne({ where: whereClause });
        if (!beforeActivity) {
            return c.json({ error: 'Before activity not found' }, 404);
        }
        // For wishlist, ensure it's also a wishlist activity
        if (isWishlist && beforeActivity.itineraryId) {
            return c.json({ error: 'Before activity is not in wishlist' }, 400);
        }
        beforeIndex = beforeActivity.orderIndex;
    }

    activity.orderIndex = calculateNewIndex(afterIndex, beforeIndex);
    await activityRepo.save(activity);

    return c.json(activity);
});

// POST /activities - Create activity (can be wishlist or assigned to itinerary)
activities.post('/', zValidator('json', createActivitySchema), async (c) => {
    const { userId } = getAuth(c);
    const data = c.req.valid('json');

    // Check travel access
    const result = await checkTravelAccess(userId, data.travelId, 'editor');
    if ('error' in result) {
        return c.json({ error: result.error }, result.status);
    }

    // If assigning to itinerary, verify it belongs to same travel
    if (data.itineraryId) {
        const itineraryRepo = AppDataSource.getRepository(Itinerary);
        const itinerary = await itineraryRepo.findOne({ where: { id: data.itineraryId } });
        if (!itinerary || itinerary.travelId !== data.travelId) {
            return c.json({ error: 'Itinerary not found or does not belong to this travel' }, 400);
        }
    }

    const activityRepo = AppDataSource.getRepository(Activity);

    // Auto-create/link Place
    let placeId: string | null = null;
    try {
        const place = await findOrCreatePlace({
            name: data.title,
            latitude: data.latitude,
            longitude: data.longitude,
            address: data.address,
            externalId: data.externalPlaceId ?? data.googlePlaceId ?? null,
            provider: data.placeProvider ?? (data.googlePlaceId ? 'google' : null),
        });
        placeId = place.id;
    } catch (err) {
        console.error('Failed to create/find place:', err);
    }

    // Get max orderIndex
    let nextOrder = 1000;
    if (data.itineraryId) {
        const lastActivity = await activityRepo.findOne({
            where: { itineraryId: data.itineraryId },
            order: { orderIndex: 'DESC' },
        });
        nextOrder = (lastActivity?.orderIndex ?? 0) + 1000;
    }

    const activity = activityRepo.create({
        ...data,
        itineraryId: data.itineraryId || null,
        orderIndex: nextOrder,
        createdById: userId,
        placeId,
    });
    await activityRepo.save(activity);

    return c.json(activity, 201);
});

// GET /activities/:activityId
activities.get('/:activityId', async (c) => {
    const { userId } = getAuth(c);
    const activityId = c.req.param('activityId');

    const result = await checkActivityAccess(userId, activityId, 'viewer');
    if ('error' in result) {
        return c.json({ error: result.error }, result.status);
    }

    // Fetch the activity with createdBy relation
    const activityRepo = AppDataSource.getRepository(Activity);
    const activityWithCreator = await activityRepo.findOne({
        where: { id: activityId },
        relations: ['createdBy'],
        select: {
            id: true,
            travelId: true,
            itineraryId: true,
            title: true,
            description: true,
            orderIndex: true,
            latitude: true,
            longitude: true,
            googlePlaceId: true,
            placeId: true,
            address: true,
            startTime: true,
            createdAt: true,
            createdById: true,
            createdBy: {
                id: true,
                name: true,
                email: true,
                username: true,
                profilePhotoUrl: true,
            },
        },
    });

    return c.json(activityWithCreator);
});

// PATCH /activities/:activityId/assign - Assign activity to itinerary or move to wishlist
activities.patch('/:activityId/assign', zValidator('json', assignSchema), async (c) => {
    const { userId } = getAuth(c);
    const activityId = c.req.param('activityId');
    const { itineraryId } = c.req.valid('json');

    const result = await checkActivityAccess(userId, activityId, 'editor');
    if ('error' in result) {
        return c.json({ error: result.error }, result.status);
    }

    const { activity } = result;
    const activityRepo = AppDataSource.getRepository(Activity);

    if (itineraryId) {
        // Verify itinerary belongs to same travel
        const itineraryRepo = AppDataSource.getRepository(Itinerary);
        const itinerary = await itineraryRepo.findOne({ where: { id: itineraryId } });
        if (!itinerary || itinerary.travelId !== activity.travelId) {
            return c.json({ error: 'Itinerary not found or does not belong to this travel' }, 400);
        }

        // Get next orderIndex for target itinerary
        const lastActivity = await activityRepo.findOne({
            where: { itineraryId },
            order: { orderIndex: 'DESC' },
        });
        activity.orderIndex = (lastActivity?.orderIndex ?? 0) + 1000;
        activity.itineraryId = itineraryId;
    } else {
        // Move to wishlist
        activity.itineraryId = null;
        activity.orderIndex = 0;
    }

    await activityRepo.save(activity);
    return c.json(activity);
});

// PATCH /activities/:activityId - Update activity
activities.patch('/:activityId', zValidator('json', updateActivitySchema), async (c) => {
    const { userId } = getAuth(c);
    const activityId = c.req.param('activityId');
    const data = c.req.valid('json');

    const result = await checkActivityAccess(userId, activityId, 'editor');
    if ('error' in result) {
        return c.json({ error: result.error }, result.status);
    }

    const activityRepo = AppDataSource.getRepository(Activity);
    const { activity } = result;

    if (data.title !== undefined) activity.title = data.title;
    if (data.description !== undefined) activity.description = data.description;
    if (data.latitude !== undefined) activity.latitude = data.latitude;
    if (data.longitude !== undefined) activity.longitude = data.longitude;
    if (data.googlePlaceId !== undefined) activity.googlePlaceId = data.googlePlaceId;

    await activityRepo.save(activity);
    return c.json(activity);
});

// DELETE /activities/:activityId
activities.delete('/:activityId', async (c) => {
    const { userId } = getAuth(c);
    const activityId = c.req.param('activityId');

    const result = await checkActivityAccess(userId, activityId, 'editor');
    if ('error' in result) {
        return c.json({ error: result.error }, result.status);
    }

    const activityRepo = AppDataSource.getRepository(Activity);
    await activityRepo.delete({ id: activityId });

    return c.json({ success: true });
});

export default activities;
