import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { AppDataSource } from '../data-source.js';
import { PlaceReview, CheckIn } from '../entities/index.js';
import { authMiddleware, getAuth } from '../middleware/index.js';

const reviews = new Hono();

reviews.use('*', authMiddleware);

const createReviewSchema = z.object({
    placeId: z.string().uuid(),
    rating: z.number().int().min(1).max(5),
    content: z.string().min(1),
});

// POST /reviews - Create review (requires check-in at place)
reviews.post('/', zValidator('json', createReviewSchema), async (c) => {
    const { userId } = getAuth(c);
    const { placeId, rating, content } = c.req.valid('json');

    const checkInRepo = AppDataSource.getRepository(CheckIn);
    const reviewRepo = AppDataSource.getRepository(PlaceReview);

    // Verify user has checked in at this place
    const checkIn = await checkInRepo.findOne({
        where: { placeId, userId },
    });
    if (!checkIn) {
        return c.json({ error: 'You must check in at this place before writing a review' }, 403);
    }

    // Check for existing review
    const existing = await reviewRepo.findOne({
        where: { placeId, userId },
    });
    if (existing) {
        return c.json({ error: 'You have already reviewed this place' }, 400);
    }

    const review = reviewRepo.create({
        placeId,
        userId,
        rating,
        content,
    });
    await reviewRepo.save(review);

    // Return with user info
    const result = await reviewRepo.findOne({
        where: { id: review.id },
        relations: ['user'],
    });

    return c.json({
        id: result!.id,
        placeId: result!.placeId,
        userId: result!.userId,
        rating: result!.rating,
        content: result!.content,
        createdAt: result!.createdAt,
        user: {
            id: result!.user.id,
            name: result!.user.name,
            profilePhotoUrl: result!.user.profilePhotoUrl,
        },
    }, 201);
});

// DELETE /reviews/:reviewId - Delete own review
reviews.delete('/:reviewId', async (c) => {
    const { userId } = getAuth(c);
    const reviewId = c.req.param('reviewId');

    const reviewRepo = AppDataSource.getRepository(PlaceReview);
    const review = await reviewRepo.findOne({
        where: { id: reviewId },
    });

    if (!review) {
        return c.json({ error: 'Review not found' }, 404);
    }

    if (review.userId !== userId) {
        return c.json({ error: 'You can only delete your own reviews' }, 403);
    }

    await reviewRepo.delete({ id: reviewId });
    return c.json({ success: true });
});

export default reviews;
