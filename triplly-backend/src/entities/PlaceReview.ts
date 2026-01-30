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

@Entity('place_reviews')
@Unique(['placeId', 'userId'])
export class PlaceReview {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column('uuid')
    placeId: string;

    @Column('uuid')
    userId: string;

    @Column({ type: 'int' })
    rating: number;

    @Column({ type: 'text' })
    content: string;

    @CreateDateColumn()
    createdAt: Date;

    @ManyToOne("Place", (place: Place) => place.reviews)
    @JoinColumn({ name: 'placeId' })
    place: Relation<Place>;

    @ManyToOne("User")
    @JoinColumn({ name: 'userId' })
    user: Relation<User>;
}
