import {
    Entity,
    PrimaryGeneratedColumn,
    Column,
    CreateDateColumn,
    UpdateDateColumn,
    ManyToOne,
    JoinColumn
} from 'typeorm';
import { Travel } from './Travel.js';

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

    @ManyToOne(() => Travel, (travel) => travel.todos, { onDelete: 'CASCADE' })
    @JoinColumn({ name: 'travelId' })
    travel: Travel;

    @CreateDateColumn()
    createdAt: Date;

    @UpdateDateColumn()
    updatedAt: Date;
}
