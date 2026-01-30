import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { AppDataSource } from '../data-source.js';
import { Travel, TravelMember, MemberRole, TravelInvite, InviteStatus, User } from '../entities/index.js';
import { authMiddleware, getAuth, requireTravelAccess } from '../middleware/index.js';
import { getPlaceImage } from '../services/unsplash.js';
import { uploadImage } from '../services/storage.js';
import { findOrCreatePlace } from '../services/places.js';

const travels = new Hono();

// All routes require authentication
travels.use('*', authMiddleware);

const createTravelSchema = z.object({
    title: z.string().min(1),
    description: z.string().nullable().optional(),
    startDate: z.string().nullable().optional(),
    endDate: z.string().nullable().optional(),
    coverImageUrl: z.string().url().nullable().optional(),
    latitude: z.number().nullable().optional(),
    longitude: z.number().nullable().optional(),
    isPublic: z.boolean().optional(),
    externalId: z.string().nullable().optional(),
    provider: z.string().nullable().optional(),
});

const updateTravelSchema = createTravelSchema.partial();

// GET /travels - List user's travels
travels.get('/', async (c) => {
    const { userId } = getAuth(c);
    const memberRepo = AppDataSource.getRepository(TravelMember);

    const memberships = await memberRepo.find({
        where: { userId },
        relations: ['travel', 'travel.owner', 'travel.members', 'travel.members.user'],
        order: { travel: { createdAt: 'DESC' } },
    });

    const travelList = memberships.map((m) => ({
        id: m.travel.id,
        title: m.travel.title,
        description: m.travel.description,
        startDate: m.travel.startDate,
        endDate: m.travel.endDate,
        coverImageUrl: m.travel.coverImageUrl,
        latitude: m.travel.latitude,
        longitude: m.travel.longitude,
        isPublic: m.travel.isPublic,
        role: m.role,
        owner: {
            id: m.travel.owner.id,
            name: m.travel.owner.name,
        },
        createdAt: m.travel.createdAt,
        members: (m.travel.members || []).map((member) => ({
            id: member.user.id,
            name: member.user.name,
            profilePhotoUrl: member.user.profilePhotoUrl,
        })),
    }));

    return c.json(travelList);
});

// POST /travels - Create travel
travels.post('/', zValidator('json', createTravelSchema), async (c) => {
    const { userId } = getAuth(c);
    const data = c.req.valid('json');
    const travelRepo = AppDataSource.getRepository(Travel);
    const memberRepo = AppDataSource.getRepository(TravelMember);

    // Auto-fetch cover image if not provided
    let coverImageUrl = data.coverImageUrl;
    if (!coverImageUrl && data.title) {
        coverImageUrl = await getPlaceImage(data.title);
    }

    // Auto-create/link Place if lat/lng provided
    let placeId: string | null = null;
    if (data.latitude != null && data.longitude != null) {
        try {
            const place = await findOrCreatePlace({
                name: data.title,
                latitude: data.latitude,
                longitude: data.longitude,
                externalId: data.externalId ?? null,
                provider: data.provider ?? null,
            });
            placeId = place.id;
        } catch (err) {
            console.error('Failed to create/find place for travel:', err);
        }
    }

    // Create travel
    const travel = travelRepo.create({
        ...data,
        coverImageUrl,
        startDate: data.startDate ? new Date(data.startDate) : null,
        endDate: data.endDate ? new Date(data.endDate) : null,
        ownerId: userId,
        placeId,
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
        relations: ['owner', 'itineraries', 'itineraries.activities', 'itineraries.activities.createdBy'],
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
        itineraries: travel.itineraries.map((it) => ({
            ...it,
            activities: it.activities.map((act) => ({
                ...act,
                createdBy: act.createdBy
                    ? { id: act.createdBy.id, name: act.createdBy.name, email: act.createdBy.email, username: act.createdBy.username, profilePhotoUrl: act.createdBy.profilePhotoUrl }
                    : null,
            })),
        })),
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
    if (data.latitude !== undefined) travel.latitude = data.latitude;
    if (data.longitude !== undefined) travel.longitude = data.longitude;

    if (data.isPublic !== undefined) {
        // Only the owner can toggle isPublic
        const { userId } = getAuth(c);
        if (travel.ownerId !== userId) {
            return c.json({ error: 'Only the owner can change visibility' }, 403);
        }
        travel.isPublic = data.isPublic;
    }

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

// POST /travels/:travelId/cover - Upload cover image
travels.post('/:travelId/cover', requireTravelAccess('editor'), async (c) => {
    const travelId = c.req.param('travelId');
    const body = await c.req.parseBody();
    const file = body['file'];

    if (!file || !(file instanceof File)) {
        return c.json({ error: 'No file uploaded' }, 400);
    }

    // Basic validation
    if (!file.type.startsWith('image/')) {
        return c.json({ error: 'Invalid file type' }, 400);
    }

    if (file.size > 5 * 1024 * 1024) { // 5MB limit
        return c.json({ error: 'File too large (max 5MB)' }, 400);
    }

    try {
        const fileExt = file.name.split('.').pop() || 'jpg';
        const fileName = `${travelId}/${Date.now()}.${fileExt}`;
        const publicUrl = await uploadImage(file, fileName);

        if (!publicUrl) {
            throw new Error('Failed to get public URL');
        }

        // Update travel
        const travelRepo = AppDataSource.getRepository(Travel);
        await travelRepo.update({ id: travelId }, { coverImageUrl: publicUrl });

        return c.json({ coverImageUrl: publicUrl });
    } catch (error) {
        console.error('Upload failed:', error);
        return c.json({ error: 'Upload failed' }, 500);
    }
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
                username: m.user.username,
            },
        }))
    );
});

// POST /travels/:travelId/members - Send invite to user
travels.post('/:travelId/members', requireTravelAccess('owner'), zValidator('json', inviteSchema), async (c) => {
    const { userId } = getAuth(c);
    const travelId = c.req.param('travelId');
    const { email, role } = c.req.valid('json');
    const userRepo = AppDataSource.getRepository(User);
    const memberRepo = AppDataSource.getRepository(TravelMember);
    const inviteRepo = AppDataSource.getRepository(TravelInvite);

    // Find user by email
    const user = await userRepo.findOne({ where: { email } });
    if (!user) {
        return c.json({ error: 'User not found' }, 404);
    }

    // Check if already member
    const existingMember = await memberRepo.findOne({
        where: { travelId, userId: user.id },
    });
    if (existingMember) {
        return c.json({ error: 'User is already a member' }, 400);
    }

    // Check if already has pending invite
    const existingInvite = await inviteRepo.findOne({
        where: { travelId, invitedUserId: user.id, status: InviteStatus.PENDING },
    });
    if (existingInvite) {
        return c.json({ error: 'User already has a pending invite' }, 400);
    }

    // Create invite
    const invite = inviteRepo.create({
        travelId,
        invitedUserId: user.id,
        invitedByUserId: userId,
        role: role === 'editor' ? MemberRole.EDITOR : MemberRole.VIEWER,
        status: InviteStatus.PENDING,
    });
    await inviteRepo.save(invite);

    return c.json({
        id: invite.id,
        role: invite.role,
        status: invite.status,
        createdAt: invite.createdAt,
        user: { id: user.id, name: user.name, email: user.email, profilePhotoUrl: user.profilePhotoUrl, username: user.username },
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

// --- Invite Management ---

// GET /travels/:travelId/invites - List pending invites for travel
travels.get('/:travelId/invites', requireTravelAccess('owner'), async (c) => {
    const travelId = c.req.param('travelId');
    const inviteRepo = AppDataSource.getRepository(TravelInvite);

    const invites = await inviteRepo.find({
        where: { travelId, status: InviteStatus.PENDING },
        relations: ['invitedUser'],
        order: { createdAt: 'DESC' },
    });

    return c.json(
        invites.map((invite) => ({
            id: invite.id,
            role: invite.role,
            status: invite.status,
            createdAt: invite.createdAt,
            user: {
                id: invite.invitedUser.id,
                name: invite.invitedUser.name,
                email: invite.invitedUser.email,
                profilePhotoUrl: invite.invitedUser.profilePhotoUrl,
                username: invite.invitedUser.username,
            },
        }))
    );
});

// DELETE /travels/:travelId/invites/:inviteId - Cancel pending invite
travels.delete('/:travelId/invites/:inviteId', requireTravelAccess('owner'), async (c) => {
    const travelId = c.req.param('travelId');
    const inviteId = c.req.param('inviteId');
    const inviteRepo = AppDataSource.getRepository(TravelInvite);

    const invite = await inviteRepo.findOne({
        where: { id: inviteId, travelId, status: InviteStatus.PENDING },
    });

    if (!invite) {
        return c.json({ error: 'Invite not found' }, 404);
    }

    await inviteRepo.delete({ id: inviteId });
    return c.json({ success: true });
});

// POST /travels/:travelId/leave - Non-owner leaves travel
travels.post('/:travelId/leave', requireTravelAccess('viewer'), async (c) => {
    const { userId } = getAuth(c);
    const travelId = c.req.param('travelId');
    const memberRepo = AppDataSource.getRepository(TravelMember);

    const member = await memberRepo.findOne({
        where: { travelId, userId },
    });

    if (!member) {
        return c.json({ error: 'Not a member of this travel' }, 404);
    }

    // Owner cannot leave
    if (member.role === MemberRole.OWNER) {
        return c.json({ error: 'Owner cannot leave the travel. Delete the travel instead.' }, 400);
    }

    await memberRepo.delete({ id: member.id });
    return c.json({ success: true });
});

export default travels;
