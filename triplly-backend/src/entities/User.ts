import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    OneToMany,
} from 'typeorm';
import type { TravelMember } from './TravelMember.js';
import type { ActivityComment } from './ActivityComment.js';

@Entity('users')
export class User {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column('varchar', { unique: true })
    email: string;

    @Column('varchar', { nullable: true })
    passwordHash: string | null;

    @Column('varchar', { unique: true, nullable: true })
    appleId: string | null;

    @Column('varchar')
    name: string;

    @Column('varchar', { nullable: true })
    profilePhotoUrl: string | null;

    @CreateDateColumn()
    createdAt: Date;

    @OneToMany("TravelMember", (member: TravelMember) => member.user)
    memberships: TravelMember[];

    @OneToMany("ActivityComment", (comment: ActivityComment) => comment.user)
    activityComments: ActivityComment[];
}
