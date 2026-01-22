import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    UpdateDateColumn,
    ManyToOne,
    JoinColumn,
    type Relation,
} from 'typeorm';
import type { Travel } from './Travel.js';

@Entity('todos')
export class Todo {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column('varchar')
    title: string;

    @Column({ type: 'boolean', default: false })
    isCompleted: boolean;

    @Column('uuid')
    travelId: string;

    @ManyToOne("Travel", (travel: Travel) => travel.todos, { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'travelId' })
    travel: Relation<Travel>;

    @CreateDateColumn()
    createdAt: Date;

    @UpdateDateColumn()
    updatedAt: Date;
}
