var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, JoinColumn, CreateDateColumn, OneToMany, } from 'typeorm';
let Activity = class Activity {
    id;
    travelId;
    itineraryId;
    title;
    description;
    orderIndex;
    latitude;
    longitude;
    googlePlaceId;
    address;
    startTime;
    createdAt;
    createdById;
    createdBy;
    travel;
    itinerary;
    comments;
};
__decorate([
    PrimaryGeneratedColumn('uuid'),
    __metadata("design:type", String)
], Activity.prototype, "id", void 0);
__decorate([
    Column('uuid'),
    __metadata("design:type", String)
], Activity.prototype, "travelId", void 0);
__decorate([
    Column('uuid', { nullable: true }),
    __metadata("design:type", Object)
], Activity.prototype, "itineraryId", void 0);
__decorate([
    Column('varchar'),
    __metadata("design:type", String)
], Activity.prototype, "title", void 0);
__decorate([
    Column({ type: 'text', nullable: true }),
    __metadata("design:type", Object)
], Activity.prototype, "description", void 0);
__decorate([
    Column({ type: 'float', default: 0 }),
    __metadata("design:type", Number)
], Activity.prototype, "orderIndex", void 0);
__decorate([
    Column({ type: 'float' }),
    __metadata("design:type", Number)
], Activity.prototype, "latitude", void 0);
__decorate([
    Column({ type: 'float' }),
    __metadata("design:type", Number)
], Activity.prototype, "longitude", void 0);
__decorate([
    Column('varchar', { nullable: true }),
    __metadata("design:type", Object)
], Activity.prototype, "googlePlaceId", void 0);
__decorate([
    Column('varchar', { nullable: true }),
    __metadata("design:type", Object)
], Activity.prototype, "address", void 0);
__decorate([
    Column('varchar', { nullable: true }),
    __metadata("design:type", Object)
], Activity.prototype, "startTime", void 0);
__decorate([
    CreateDateColumn(),
    __metadata("design:type", Date)
], Activity.prototype, "createdAt", void 0);
__decorate([
    Column('uuid', { nullable: true }),
    __metadata("design:type", Object)
], Activity.prototype, "createdById", void 0);
__decorate([
    ManyToOne("User", { nullable: true }),
    JoinColumn({ name: 'createdById' }),
    __metadata("design:type", Object)
], Activity.prototype, "createdBy", void 0);
__decorate([
    ManyToOne("Travel", { onDelete: 'CASCADE' }),
    JoinColumn({ name: 'travelId' }),
    __metadata("design:type", Object)
], Activity.prototype, "travel", void 0);
__decorate([
    ManyToOne("Itinerary", (itinerary) => itinerary.activities, { onDelete: 'CASCADE', nullable: true }),
    JoinColumn({ name: 'itineraryId' }),
    __metadata("design:type", Object)
], Activity.prototype, "itinerary", void 0);
__decorate([
    OneToMany("ActivityComment", (comment) => comment.activity),
    __metadata("design:type", Array)
], Activity.prototype, "comments", void 0);
Activity = __decorate([
    Entity('activities')
], Activity);
export { Activity };
