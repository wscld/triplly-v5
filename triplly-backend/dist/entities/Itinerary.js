var __decorate = (this && this.__decorate) || function (decorators, target, key, desc) {
    var c = arguments.length, r = c < 3 ? target : desc === null ? desc = Object.getOwnPropertyDescriptor(target, key) : desc, d;
    if (typeof Reflect === "object" && typeof Reflect.decorate === "function") r = Reflect.decorate(decorators, target, key, desc);
    else for (var i = decorators.length - 1; i >= 0; i--) if (d = decorators[i]) r = (c < 3 ? d(r) : c > 3 ? d(target, key, r) : d(target, key)) || r;
    return c > 3 && r && Object.defineProperty(target, key, r), r;
};
var __metadata = (this && this.__metadata) || function (k, v) {
    if (typeof Reflect === "object" && typeof Reflect.metadata === "function") return Reflect.metadata(k, v);
};
import { Entity, PrimaryGeneratedColumn, Column, ManyToOne, OneToMany, JoinColumn, } from 'typeorm';
import { Travel } from './Travel.js';
import { Activity } from './Activity.js';
let Itinerary = class Itinerary {
    id;
    travelId;
    date;
    title;
    orderIndex;
    travel;
    activities;
};
__decorate([
    PrimaryGeneratedColumn('uuid'),
    __metadata("design:type", String)
], Itinerary.prototype, "id", void 0);
__decorate([
    Column('uuid'),
    __metadata("design:type", String)
], Itinerary.prototype, "travelId", void 0);
__decorate([
    Column({ type: 'date', nullable: true }),
    __metadata("design:type", Object)
], Itinerary.prototype, "date", void 0);
__decorate([
    Column('varchar'),
    __metadata("design:type", String)
], Itinerary.prototype, "title", void 0);
__decorate([
    Column({ type: 'float', default: 0 }),
    __metadata("design:type", Number)
], Itinerary.prototype, "orderIndex", void 0);
__decorate([
    ManyToOne(() => Travel, (travel) => travel.itineraries, { onDelete: 'CASCADE' }),
    JoinColumn({ name: 'travelId' }),
    __metadata("design:type", Travel)
], Itinerary.prototype, "travel", void 0);
__decorate([
    OneToMany(() => Activity, (activity) => activity.itinerary),
    __metadata("design:type", Array)
], Itinerary.prototype, "activities", void 0);
Itinerary = __decorate([
    Entity('itineraries')
], Itinerary);
export { Itinerary };
