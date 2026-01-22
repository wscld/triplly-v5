import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { AppDataSource } from '../data-source.js';
import { Itinerary, TravelMember } from '../entities/index.js';
import { authMiddleware, getAuth, requireTravelAccess } from '../middleware/index.js';
const itineraries = new Hono();
// All routes require authentication
itineraries.use('*', authMiddleware);
const createItinerarySchema = z.object({
    travelId: z.string().uuid(),
    title: z.string().min(1),
    date: z.string().nullable().optional(),
});
const updateItinerarySchema = z.object({
    title: z.string().min(1).optional(),
    date: z.string().nullable().optional(),
});
// Helper to check travel access for itinerary operations
async function checkItineraryAccess(userId, itineraryId, minRole) {
    const itineraryRepo = AppDataSource.getRepository(Itinerary);
    const memberRepo = AppDataSource.getRepository(TravelMember);
    const itinerary = await itineraryRepo.findOne({
        where: { id: itineraryId },
    });
    if (!itinerary) {
        return { error: 'Itinerary not found', status: 404 };
    }
    const member = await memberRepo.findOne({
        where: { travelId: itinerary.travelId, userId },
    });
    if (!member) {
        return { error: 'Not a member of this travel', status: 403 };
    }
    const roleLevel = { viewer: 1, editor: 2, owner: 3 };
    if (roleLevel[member.role] < roleLevel[minRole]) {
        return { error: 'Insufficient permissions', status: 403 };
    }
    return { itinerary, member };
}
// POST /itineraries - Create itinerary
itineraries.post('/', zValidator('json', createItinerarySchema), async (c) => {
    const { userId } = getAuth(c);
    const { travelId, title, date } = c.req.valid('json');
    const memberRepo = AppDataSource.getRepository(TravelMember);
    const itineraryRepo = AppDataSource.getRepository(Itinerary);
    // Check access
    const member = await memberRepo.findOne({ where: { travelId, userId } });
    if (!member) {
        return c.json({ error: 'Not a member of this travel' }, 403);
    }
    if (member.role === 'viewer') {
        return c.json({ error: 'Insufficient permissions' }, 403);
    }
    // Get max orderIndex
    const lastItinerary = await itineraryRepo.findOne({
        where: { travelId },
        order: { orderIndex: 'DESC' },
    });
    const nextOrder = (lastItinerary?.orderIndex ?? 0) + 1000;
    const itinerary = itineraryRepo.create({
        travelId,
        title,
        date: date ? new Date(date) : null,
        orderIndex: nextOrder,
    });
    await itineraryRepo.save(itinerary);
    return c.json(itinerary, 201);
});
// GET /itineraries/:itineraryId - Get itinerary with activities
itineraries.get('/:itineraryId', async (c) => {
    const { userId } = getAuth(c);
    const itineraryId = c.req.param('itineraryId');
    const result = await checkItineraryAccess(userId, itineraryId, 'viewer');
    if ('error' in result) {
        return c.json({ error: result.error }, result.status);
    }
    const itineraryRepo = AppDataSource.getRepository(Itinerary);
    const itinerary = await itineraryRepo.findOne({
        where: { id: itineraryId },
        relations: ['activities'],
    });
    if (!itinerary) {
        return c.json({ error: 'Itinerary not found' }, 404);
    }
    // Sort activities by orderIndex
    itinerary.activities.sort((a, b) => a.orderIndex - b.orderIndex);
    return c.json(itinerary);
});
// PATCH /itineraries/:itineraryId - Update itinerary
itineraries.patch('/:itineraryId', zValidator('json', updateItinerarySchema), async (c) => {
    const { userId } = getAuth(c);
    const itineraryId = c.req.param('itineraryId');
    const data = c.req.valid('json');
    const result = await checkItineraryAccess(userId, itineraryId, 'editor');
    if ('error' in result) {
        return c.json({ error: result.error }, result.status);
    }
    const itineraryRepo = AppDataSource.getRepository(Itinerary);
    const { itinerary } = result;
    if (data.title !== undefined)
        itinerary.title = data.title;
    if (data.date !== undefined)
        itinerary.date = data.date ? new Date(data.date) : null;
    await itineraryRepo.save(itinerary);
    return c.json(itinerary);
});
// DELETE /itineraries/:itineraryId
itineraries.delete('/:itineraryId', async (c) => {
    const { userId } = getAuth(c);
    const itineraryId = c.req.param('itineraryId');
    const result = await checkItineraryAccess(userId, itineraryId, 'editor');
    if ('error' in result) {
        return c.json({ error: result.error }, result.status);
    }
    const itineraryRepo = AppDataSource.getRepository(Itinerary);
    await itineraryRepo.delete({ id: itineraryId });
    return c.json({ success: true });
});
export default itineraries;
