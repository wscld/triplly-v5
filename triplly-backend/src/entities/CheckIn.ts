import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    ManyToOne,
    JoinColumn,
    Unique,
    type Relation,
} from 'typeorm';
import type { Place } from './Place.js';
import type { User } from './User.js';
import type { Activity } from './Activity.js';

@Entity('check_ins')
@Unique(['placeId', 'userId'])
export class CheckIn {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column('uuid')
    placeId: string;

    @Column('uuid')
    userId: string;

    @Column('uuid', { nullable: true })
    activityId: string | null;

    @CreateDateColumn()
    createdAt: Date;

    @ManyToOne("Place", (place: Place) => place.checkIns)
    @JoinColumn({ name: 'placeId' })
    place: Relation<Place>;

    @ManyToOne("User")
    @JoinColumn({ name: 'userId' })
    user: Relation<User>;

    @ManyToOne("Activity", { nullable: true, onDelete: 'SET NULL' })
    @JoinColumn({ name: 'activityId' })
    activity: Relation<Activity> | null;
}
