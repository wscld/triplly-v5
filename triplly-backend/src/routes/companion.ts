import { Hono } from 'hono';
import { zValidator } from '@hono/zod-validator';
import { z } from 'zod';
import OpenAI from 'openai';
import { AppDataSource } from '../data-source.js';
import { authMiddleware, getAuth } from '../middleware/index.js';
import { TravelMember } from '../entities/index.js';

const companion = new Hono();
companion.use('*', authMiddleware);

const chatSchema = z.object({
    message: z.string().min(1),
    conversationHistory: z.array(z.object({
        role: z.enum(['user', 'assistant']),
        content: z.string()
    })).optional()
});

// POST /api/companion/chat
companion.post('/chat', zValidator('json', chatSchema), async (c) => {
    const { userId } = getAuth(c);
    const { message, conversationHistory } = c.req.valid('json');

    // 1. Fetch ALL user's travels with full context
    const memberRepo = AppDataSource.getRepository(TravelMember);
    const memberships = await memberRepo.find({
        where: { userId },
        relations: [
            'travel',
            'travel.owner',
            'travel.itineraries',
            'travel.itineraries.activities',
            'travel.todos'
        ]
    });

    // 2. Build travel context for AI
    const travelsContext = memberships.map(m => ({
        title: m.travel.title,
        role: m.role,
        dates: { start: m.travel.startDate, end: m.travel.endDate },
        description: m.travel.description,
        itineraries: m.travel.itineraries?.map(it => ({
            title: it.title,
            date: it.date,
            activities: it.activities?.map(a => ({
                title: a.title,
                address: a.address,
                time: a.startTime
            }))
        })),
        todos: m.travel.todos?.map(t => ({
            title: t.title,
            completed: t.isCompleted
        }))
    }));

    // 3. Call OpenAI
    const openai = new OpenAI({ apiKey: process.env.OPENAI_API_KEY });

    const systemPrompt = `You are Triplly Companion, a helpful travel assistant. You have access to the user's travel information and can help them with questions, suggestions, and insights about their trips.

Current user's travels:
${JSON.stringify(travelsContext, null, 2)}

Guidelines:
- Be friendly and conversational
- Provide specific, actionable advice based on their actual travel plans
- If asked about a trip, reference specific activities and dates
- Suggest improvements or things they might have missed
- Help with packing lists, timing, and logistics based on their itinerary
- Keep responses concise but helpful`;

    const messages: OpenAI.ChatCompletionMessageParam[] = [
        { role: 'system', content: systemPrompt },
        ...(conversationHistory || []),
        { role: 'user', content: message }
    ];

    const completion = await openai.chat.completions.create({
        model: 'gpt-4o',
        messages,
        max_tokens: 1000,
        temperature: 0.7
    });

    return c.json({
        response: completion.choices[0].message.content,
        timestamp: new Date().toISOString()
    });
});

export default companion;
