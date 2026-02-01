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
import type { Travel } from './Travel.js';
import type { User } from './User.js';

@Entity('categories')
@Unique(['travelId', 'name'])
export class Category {
    @PrimaryGeneratedColumn('uuid')
    id: string;

    @Column('varchar')
    name: string;

    @Column('varchar')
    icon: string;

    @Column('varchar')
    color: string;

    @Column({ type: 'boolean', default: false })
    isDefault: boolean;

    @Column('uuid', { nullable: true })
    travelId: string | null;

    @Column('uuid', { nullable: true })
    createdById: string | null;

    @CreateDateColumn()
    createdAt: Date;

    @ManyToOne("Travel", { nullable: true, onDelete: 'CASCADE' })
    @JoinColumn({ name: 'travelId' })
    travel: Relation<Travel> | null;

    @ManyToOne("User", { nullable: true, onDelete: 'SET NULL' })
    @JoinColumn({ name: 'createdById' })
    createdBy: Relation<User> | null;
}
