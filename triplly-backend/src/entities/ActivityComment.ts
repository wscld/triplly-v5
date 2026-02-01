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

    @Column({ type: 'text', nullable: true })
    linkUrl: string | null;

    @Column({ type: 'text', nullable: true })
    linkTitle: string | null;

    @Column({ type: 'text', nullable: true })
    linkDescription: string | null;

    @Column({ type: 'text', nullable: true })
    linkImageUrl: string | null;

    @CreateDateColumn()
    createdAt: Date;

    @ManyToOne("Activity", (activity: Activity) => activity.comments, { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'activityId' })
    activity: Relation<Activity>;

    @ManyToOne("User", (user: User) => user.activityComments, { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'userId' })
    user: Relation<User>;
}
