import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    ManyToOne,
    JoinColumn,
    CreateDateColumn,
} from 'typeorm';
import { Activity } from './Activity.js';
import { User } from './User.js';

@Entity('activity_comments')
export class ActivityComment {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column('uuid')
    activityId: string;

    @Column('uuid')
    userId: string;

    @Column('text')
    content: string;

    @CreateDateColumn()
    createdAt: Date;

    @ManyToOne(() => Activity, (activity) => activity.comments, { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'activityId' })
    activity: Activity;

    @ManyToOne(() => User, (user) => user.activityComments, { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'userId' })
    user: User;
}
