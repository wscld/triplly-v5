import { Hono } from 'hono';
import { AppDataSource } from '../data-source.js';
import { Place, CheckIn, PlaceReview } from '../entities/index.js';
import { authMiddleware, getAuth } from '../middleware/index.js';

const places = new Hono();

places.use('*', authMiddleware);

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
