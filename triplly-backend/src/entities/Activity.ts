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
import { Itinerary } from './Itinerary.js';
import { ActivityComment } from './ActivityComment.js';
import { Travel } from './Travel.js';
import { User } from './User.js';

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
    googlePlaceId: string | null;

    @Column('varchar', { nullable: true })
    address: string | null;

    @Column('varchar', { nullable: true })
    startTime: string | null;

    @CreateDateColumn()
    createdAt: Date;

    @Column('uuid', { nullable: true })
    createdById: string | null;

    @ManyToOne(() => User, { nullable: true })
    @JoinColumn({ name: 'createdById' })
    createdBy: Relation<User> | null;

    @ManyToOne(() => Travel, { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'travelId' })
    travel: Relation<Travel>;

    @ManyToOne(() => Itinerary, (itinerary) => itinerary.activities, { onDelete: 'CASCADE', nullable: true })
    @JoinColumn({ name: 'itineraryId' })
    itinerary: Relation<Itinerary> | null;

    @OneToMany(() => ActivityComment, (comment) => comment.activity)
    comments: ActivityComment[];
}

