import { Hono } from 'hono';
import { AppDataSource } from '../data-source.js';
import { User } from '../entities/User.js';
import { Travel } from '../entities/Travel.js';
import { TravelMember } from '../entities/TravelMember.js';
import { computeUserAwards } from '../services/awards.js';

const publicRoutes = new Hono();

// GET /public/users/:username - Public profile + public travels
publicRoutes.get('/users/:username', async (c) => {
    const username = c.req.param('username');
    const userRepo = AppDataSource.getRepository(User);
    const memberRepo = AppDataSource.getRepository(TravelMember);

    const user = await userRepo.findOne({ where: { username } });
    if (!user) {
        return c.json({ error: 'User not found' }, 404);
    }

    // Get user's travels that are public
    const memberships = await memberRepo.find({
        where: { userId: user.id },
        relations: ['travel'],
    });

    const publicTravels = memberships
        .filter((m) => m.travel.isPublic)
        .map((m) => ({
            id: m.travel.id,
            title: m.travel.title,
            description: m.travel.description,
            startDate: m.travel.startDate,
            endDate: m.travel.endDate,
            coverImageUrl: m.travel.coverImageUrl,
            latitude: m.travel.latitude,
            longitude: m.travel.longitude,
        }));

    const awards = await computeUserAwards(user.id);

    return c.json({
        id: user.id,
        name: user.name,
        username: user.username,
        profilePhotoUrl: user.profilePhotoUrl,
        travels: publicTravels,
        awards,
    });
});

// GET /public/travels/:travelId - Public travel detail with itineraries/activities
publicRoutes.get('/travels/:travelId', async (c) => {
    const travelId = c.req.param('travelId');
    const travelRepo = AppDataSource.getRepository(Travel);

    const travel = await travelRepo.findOne({
        where: { id: travelId, isPublic: true },
        relations: ['owner', 'itineraries', 'itineraries.activities', 'itineraries.activities.categoryRef'],
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
        owner: {
            id: travel.owner.id,
            name: travel.owner.name,
            username: travel.owner.username,
            profilePhotoUrl: travel.owner.profilePhotoUrl,
        },
    });
});

// GET /public/users/:username/available - Username availability check
publicRoutes.get('/users/:username/available', async (c) => {
    const username = c.req.param('username');
    const userRepo = AppDataSource.getRepository(User);

    // Validate format
    if (username.length < 3 || username.length > 30 || !/^[a-z0-9_]+$/.test(username)) {
        return c.json({ available: false, reason: 'Invalid format' });
    }

    const existing = await userRepo.findOne({ where: { username } });
    return c.json({ available: !existing });
});

export default publicRoutes;
