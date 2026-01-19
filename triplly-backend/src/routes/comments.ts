import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { AppDataSource } from '../data-source.js';
import { Activity, ActivityComment, TravelMember } from '../entities/index.js';
import { authMiddleware, getAuth } from '../middleware/index.js';

const comments = new Hono();

comments.use('*', authMiddleware);

const createCommentSchema = z.object({
    content: z.string().min(1),
});

// Helper to check read access (viewer+)
// Helper to check read access (viewer+)
async function checkCommentReadAccess(userId: string, activityId: string) {
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

    return { activity };
}

// GET /comments/activity/:activityId - List comments for an activity
comments.get('/activity/:activityId', async (c) => {
    const { userId } = getAuth(c);
    const activityId = c.req.param('activityId');

    const result = await checkCommentReadAccess(userId, activityId);
    if ('error' in result) {
        return c.json({ error: result.error }, result.status);
    }

    const commentRepo = AppDataSource.getRepository(ActivityComment);
    const comments = await commentRepo.find({
        where: { activityId },
        order: { createdAt: 'ASC' },
        relations: ['user'],
    });

    return c.json(comments);
});

// POST /comments/activity/:activityId - Add a comment
comments.post('/activity/:activityId', zValidator('json', createCommentSchema), async (c) => {
    const { userId } = getAuth(c);
    const activityId = c.req.param('activityId');
    const { content } = c.req.valid('json');

    // Reuse read access check (members can comment)
    const result = await checkCommentReadAccess(userId, activityId);
    if ('error' in result) {
        return c.json({ error: result.error }, result.status);
    }

    const commentRepo = AppDataSource.getRepository(ActivityComment);
    const comment = commentRepo.create({
        activityId,
        userId,
        content,
    });
    await commentRepo.save(comment);

    // Fetch again to include user relation
    const savedComment = await commentRepo.findOne({
        where: { id: comment.id },
        relations: ['user'],
    });

    return c.json(savedComment, 201);
});

// DELETE /comments/:commentId
comments.delete('/:commentId', async (c) => {
    const { userId } = getAuth(c);
    const commentId = c.req.param('commentId');

    const commentRepo = AppDataSource.getRepository(ActivityComment);
    const comment = await commentRepo.findOne({ where: { id: commentId } });

    if (!comment) {
        return c.json({ error: 'Comment not found' }, 404);
    }

    if (comment.userId !== userId) {
        return c.json({ error: 'Cannot delete others comments' }, 403);
    }

    await commentRepo.delete({ id: commentId });
    return c.json({ success: true });
});

export default comments;
