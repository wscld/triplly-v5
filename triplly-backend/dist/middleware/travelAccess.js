import { AppDataSource } from '../data-source.js';
import { TravelMember, MemberRole } from '../entities/index.js';
import { getAuth } from './auth.js';
const roleHierarchy = {
    [MemberRole.VIEWER]: 1,
    [MemberRole.EDITOR]: 2,
    [MemberRole.OWNER]: 3,
};
/**
 * Middleware that checks if user has required role for a travel.
 * Expects travelId in route params.
 */
export function requireTravelAccess(minRole) {
    return async (c, next) => {
        const { userId } = getAuth(c);
        const travelId = c.req.param('travelId');
        if (!travelId) {
            return c.json({ error: 'Travel ID required' }, 400);
        }
        const memberRepo = AppDataSource.getRepository(TravelMember);
        const member = await memberRepo.findOne({
            where: { travelId, userId },
        });
        if (!member) {
            return c.json({ error: 'Not a member of this travel' }, 403);
        }
        const requiredLevel = roleHierarchy[minRole];
        const userLevel = roleHierarchy[member.role];
        if (userLevel < requiredLevel) {
            return c.json({ error: 'Insufficient permissions' }, 403);
        }
        c.set('member', member);
        await next();
    };
}
export function getMember(c) {
    return c.get('member');
}
