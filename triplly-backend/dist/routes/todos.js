import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import { AppDataSource } from '../data-source.js';
import { Todo, TravelMember, MemberRole } from '../entities/index.js';
import { authMiddleware, getAuth } from '../middleware/index.js';
const todos = new Hono();
todos.use('*', authMiddleware);
const createTodoSchema = z.object({
    travelId: z.string().uuid(),
    title: z.string().min(1),
});
const updateTodoSchema = z.object({
    title: z.string().min(1).optional(),
    isCompleted: z.boolean().optional(),
});
// Helper: Check access
async function checkTodoAccess(userId, todoIdStr, travelIdStr, minRole) {
    const todoRepo = AppDataSource.getRepository(Todo);
    const memberRepo = AppDataSource.getRepository(TravelMember);
    let travelId = travelIdStr;
    let todo = null;
    if (todoIdStr) {
        todo = await todoRepo.findOne({ where: { id: todoIdStr } });
        if (!todo)
            return { error: 'Todo not found', status: 404 };
        travelId = todo.travelId;
    }
    if (!travelId)
        return { error: 'Invalid request', status: 400 };
    const member = await memberRepo.findOne({ where: { travelId, userId } });
    if (!member)
        return { error: 'Not a member of this travel', status: 403 };
    const roleLevel = { viewer: 1, editor: 2, owner: 3 };
    if (roleLevel[member.role] < roleLevel[minRole]) {
        return { error: 'Insufficient permissions', status: 403 };
    }
    return { todo, member };
}
// GET /?travelId=...
todos.get('/', async (c) => {
    const { userId } = getAuth(c);
    const travelId = c.req.query('travelId');
    if (!travelId)
        return c.json({ error: 'Missing travelId' }, 400);
    const result = await checkTodoAccess(userId, null, travelId, 'viewer');
    if ('error' in result)
        return c.json({ error: result.error }, result.status);
    const todoRepo = AppDataSource.getRepository(Todo);
    const items = await todoRepo.find({
        where: { travelId },
        order: { createdAt: 'DESC' },
    });
    return c.json(items);
});
// POST /
todos.post('/', zValidator('json', createTodoSchema), async (c) => {
    const { userId } = getAuth(c);
    const { travelId, title } = c.req.valid('json');
    const result = await checkTodoAccess(userId, null, travelId, 'editor');
    if ('error' in result)
        return c.json({ error: result.error }, result.status);
    const todoRepo = AppDataSource.getRepository(Todo);
    const todo = todoRepo.create({ travelId, title });
    await todoRepo.save(todo);
    return c.json(todo, 201);
});
// PATCH /:id
todos.patch('/:id', zValidator('json', updateTodoSchema), async (c) => {
    const { userId } = getAuth(c);
    const id = c.req.param('id');
    const data = c.req.valid('json');
    const result = await checkTodoAccess(userId, id, null, 'editor');
    if ('error' in result)
        return c.json({ error: result.error }, result.status);
    const { todo } = result;
    if (!todo)
        return c.json({ error: 'Todo not found' }, 404); // Should be covered by checkTodoAccess
    if (data.title !== undefined)
        todo.title = data.title;
    if (data.isCompleted !== undefined)
        todo.isCompleted = data.isCompleted;
    const todoRepo = AppDataSource.getRepository(Todo);
    await todoRepo.save(todo);
    return c.json(todo);
});
// DELETE /:id
todos.delete('/:id', async (c) => {
    const { userId } = getAuth(c);
    const id = c.req.param('id');
    const result = await checkTodoAccess(userId, id, null, 'editor');
    if ('error' in result)
        return c.json({ error: result.error }, result.status);
    const todoRepo = AppDataSource.getRepository(Todo);
    await todoRepo.delete(id);
    return c.json({ success: true });
});
export default todos;
