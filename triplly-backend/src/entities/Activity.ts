import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    ManyToOne,
    JoinColumn,
    CreateDateColumn,
    OneToMany,
    type Relation,
} from 'typeorm';
import type { Itinerary } from './Itinerary.js';
import type { ActivityComment } from './ActivityComment.js';
import type { Travel } from './Travel.js';
import type { User } from './User.js';
import type { Place } from './Place.js';

@Entity('activities')
export class Activity {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column('uuid')
    travelId: string;

    @Column('uuid', { nullable: true })
    itineraryId: string | null;

    @Column('varchar')
    title: string;

    @Column({ type: 'text', nullable: true })
    description: string | null;

    @Column({ type: 'float', default: 0 })
    orderIndex: number;

    @Column({ type: 'float' })
    latitude: number;

    @Column({ type: 'float' })
    longitude: number;

    @Column('varchar', { nullable: true })
    externalId: string | null;

    @Column('varchar', { nullable: true })
    provider: string | null;

    @Column('varchar', { nullable: true })
    address: string | null;

    @Column('uuid', { nullable: true })
    placeId: string | null;

    @Column('varchar', { nullable: true })
    startTime: string | null;

    @CreateDateColumn()
    createdAt: Date;

    @Column('uuid', { nullable: true })
    createdById: string | null;

    @ManyToOne("User", { nullable: true })
    @JoinColumn({ name: 'createdById' })
    createdBy: Relation<User> | null;

    @ManyToOne("Place", { nullable: true, onDelete: 'SET NULL' })
    @JoinColumn({ name: 'placeId' })
    place: Relation<Place> | null;

    @ManyToOne("Travel", { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'travelId' })
    travel: Relation<Travel>;

    @ManyToOne("Itinerary", (itinerary: Itinerary) => itinerary.activities, { onDelete: 'CASCADE', nullable: true })
    @JoinColumn({ name: 'itineraryId' })
    itinerary: Relation<Itinerary> | null;

    @OneToMany("ActivityComment", (comment: ActivityComment) => comment.activity)
    comments: ActivityComment[];
}

