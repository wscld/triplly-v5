import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    ManyToOne,
    JoinColumn,
    CreateDateColumn,
    type Relation,
} from 'typeorm';
import type { Activity } from './Activity.js';
import type { User } from './User.js';

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

    @ManyToOne("Activity", (activity: Activity) => activity.comments, { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'activityId' })
    activity: Relation<Activity>;

    @ManyToOne("User", (user: User) => user.activityComments, { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'userId' })
    user: Relation<User>;
}
