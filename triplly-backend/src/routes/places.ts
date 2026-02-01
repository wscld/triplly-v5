import { Hono } from 'hono';
import { AppDataSource } from '../data-source.js';
import { Place, CheckIn, PlaceReview, Category } from '../entities/index.js';
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

// GET /places/lookup - Lookup place by external ID or name+coords, with check-ins and reviews
places.get('/lookup', async (c) => {
    const externalId = c.req.query('externalId');
    const provider = c.req.query('provider');
    const name = c.req.query('name');
    const lat = c.req.query('latitude');
    const lng = c.req.query('longitude');

    const placeRepo = AppDataSource.getRepository(Place);
    const checkInRepo = AppDataSource.getRepository(CheckIn);
    const reviewRepo = AppDataSource.getRepository(PlaceReview);

    // Strategy 1: exact match on externalId + provider
    let place = null;
    if (externalId && provider) {
        place = await placeRepo.findOne({ where: { externalId, provider } });
    }

    // Strategy 2: name + lat/lng proximity (~100m = ~0.001 degrees)
    if (!place && name && lat && lng) {
        const proximity = 0.001;
        place = await placeRepo
            .createQueryBuilder('place')
            .where('place.name = :name', { name })
            .andWhere('ABS(place.latitude - :lat) < :proximity', { lat: parseFloat(lat), proximity })
            .andWhere('ABS(place.longitude - :lng) < :proximity', { lng: parseFloat(lng), proximity })
            .getOne();
    }

    if (!place) {
        return c.json({ place: null, checkIns: [], reviews: [] });
    }

    const limit = parseInt(c.req.query('limit') || '5', 10);

    const [checkIns, reviews, checkInCount, reviewCount, avgResult] = await Promise.all([
        checkInRepo.find({
            where: { placeId: place.id },
            relations: ['user'],
            order: { createdAt: 'DESC' },
            take: limit,
        }),
        reviewRepo.find({
            where: { placeId: place.id },
            relations: ['user'],
            order: { createdAt: 'DESC' },
            take: limit,
        }),
        checkInRepo.count({ where: { placeId: place.id } }),
        reviewRepo.count({ where: { placeId: place.id } }),
        reviewRepo
            .createQueryBuilder('review')
            .select('AVG(review.rating)', 'avg')
            .where('review.placeId = :placeId', { placeId: place.id })
            .getRawOne(),
    ]);
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
                username: ci.user.username,
                profilePhotoUrl: ci.user.profilePhotoUrl,
            },
        })),
        totalCheckIns: checkInCount,
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
                username: r.user.username,
                profilePhotoUrl: r.user.profilePhotoUrl,
            },
        })),
        totalReviews: reviewCount,
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

    // Look up category info if place has a category name
    let categoryInfo = null;
    if (place.category) {
        const categoryRepo = AppDataSource.getRepository(Category);
        const cat = await categoryRepo.findOne({
            where: { name: place.category, isDefault: true },
        });
        if (cat) {
            categoryInfo = {
                id: cat.id,
                name: cat.name,
                icon: cat.icon,
                color: cat.color,
                isDefault: cat.isDefault,
                travelId: cat.travelId,
            };
        }
    }

    return c.json({
        id: place.id,
        name: place.name,
        latitude: Number(place.latitude),
        longitude: Number(place.longitude),
        address: place.address,
        externalId: place.externalId,
        provider: place.provider,
        category: place.category,
        categoryInfo,
        createdAt: place.createdAt,
        checkInCount,
        averageRating,
    });
});

// GET /places/:placeId/checkins - Check-ins with pagination
places.get('/:placeId/checkins', async (c) => {
    const placeId = c.req.param('placeId');
    const limit = parseInt(c.req.query('limit') || '20', 10);
    const offset = parseInt(c.req.query('offset') || '0', 10);
    const checkInRepo = AppDataSource.getRepository(CheckIn);

    const [checkIns, total] = await checkInRepo.findAndCount({
        where: { placeId },
        relations: ['user'],
        order: { createdAt: 'DESC' },
        take: limit,
        skip: offset,
    });

    return c.json({
        data: checkIns.map((ci) => ({
            id: ci.id,
            placeId: ci.placeId,
            userId: ci.userId,
            activityId: ci.activityId,
            createdAt: ci.createdAt,
            user: {
                id: ci.user.id,
                name: ci.user.name,
                username: ci.user.username,
                profilePhotoUrl: ci.user.profilePhotoUrl,
            },
        })),
        total,
        limit,
        offset,
    });
});

// GET /places/:placeId/reviews - Reviews with pagination
places.get('/:placeId/reviews', async (c) => {
    const placeId = c.req.param('placeId');
    const limit = parseInt(c.req.query('limit') || '20', 10);
    const offset = parseInt(c.req.query('offset') || '0', 10);
    const reviewRepo = AppDataSource.getRepository(PlaceReview);

    const [reviews, total] = await reviewRepo.findAndCount({
        where: { placeId },
        relations: ['user'],
        order: { createdAt: 'DESC' },
        take: limit,
        skip: offset,
    });

    return c.json({
        data: reviews.map((r) => ({
            id: r.id,
            placeId: r.placeId,
            userId: r.userId,
            rating: r.rating,
            content: r.content,
            createdAt: r.createdAt,
            user: {
                id: r.user.id,
                name: r.user.name,
                username: r.user.username,
                profilePhotoUrl: r.user.profilePhotoUrl,
            },
        })),
        total,
        limit,
        offset,
    });
});

export default places;
