import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    ManyToOne,
    OneToMany,
    JoinColumn,
} from 'typeorm';
import { User } from './User.js';
import { TravelMember } from './TravelMember.js';
import { Itinerary } from './Itinerary.js';

@Entity('travels')
export class Travel {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column('varchar')
    title: string;

    @Column({ type: 'text', nullable: true })
    description: string | null;

    @Column({ type: 'date', nullable: true })
    startDate: Date | null;

    @Column({ type: 'date', nullable: true })
    endDate: Date | null;

    @Column('varchar', { nullable: true })
    coverImageUrl: string | null;

    @CreateDateColumn()
    createdAt: Date;

    @Column('uuid')
    ownerId: string;

    @ManyToOne(() => User)
    @JoinColumn({ name: 'ownerId' })
    owner: User;

    @OneToMany(() => TravelMember, (member) => member.travel)
    members: TravelMember[];

    @OneToMany(() => Itinerary, (itinerary) => itinerary.travel)
    itineraries: Itinerary[];
}
