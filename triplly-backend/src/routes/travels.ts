import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { AppDataSource } from '../data-source.js';
import { Travel, TravelMember, MemberRole, User } from '../entities/index.js';
import { authMiddleware, getAuth, requireTravelAccess } from '../middleware/index.js';

const travels = new Hono();

// All routes require authentication
travels.use('*', authMiddleware);

const createTravelSchema = z.object({
    title: z.string().min(1),
    description: z.string().nullable().optional(),
    startDate: z.string().nullable().optional(),
    endDate: z.string().nullable().optional(),
    coverImageUrl: z.string().url().nullable().optional(),
});

const updateTravelSchema = createTravelSchema.partial();

// GET /travels - List user's travels
travels.get('/', async (c) => {
    const { userId } = getAuth(c);
    const memberRepo = AppDataSource.getRepository(TravelMember);

    const memberships = await memberRepo.find({
        where: { userId },
        relations: ['travel', 'travel.owner'],
        order: { travel: { createdAt: 'DESC' } },
    });

    const travelList = memberships.map((m) => ({
        id: m.travel.id,
        title: m.travel.title,
        description: m.travel.description,
        startDate: m.travel.startDate,
        endDate: m.travel.endDate,
        coverImageUrl: m.travel.coverImageUrl,
        role: m.role,
        owner: {
            id: m.travel.owner.id,
            name: m.travel.owner.name,
        },
        createdAt: m.travel.createdAt,
    }));

    return c.json(travelList);
});

// POST /travels - Create travel
travels.post('/', zValidator('json', createTravelSchema), async (c) => {
    const { userId } = getAuth(c);
    const data = c.req.valid('json');
    const travelRepo = AppDataSource.getRepository(Travel);
    const memberRepo = AppDataSource.getRepository(TravelMember);

    // Create travel
    const travel = travelRepo.create({
        ...data,
        startDate: data.startDate ? new Date(data.startDate) : null,
        endDate: data.endDate ? new Date(data.endDate) : null,
        ownerId: userId,
    });
    await travelRepo.save(travel);

    // Add creator as owner member
    const member = memberRepo.create({
        travelId: travel.id,
        userId,
        role: MemberRole.OWNER,
    });
    await memberRepo.save(member);

    return c.json(travel, 201);
});

// GET /travels/:travelId - Get travel details
travels.get('/:travelId', requireTravelAccess('viewer'), async (c) => {
    const travelId = c.req.param('travelId');
    const travelRepo = AppDataSource.getRepository(Travel);

    const travel = await travelRepo.findOne({
        where: { id: travelId },
        relations: ['owner', 'itineraries', 'itineraries.activities'],
    });

    if (!travel) {
        return c.json({ error: 'Travel not found' }, 404);
    }

    // Sort itineraries and activities by orderIndex
    travel.itineraries.sort((a, b) => a.orderIndex - b.orderIndex);
    travel.itineraries.forEach((it) => {
        it.activities.sort((a, b) => a.orderIndex - b.orderIndex);
    });

    return c.json({
        ...travel,
        owner: { id: travel.owner.id, name: travel.owner.name, email: travel.owner.email },
    });
});

// PATCH /travels/:travelId - Update travel
travels.patch('/:travelId', requireTravelAccess('editor'), zValidator('json', updateTravelSchema), async (c) => {
    const travelId = c.req.param('travelId');
    const data = c.req.valid('json');
    const travelRepo = AppDataSource.getRepository(Travel);

    const travel = await travelRepo.findOne({ where: { id: travelId } });
    if (!travel) {
        return c.json({ error: 'Travel not found' }, 404);
    }

    // Update fields
    if (data.title !== undefined) travel.title = data.title;
    if (data.description !== undefined) travel.description = data.description;
    if (data.startDate !== undefined) travel.startDate = data.startDate ? new Date(data.startDate) : null;
    if (data.endDate !== undefined) travel.endDate = data.endDate ? new Date(data.endDate) : null;
    if (data.coverImageUrl !== undefined) travel.coverImageUrl = data.coverImageUrl;

    await travelRepo.save(travel);
    return c.json(travel);
});

// DELETE /travels/:travelId - Delete travel (owner only)
travels.delete('/:travelId', requireTravelAccess('owner'), async (c) => {
    const travelId = c.req.param('travelId');
    const travelRepo = AppDataSource.getRepository(Travel);

    await travelRepo.delete({ id: travelId });
    return c.json({ success: true });
});

// --- Member Management ---

const inviteSchema = z.object({
    email: z.string().email(),
    role: z.enum(['editor', 'viewer']).default('viewer'),
});

const updateRoleSchema = z.object({
    role: z.enum(['editor', 'viewer']),
});

// GET /travels/:travelId/members
travels.get('/:travelId/members', requireTravelAccess('viewer'), async (c) => {
    const travelId = c.req.param('travelId');
    const memberRepo = AppDataSource.getRepository(TravelMember);

    const members = await memberRepo.find({
        where: { travelId },
        relations: ['user'],
        order: { joinedAt: 'ASC' },
    });

    return c.json(
        members.map((m) => ({
            id: m.id,
            userId: m.userId,
            role: m.role,
            joinedAt: m.joinedAt,
            user: {
                id: m.user.id,
                name: m.user.name,
                email: m.user.email,
                profilePhotoUrl: m.user.profilePhotoUrl,
            },
        }))
    );
});

// POST /travels/:travelId/members - Invite member
travels.post('/:travelId/members', requireTravelAccess('owner'), zValidator('json', inviteSchema), async (c) => {
    const travelId = c.req.param('travelId');
    const { email, role } = c.req.valid('json');
    const userRepo = AppDataSource.getRepository(User);
    const memberRepo = AppDataSource.getRepository(TravelMember);

    // Find user by email
    const user = await userRepo.findOne({ where: { email } });
    if (!user) {
        return c.json({ error: 'User not found' }, 404);
    }

    // Check if already member
    const existing = await memberRepo.findOne({
        where: { travelId, userId: user.id },
    });
    if (existing) {
        return c.json({ error: 'User is already a member' }, 400);
    }

    // Create membership
    const member = memberRepo.create({
        travelId,
        userId: user.id,
        role: role === 'editor' ? MemberRole.EDITOR : MemberRole.VIEWER,
    });
    await memberRepo.save(member);

    return c.json({
        id: member.id,
        userId: member.userId,
        role: member.role,
        joinedAt: member.joinedAt,
        user: { id: user.id, name: user.name, email: user.email },
    }, 201);
});

// PATCH /travels/:travelId/members/:memberId - Update role
travels.patch('/:travelId/members/:memberId', requireTravelAccess('owner'), zValidator('json', updateRoleSchema), async (c) => {
    const memberId = c.req.param('memberId');
    const { role } = c.req.valid('json');
    const memberRepo = AppDataSource.getRepository(TravelMember);

    const member = await memberRepo.findOne({ where: { id: memberId } });
    if (!member) {
        return c.json({ error: 'Member not found' }, 404);
    }

    // Can't change owner's role
    if (member.role === MemberRole.OWNER) {
        return c.json({ error: 'Cannot change owner role' }, 400);
    }

    member.role = role === 'editor' ? MemberRole.EDITOR : MemberRole.VIEWER;
    await memberRepo.save(member);

    return c.json({ id: member.id, role: member.role });
});

// DELETE /travels/:travelId/members/:memberId - Remove member
travels.delete('/:travelId/members/:memberId', requireTravelAccess('owner'), async (c) => {
    const memberId = c.req.param('memberId');
    const memberRepo = AppDataSource.getRepository(TravelMember);

    const member = await memberRepo.findOne({ where: { id: memberId } });
    if (!member) {
        return c.json({ error: 'Member not found' }, 404);
    }

    // Can't remove owner
    if (member.role === MemberRole.OWNER) {
        return c.json({ error: 'Cannot remove owner' }, 400);
    }

    await memberRepo.delete({ id: memberId });
    return c.json({ success: true });
});

export default travels;
