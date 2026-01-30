import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    ManyToOne,
    OneToMany,
    JoinColumn,
    type Relation,
} from 'typeorm';
import type { User } from './User.js';
import type { TravelMember } from './TravelMember.js';
import type { TravelInvite } from './TravelInvite.js';
import type { Itinerary } from './Itinerary.js';
import type { Todo } from './Todo.js';
import type { Place } from './Place.js';

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

    @Column({ type: 'decimal', precision: 10, scale: 7, nullable: true })
    latitude: number | null;

    @Column({ type: 'decimal', precision: 10, scale: 7, nullable: true })
    longitude: number | null;

    @Column({ type: 'boolean', default: false })
    isPublic: boolean;

    @Column('uuid', { nullable: true })
    placeId: string | null;

    @CreateDateColumn()
    createdAt: Date;

    @Column('uuid')
    ownerId: string;

    @ManyToOne("User")
    @JoinColumn({ name: 'ownerId' })
    owner: Relation<User>;

    @ManyToOne("Place", { nullable: true, onDelete: 'SET NULL' })
    @JoinColumn({ name: 'placeId' })
    place: Relation<Place> | null;

    @OneToMany("TravelMember", (member: TravelMember) => member.travel)
    members: TravelMember[];

    @OneToMany("Itinerary", (itinerary: Itinerary) => itinerary.travel)
    itineraries: Itinerary[];

    @OneToMany("Todo", (todo: Todo) => todo.travel)
    todos: Todo[];

    @OneToMany("TravelInvite", (invite: TravelInvite) => invite.travel)
    invites: TravelInvite[];
}
