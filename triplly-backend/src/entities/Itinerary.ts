import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    ManyToOne,
    OneToMany,
    JoinColumn,
    type Relation,
} from 'typeorm';
import type { Travel } from './Travel.js';
import type { Activity } from './Activity.js';

@Entity('itineraries')
export class Itinerary {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column('uuid')
    travelId: string;

    @Column({ type: 'date', nullable: true })
    date: Date | null;

    @Column('varchar')
    title: string;

    @Column({ type: 'float', default: 0 })
    orderIndex: number;

    @ManyToOne("Travel", (travel: Travel) => travel.itineraries, { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'travelId' })
    travel: Relation<Travel>;

    @OneToMany("Activity", (activity: Activity) => activity.itinerary)
    activities: Activity[];
}
