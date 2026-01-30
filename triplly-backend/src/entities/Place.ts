import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    OneToMany,
    Unique,
    type Relation,
} from 'typeorm';
import type { CheckIn } from './CheckIn.js';
import type { PlaceReview } from './PlaceReview.js';

@Entity('places')
@Unique(['externalId', 'provider'])
export class Place {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column('varchar')
    name: string;

    @Column({ type: 'decimal', precision: 10, scale: 7 })
    latitude: number;

    @Column({ type: 'decimal', precision: 10, scale: 7 })
    longitude: number;

    @Column('varchar', { nullable: true })
    address: string | null;

    @Column('varchar', { nullable: true })
    externalId: string | null;

    @Column('varchar', { nullable: true })
    provider: string | null;

    @CreateDateColumn()
    createdAt: Date;

    @OneToMany("CheckIn", (checkIn: CheckIn) => checkIn.place)
    checkIns: CheckIn[];

    @OneToMany("PlaceReview", (review: PlaceReview) => review.place)
    reviews: PlaceReview[];
}
