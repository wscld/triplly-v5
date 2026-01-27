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
import { MemberRole } from './TravelMember.js';

export enum InviteStatus {
    PENDING = 'pending',
    ACCEPTED = 'accepted',
    REJECTED = 'rejected',
}

@Entity('travel_invites')
@Unique(['travelId', 'invitedUserId'])
export class TravelInvite {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column('uuid')
    travelId: string;

    @Column('uuid')
    invitedUserId: string;

    @Column('uuid')
    invitedByUserId: string;

    @Column({ type: 'enum', enum: MemberRole, default: MemberRole.VIEWER })
    role: MemberRole;

    @Column({ type: 'enum', enum: InviteStatus, default: InviteStatus.PENDING })
    status: InviteStatus;

    @CreateDateColumn()
    createdAt: Date;

    @Column({ type: 'timestamp', nullable: true })
    respondedAt: Date | null;

    @ManyToOne("Travel", (travel: Travel) => travel.invites, { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'travelId' })
    travel: Relation<Travel>;

    @ManyToOne("User", { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'invitedUserId' })
    invitedUser: Relation<User>;

    @ManyToOne("User", { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'invitedByUserId' })
    invitedBy: Relation<User>;
}
