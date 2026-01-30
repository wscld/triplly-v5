import { AppDataSource } from '../data-source.js';
import { Place } from '../entities/index.js';

interface FindOrCreatePlaceParams {
    name: string;
    latitude: number;
    longitude: number;
    address?: string | null;
    externalId?: string | null;
    provider?: string | null;
}

/**
 * Find an existing place or create a new one.
 *
 * Strategy 1: If externalId + provider provided, deduplicate by exact match.
 * Strategy 2: Fallback to name + lat/lng proximity (~100m / 0.001 degrees).
 * If no match, create a new Place.
 */
export async function findOrCreatePlace(params: FindOrCreatePlaceParams): Promise<Place> {
    const placeRepo = AppDataSource.getRepository(Place);

    // Strategy 1: Exact match on externalId + provider
    if (params.externalId && params.provider) {
        const existing = await placeRepo.findOne({
            where: {
                externalId: params.externalId,
                provider: params.provider,
            },
        });
        if (existing) {
            return existing;
        }
    }

    // Strategy 2: Name + lat/lng proximity (~100m = ~0.001 degrees)
    const proximity = 0.001;
    const nearby = await placeRepo
        .createQueryBuilder('place')
        .where('place.name = :name', { name: params.name })
        .andWhere('ABS(place.latitude - :lat) < :proximity', { lat: params.latitude, proximity })
        .andWhere('ABS(place.longitude - :lng) < :proximity', { lng: params.longitude, proximity })
        .getOne();

    if (nearby) {
        return nearby;
    }

    // Create new place
    const place = placeRepo.create({
        name: params.name,
        latitude: params.latitude,
        longitude: params.longitude,
        address: params.address ?? null,
        externalId: params.externalId ?? null,
        provider: params.provider ?? null,
    });
    await placeRepo.save(place);

    return place;
}
