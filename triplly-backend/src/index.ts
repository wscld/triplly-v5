import 'reflect-metadata';
import { serve } from '@hono/node-server';
import { Hono } from 'hono';
import { cors } from 'hono/cors';
import { logger } from 'hono/logger';
import { config } from 'dotenv';

import { AppDataSource } from './data-source.js';
import { authRoutes, travelRoutes, inviteRoutes, itineraryRoutes, activityRoutes, commentRoutes, todoRoutes, companionRoutes, publicRoutes, checkinRoutes, placeRoutes, reviewRoutes } from './routes/index.js';

config();

const app = new Hono();

// Middleware
app.use('*', logger());
app.use('*', cors({
  origin: '*', // Configure for production
  allowMethods: ['GET', 'POST', 'PATCH', 'DELETE', 'OPTIONS'],
  allowHeaders: ['Content-Type', 'Authorization'],
}));

// Health check
app.get('/', (c) => c.json({ status: 'ok', name: 'Triplly API' }));

// API Routes
app.route('/api/auth', authRoutes);
app.route('/api/travels', travelRoutes);
app.route('/api/invites', inviteRoutes);
app.route('/api/itineraries', itineraryRoutes);
app.route('/api/activities', activityRoutes);
app.route('/api/comments', commentRoutes);
app.route('/api/todos', todoRoutes);
app.route('/api/companion', companionRoutes);
app.route('/api/public', publicRoutes);
app.route('/api/checkins', checkinRoutes);
app.route('/api/places', placeRoutes);
app.route('/api/reviews', reviewRoutes);

// Error handler
app.onError((err, c) => {
  console.error('Error:', err);
  return c.json({ error: 'Internal server error' }, 500);
});

// Not found handler
app.notFound((c) => {
  return c.json({ error: 'Not found' }, 404);
});

// Initialize database and start server
const port = parseInt(process.env.PORT || '3000', 10);

AppDataSource.initialize()
  .then(() => {
    console.log('Database connected');
    serve({
      fetch: app.fetch,
      port,
    }, (info) => {
      console.log(`Server is running on http://localhost:${info.port}`);
    });
  })
  .catch((error) => {
    console.error('Database connection failed:', error);
    process.exit(1);
  });
