import { IsNull } from 'typeorm';
import { AppDataSource } from '../data-source.js';
import { Category } from '../entities/index.js';

const DEFAULT_CATEGORIES = [
    { name: 'restaurant', icon: 'fork.knife', color: '#EA580C' },
    { name: 'cafe', icon: 'cup.and.saucer.fill', color: '#A16207' },
    { name: 'bar', icon: 'wineglass.fill', color: '#9333EA' },
    { name: 'hotel', icon: 'bed.double.fill', color: '#2563EB' },
    { name: 'museum', icon: 'building.columns.fill', color: '#7C3AED' },
    { name: 'park', icon: 'leaf.fill', color: '#16A34A' },
    { name: 'beach', icon: 'beach.umbrella.fill', color: '#06B6D4' },
    { name: 'airport', icon: 'airplane', color: '#475569' },
    { name: 'shopping', icon: 'bag.fill', color: '#DB2777' },
    { name: 'nightlife', icon: 'moon.stars.fill', color: '#4F46E5' },
    { name: 'landmark', icon: 'mappin.circle.fill', color: '#E11D48' },
    { name: 'sports', icon: 'figure.run', color: '#059669' },
    { name: 'entertainment', icon: 'theatermasks.fill', color: '#D97706' },
    { name: 'transport', icon: 'tram.fill', color: '#0D9488' },
    { name: 'health', icon: 'cross.case.fill', color: '#EF4444' },
    { name: 'education', icon: 'graduationcap.fill', color: '#3B82F6' },
    { name: 'worship', icon: 'building.fill', color: '#A8A29E' },
    { name: 'other', icon: 'mappin', color: '#6B7280' },
];

export async function seedDefaultCategories(): Promise<void> {
    const categoryRepo = AppDataSource.getRepository(Category);

    const existingCount = await categoryRepo.count({
        where: { isDefault: true, travelId: IsNull() },
    });

    if (existingCount >= DEFAULT_CATEGORIES.length) {
        console.log(`Default categories already seeded (${existingCount} found)`);
        return;
    }

    let seeded = 0;
    for (const cat of DEFAULT_CATEGORIES) {
        const exists = await categoryRepo.findOne({
            where: { name: cat.name, isDefault: true },
        });

        if (!exists) {
            const category = categoryRepo.create({
                name: cat.name,
                icon: cat.icon,
                color: cat.color,
                isDefault: true,
                travelId: null,
                createdById: null,
            });
            await categoryRepo.save(category);
            seeded++;
        }
    }

    console.log(`Seeded ${seeded} default categories`);
}
