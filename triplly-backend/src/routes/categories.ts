import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { IsNull } from 'typeorm';
import { AppDataSource } from '../data-source.js';
import { Category, TravelMember } from '../entities/index.js';
import { authMiddleware, getAuth } from '../middleware/index.js';

const categories = new Hono();

categories.use('*', authMiddleware);

const createCategorySchema = z.object({
    name: z.string().min(1).max(100),
    icon: z.string().min(1).max(50),
    color: z.string().regex(/^#[0-9A-Fa-f]{6}$/),
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

// GET /categories/travel/:travelId — Returns defaults + travel custom categories
categories.get('/travel/:travelId', async (c) => {
    const { userId } = getAuth(c);
    const travelId = c.req.param('travelId');

    const result = await checkTravelAccess(userId, travelId, 'viewer');
    if ('error' in result) {
        return c.json({ error: result.error }, result.status);
    }

    const categoryRepo = AppDataSource.getRepository(Category);

    // Get defaults (travelId IS NULL, isDefault = true)
    const defaults = await categoryRepo.find({
        where: { isDefault: true, travelId: IsNull() },
        order: { createdAt: 'ASC' },
    });

    // Get custom categories for this travel
    const customs = await categoryRepo.find({
        where: { travelId, isDefault: false },
        order: { createdAt: 'ASC' },
    });

    return c.json([...defaults, ...customs]);
});

// POST /categories/travel/:travelId — Create custom category for a travel
categories.post('/travel/:travelId', zValidator('json', createCategorySchema), async (c) => {
    const { userId } = getAuth(c);
    const travelId = c.req.param('travelId');
    const data = c.req.valid('json');

    const result = await checkTravelAccess(userId, travelId, 'editor');
    if ('error' in result) {
        return c.json({ error: result.error }, result.status);
    }

    const categoryRepo = AppDataSource.getRepository(Category);

    // Check for duplicate name within travel (including defaults with null travelId)
    const existingInTravel = await categoryRepo.findOne({
        where: { travelId, name: data.name },
    });
    if (existingInTravel) {
        return c.json({ error: 'A category with this name already exists for this travel' }, 409);
    }

    const category = categoryRepo.create({
        name: data.name,
        icon: data.icon,
        color: data.color,
        isDefault: false,
        travelId,
        createdById: userId,
    });

    await categoryRepo.save(category);
    return c.json(category, 201);
});

// DELETE /categories/:categoryId — Delete a custom category
categories.delete('/:categoryId', async (c) => {
    const { userId } = getAuth(c);
    const categoryId = c.req.param('categoryId');

    const categoryRepo = AppDataSource.getRepository(Category);
    const category = await categoryRepo.findOne({ where: { id: categoryId } });

    if (!category) {
        return c.json({ error: 'Category not found' }, 404);
    }

    if (category.isDefault) {
        return c.json({ error: 'Cannot delete default categories' }, 400);
    }

    if (!category.travelId) {
        return c.json({ error: 'Cannot delete global categories' }, 400);
    }

    // Check travel access
    const result = await checkTravelAccess(userId, category.travelId, 'editor');
    if ('error' in result) {
        return c.json({ error: result.error }, result.status);
    }

    await categoryRepo.delete({ id: categoryId });
    return c.json({ success: true });
});

export default categories;
