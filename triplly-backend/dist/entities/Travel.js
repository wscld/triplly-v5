var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
import { Entity, PrimaryGeneratedColumn, Column, CreateDateColumn, ManyToOne, OneToMany, JoinColumn, } from 'typeorm';
let Travel = class Travel {
    id;
    title;
    description;
    startDate;
    endDate;
    coverImageUrl;
    latitude;
    longitude;
    createdAt;
    ownerId;
    owner;
    members;
    itineraries;
    todos;
};
__decorate([
    PrimaryGeneratedColumn('uuid'),
    __metadata("design:type", String)
], Travel.prototype, "id", void 0);
__decorate([
    Column('varchar'),
    __metadata("design:type", String)
], Travel.prototype, "title", void 0);
__decorate([
    Column({ type: 'text', nullable: true }),
    __metadata("design:type", Object)
], Travel.prototype, "description", void 0);
__decorate([
    Column({ type: 'date', nullable: true }),
    __metadata("design:type", Object)
], Travel.prototype, "startDate", void 0);
__decorate([
    Column({ type: 'date', nullable: true }),
    __metadata("design:type", Object)
], Travel.prototype, "endDate", void 0);
__decorate([
    Column('varchar', { nullable: true }),
    __metadata("design:type", Object)
], Travel.prototype, "coverImageUrl", void 0);
__decorate([
    Column({ type: 'decimal', precision: 10, scale: 7, nullable: true }),
    __metadata("design:type", Object)
], Travel.prototype, "latitude", void 0);
__decorate([
    Column({ type: 'decimal', precision: 10, scale: 7, nullable: true }),
    __metadata("design:type", Object)
], Travel.prototype, "longitude", void 0);
__decorate([
    CreateDateColumn(),
    __metadata("design:type", Date)
], Travel.prototype, "createdAt", void 0);
__decorate([
    Column('uuid'),
    __metadata("design:type", String)
], Travel.prototype, "ownerId", void 0);
__decorate([
    ManyToOne("User"),
    JoinColumn({ name: 'ownerId' }),
    __metadata("design:type", Object)
], Travel.prototype, "owner", void 0);
__decorate([
    OneToMany("TravelMember", (member) => member.travel),
    __metadata("design:type", Array)
], Travel.prototype, "members", void 0);
__decorate([
    OneToMany("Itinerary", (itinerary) => itinerary.travel),
    __metadata("design:type", Array)
], Travel.prototype, "itineraries", void 0);
__decorate([
    OneToMany("Todo", (todo) => todo.travel),
    __metadata("design:type", Array)
], Travel.prototype, "todos", void 0);
Travel = __decorate([
    Entity('travels')
], Travel);
export { Travel };
