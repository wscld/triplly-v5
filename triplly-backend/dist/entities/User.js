var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, OneToMany, } from 'typeorm';
import { TravelMember } from './TravelMember.js';
import { ActivityComment } from './ActivityComment.js';
let User = class User {
    id;
    email;
    passwordHash;
    name;
    profilePhotoUrl;
    createdAt;
    memberships;
    activityComments;
};
__decorate([
    PrimaryGeneratedColumn('uuid'),
    __metadata("design:type", String)
], User.prototype, "id", void 0);
__decorate([
    Column('varchar', { unique: true }),
    __metadata("design:type", String)
], User.prototype, "email", void 0);
__decorate([
    Column('varchar'),
    __metadata("design:type", String)
], User.prototype, "passwordHash", void 0);
__decorate([
    Column('varchar'),
    __metadata("design:type", String)
], User.prototype, "name", void 0);
__decorate([
    Column('varchar', { nullable: true }),
    __metadata("design:type", Object)
], User.prototype, "profilePhotoUrl", void 0);
__decorate([
    CreateDateColumn(),
    __metadata("design:type", Date)
], User.prototype, "createdAt", void 0);
__decorate([
    OneToMany(() => TravelMember, (member) => member.user),
    __metadata("design:type", Array)
], User.prototype, "memberships", void 0);
__decorate([
    OneToMany(() => ActivityComment, (comment) => comment.user),
    __metadata("design:type", Array)
], User.prototype, "activityComments", void 0);
User = __decorate([
    Entity('users')
], User);
export { User };
