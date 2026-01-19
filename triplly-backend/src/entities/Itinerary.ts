import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    ManyToOne,
    OneToMany,
    JoinColumn,
} from 'typeorm';
import { Travel } from './Travel.js';
import { Activity } from './Activity.js';

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

    @ManyToOne(() => Travel, (travel) => travel.itineraries, { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'travelId' })
    travel: Travel;

    @OneToMany(() => Activity, (activity) => activity.itinerary)
    activities: Activity[];
}
