import { Hono } from 'hono';
import { AppDataSource } from '../data-source.js';
import { TravelInvite, InviteStatus, TravelMember, MemberRole } from '../entities/index.js';
import { authMiddleware, getAuth } from '../middleware/index.js';

const invites = new Hono();

// All routes require authentication
invites.use('*', authMiddleware);

// GET /invites - Get current user's pending invites
invites.get('/', async (c) => {
    const { userId } = getAuth(c);
    const inviteRepo = AppDataSource.getRepository(TravelInvite);

    const pendingInvites = await inviteRepo.find({
        where: {
            invitedUserId: userId,
            status: InviteStatus.PENDING,
        },
        relations: ['travel', 'travel.owner', 'invitedBy'],
        order: { createdAt: 'DESC' },
    });

    return c.json(
        pendingInvites.map((invite) => ({
            id: invite.id,
            role: invite.role,
            status: invite.status,
            createdAt: invite.createdAt,
            travel: {
                id: invite.travel.id,
                title: invite.travel.title,
                description: invite.travel.description,
                startDate: invite.travel.startDate,
                endDate: invite.travel.endDate,
                coverImageUrl: invite.travel.coverImageUrl,
                owner: {
                    id: invite.travel.owner.id,
                    name: invite.travel.owner.name,
                },
            },
            invitedBy: {
                id: invite.invitedBy.id,
                name: invite.invitedBy.name,
                email: invite.invitedBy.email,
            },
        }))
    );
});

// POST /invites/:inviteId/accept - Accept invite
invites.post('/:inviteId/accept', async (c) => {
    const { userId } = getAuth(c);
    const inviteId = c.req.param('inviteId');
    const inviteRepo = AppDataSource.getRepository(TravelInvite);
    const memberRepo = AppDataSource.getRepository(TravelMember);

    const invite = await inviteRepo.findOne({
        where: { id: inviteId, invitedUserId: userId },
    });

    if (!invite) {
        return c.json({ error: 'Invite not found' }, 404);
    }

    if (invite.status !== InviteStatus.PENDING) {
        return c.json({ error: 'Invite has already been responded to' }, 400);
    }

    // Check if user is already a member (race condition)
    const existingMember = await memberRepo.findOne({
        where: { travelId: invite.travelId, userId },
    });

    if (existingMember) {
        // Update invite status and return success
        invite.status = InviteStatus.ACCEPTED;
        invite.respondedAt = new Date();
        await inviteRepo.save(invite);
        return c.json({ success: true });
    }

    // Create membership
    const member = memberRepo.create({
        travelId: invite.travelId,
        userId,
        role: invite.role,
    });
    await memberRepo.save(member);

    // Update invite status
    invite.status = InviteStatus.ACCEPTED;
    invite.respondedAt = new Date();
    await inviteRepo.save(invite);

    return c.json({ success: true });
});

// POST /invites/:inviteId/reject - Reject invite
invites.post('/:inviteId/reject', async (c) => {
    const { userId } = getAuth(c);
    const inviteId = c.req.param('inviteId');
    const inviteRepo = AppDataSource.getRepository(TravelInvite);

    const invite = await inviteRepo.findOne({
        where: { id: inviteId, invitedUserId: userId },
    });

    if (!invite) {
        return c.json({ error: 'Invite not found' }, 404);
    }

    if (invite.status !== InviteStatus.PENDING) {
        return c.json({ error: 'Invite has already been responded to' }, 400);
    }

    // Update invite status
    invite.status = InviteStatus.REJECTED;
    invite.respondedAt = new Date();
    await inviteRepo.save(invite);

    return c.json({ success: true });
});

export default invites;
