import 'reflect-metadata';
import { DataSource } from 'typeorm';
import { config } from 'dotenv';
import {
    User,
    Travel,
    TravelMember,
    TravelInvite,
    Itinerary,
    Activity,
    ActivityComment,
    Todo,
} from './entities/index.js';

config();

export const AppDataSource = new DataSource({
    type: 'postgres',
    url: process.env.DATABASE_URL,
    synchronize: true, // Set to false in production, use migrations
    logging: process.env.NODE_ENV === 'development',
    entities: [
        User,
        Travel,
        TravelMember,
        TravelInvite,
        Itinerary,
        Activity,
        ActivityComment,
        Todo,
    ],
    migrations: ['src/migrations/**/*.ts'],
    ssl: {
        rejectUnauthorized: false,
    },
});
