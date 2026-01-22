var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, UpdateDateColumn, ManyToOne, JoinColumn, } from 'typeorm';
let Todo = class Todo {
    id;
    title;
    isCompleted;
    travelId;
    travel;
    createdAt;
    updatedAt;
};
__decorate([
    PrimaryGeneratedColumn('uuid'),
    __metadata("design:type", String)
], Todo.prototype, "id", void 0);
__decorate([
    Column('varchar'),
    __metadata("design:type", String)
], Todo.prototype, "title", void 0);
__decorate([
    Column({ type: 'boolean', default: false }),
    __metadata("design:type", Boolean)
], Todo.prototype, "isCompleted", void 0);
__decorate([
    Column('uuid'),
    __metadata("design:type", String)
], Todo.prototype, "travelId", void 0);
__decorate([
    ManyToOne("Travel", (travel) => travel.todos, { onDelete: 'CASCADE' }),
    JoinColumn({ name: 'travelId' }),
    __metadata("design:type", Object)
], Todo.prototype, "travel", void 0);
__decorate([
    CreateDateColumn(),
    __metadata("design:type", Date)
], Todo.prototype, "createdAt", void 0);
__decorate([
    UpdateDateColumn(),
    __metadata("design:type", Date)
], Todo.prototype, "updatedAt", void 0);
Todo = __decorate([
    Entity('todos')
], Todo);
export { Todo };
