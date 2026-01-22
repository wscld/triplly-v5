import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    ManyToOne,
    JoinColumn,
    CreateDateColumn,
    Unique,
    type Relation,
} from 'typeorm';
import type { User } from './User.js';
import type { Travel } from './Travel.js';

export enum MemberRole {
    OWNER = 'owner',
    EDITOR = 'editor',
    VIEWER = 'viewer',
}

@Entity('travel_members')
@Unique(['travelId', 'userId'])
export class TravelMember {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column('uuid')
    travelId: string;

    @Column('uuid')
    userId: string;

    @Column({ type: 'enum', enum: MemberRole, default: MemberRole.VIEWER })
    role: MemberRole;

    @CreateDateColumn()
    joinedAt: Date;

    @ManyToOne("Travel", (travel: Travel) => travel.members, { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'travelId' })
    travel: Relation<Travel>;

    @ManyToOne("User", (user: User) => user.memberships, { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'userId' })
    user: Relation<User>;
}
