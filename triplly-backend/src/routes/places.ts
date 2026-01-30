import { Hono } from 'hono';
import { AppDataSource } from '../data-source.js';
import { Place, CheckIn, PlaceReview } from '../entities/index.js';
import { authMiddleware, getAuth } from '../middleware/index.js';
import { searchPlaces } from '../services/search.js';

const places = new Hono();

places.use('*', authMiddleware);

// GET /places/search?q=...&limit=... - Search places via Nominatim
places.get('/search', async (c) => {
    const query = c.req.query('q');
    if (!query) {
        return c.json({ error: 'Query parameter "q" is required' }, 400);
    }

    const limitParam = c.req.query('limit');
    const limit = limitParam ? parseInt(limitParam, 10) : undefined;

    try {
        const results = await searchPlaces(query, limit);
        return c.json(results);
    } catch (err) {
        console.error('Place search failed:', err);
        return c.json({ error: 'Search failed' }, 500);
    }
});

// GET /places/lookup?externalId=...&provider=... - Lookup place by external ID with check-ins and reviews
places.get('/lookup', async (c) => {
    const externalId = c.req.query('externalId');
    const provider = c.req.query('provider');

    if (!externalId || !provider) {
        return c.json({ error: 'Both "externalId" and "provider" query params are required' }, 400);
    }

    const placeRepo = AppDataSource.getRepository(Place);
    const checkInRepo = AppDataSource.getRepository(CheckIn);
    const reviewRepo = AppDataSource.getRepository(PlaceReview);

    const place = await placeRepo.findOne({ where: { externalId, provider } });
    if (!place) {
        return c.json({ place: null, checkIns: [], reviews: [] });
    }

    const [checkIns, reviews, avgResult] = await Promise.all([
        checkInRepo.find({
            where: { placeId: place.id },
            relations: ['user'],
            order: { createdAt: 'DESC' },
        }),
        reviewRepo.find({
            where: { placeId: place.id },
            relations: ['user'],
            order: { createdAt: 'DESC' },
        }),
        reviewRepo
            .createQueryBuilder('review')
            .select('AVG(review.rating)', 'avg')
            .where('review.placeId = :placeId', { placeId: place.id })
            .getRawOne(),
    ]);

    const checkInCount = checkIns.length;
    const averageRating = avgResult?.avg ? parseFloat(avgResult.avg) : null;

    return c.json({
        place: {
            id: place.id,
            name: place.name,
            latitude: Number(place.latitude),
            longitude: Number(place.longitude),
            address: place.address,
            externalId: place.externalId,
            provider: place.provider,
            createdAt: place.createdAt,
            checkInCount,
            averageRating,
        },
        checkIns: checkIns.map((ci) => ({
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
        })),
        reviews: reviews.map((r) => ({
            id: r.id,
            placeId: r.placeId,
            userId: r.userId,
            rating: r.rating,
            content: r.content,
            createdAt: r.createdAt,
            user: {
                id: r.user.id,
                name: r.user.name,
                profilePhotoUrl: r.user.profilePhotoUrl,
            },
        })),
    });
});

// GET /places/:placeId - Place details + stats
places.get('/:placeId', async (c) => {
    const placeId = c.req.param('placeId');
    const placeRepo = AppDataSource.getRepository(Place);
    const checkInRepo = AppDataSource.getRepository(CheckIn);
    const reviewRepo = AppDataSource.getRepository(PlaceReview);

    const place = await placeRepo.findOne({ where: { id: placeId } });
    if (!place) {
        return c.json({ error: 'Place not found' }, 404);
    }

    const checkInCount = await checkInRepo.count({ where: { placeId } });

    const avgResult = await reviewRepo
        .createQueryBuilder('review')
        .select('AVG(review.rating)', 'avg')
        .where('review.placeId = :placeId', { placeId })
        .getRawOne();

    const averageRating = avgResult?.avg ? parseFloat(avgResult.avg) : null;

    return c.json({
        id: place.id,
        name: place.name,
        latitude: Number(place.latitude),
        longitude: Number(place.longitude),
        address: place.address,
        externalId: place.externalId,
        provider: place.provider,
        createdAt: place.createdAt,
        checkInCount,
        averageRating,
    });
});

// GET /places/:placeId/checkins - All check-ins with user info
places.get('/:placeId/checkins', async (c) => {
    const placeId = c.req.param('placeId');
    const checkInRepo = AppDataSource.getRepository(CheckIn);

    const checkIns = await checkInRepo.find({
        where: { placeId },
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

// GET /places/:placeId/reviews - All reviews with user info
places.get('/:placeId/reviews', async (c) => {
    const placeId = c.req.param('placeId');
    const reviewRepo = AppDataSource.getRepository(PlaceReview);

    const reviews = await reviewRepo.find({
        where: { placeId },
        relations: ['user'],
        order: { createdAt: 'DESC' },
    });

    return c.json(reviews.map((r) => ({
        id: r.id,
        placeId: r.placeId,
        userId: r.userId,
        rating: r.rating,
        content: r.content,
        createdAt: r.createdAt,
        user: {
            id: r.user.id,
            name: r.user.name,
            profilePhotoUrl: r.user.profilePhotoUrl,
        },
    })));
});

export default places;
