import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    OneToMany,
} from 'typeorm';
import { TravelMember } from './TravelMember.js';
import { ActivityComment } from './ActivityComment.js';

@Entity('users')
export class User {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column('varchar', { unique: true })
    email: string;

    @Column('varchar')
    passwordHash: string;

    @Column('varchar')
    name: string;

    @Column('varchar', { nullable: true })
    profilePhotoUrl: string | null;

    @CreateDateColumn()
    createdAt: Date;

    @OneToMany(() => TravelMember, (member) => member.user)
    memberships: TravelMember[];

    @OneToMany(() => ActivityComment, (comment) => comment.user)
    activityComments: ActivityComment[];
}
