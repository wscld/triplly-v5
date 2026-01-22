var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn, CreateDateColumn, } from 'typeorm';
import { Activity } from './Activity.js';
import { User } from './User.js';
let ActivityComment = class ActivityComment {
    id;
    activityId;
    userId;
    content;
    createdAt;
    activity;
    user;
};
__decorate([
    PrimaryGeneratedColumn('uuid'),
    __metadata("design:type", String)
], ActivityComment.prototype, "id", void 0);
__decorate([
    Column('uuid'),
    __metadata("design:type", String)
], ActivityComment.prototype, "activityId", void 0);
__decorate([
    Column('uuid'),
    __metadata("design:type", String)
], ActivityComment.prototype, "userId", void 0);
__decorate([
    Column('text'),
    __metadata("design:type", String)
], ActivityComment.prototype, "content", void 0);
__decorate([
    CreateDateColumn(),
    __metadata("design:type", Date)
], ActivityComment.prototype, "createdAt", void 0);
__decorate([
    ManyToOne(() => Activity, (activity) => activity.comments, { onDelete: 'CASCADE' }),
    JoinColumn({ name: 'activityId' }),
    __metadata("design:type", Object)
], ActivityComment.prototype, "activity", void 0);
__decorate([
    ManyToOne(() => User, (user) => user.activityComments, { onDelete: 'CASCADE' }),
    JoinColumn({ name: 'userId' }),
    __metadata("design:type", Object)
], ActivityComment.prototype, "user", void 0);
ActivityComment = __decorate([
    Entity('activity_comments')
], ActivityComment);
export { ActivityComment };
