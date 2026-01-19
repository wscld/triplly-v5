const EARTH_RADIUS_KM = 6371;

function toRadians(degrees: number): number {
    return degrees * (Math.PI / 180);
}

/**
 * Calculate distance between two points using Haversine formula
 * @returns Distance in kilometers
 */
export function haversineDistance(
    lat1: number,
    lon1: number,
    lat2: number,
    lon2: number
): number {
    const dLat = toRadians(lat2 - lat1);
    const dLon = toRadians(lon2 - lon1);

    const a =
        Math.sin(dLat / 2) ** 2 +
        Math.cos(toRadians(lat1)) *
        Math.cos(toRadians(lat2)) *
        Math.sin(dLon / 2) ** 2;

    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));

    return EARTH_RADIUS_KM * c;
}

interface Coordinate {
    latitude: number;
    longitude: number;
}

/**
 * Calculate distances between consecutive coordinates and total
 */
export function calculateDistances(coordinates: Coordinate[]): {
    segmentDistances: number[];
    totalDistance: number;
} {
    const segmentDistances: number[] = [];
    let totalDistance = 0;

    for (let i = 1; i < coordinates.length; i++) {
        const prev = coordinates[i - 1];
        const curr = coordinates[i];
        const distance = haversineDistance(
            prev.latitude,
            prev.longitude,
            curr.latitude,
            curr.longitude
        );
        segmentDistances.push(distance);
        totalDistance += distance;
    }

    return { segmentDistances, totalDistance };
}

/**
 * Format distance for display
 */
export function formatDistance(km: number): string {
    if (km < 1) {
        return `${Math.round(km * 1000)} m`;
    }
    return `${km.toFixed(1)} km`;
}

/**
 * Format date for display
 */
export function formatDate(dateString: string | null): string {
    if (!dateString) return '';
    const date = new Date(dateString);
    return date.toLocaleDateString('en-US', {
        weekday: 'short',
        month: 'short',
        day: 'numeric',
    });
}

/**
 * Format date range for display
 */
export function formatDateRange(start: string | null, end: string | null): string {
    if (!start) return '';
    if (!end) return formatDate(start);

    const startDate = new Date(start);
    const endDate = new Date(end);

    const sameMonth = startDate.getMonth() === endDate.getMonth();
    const sameYear = startDate.getFullYear() === endDate.getFullYear();

    if (sameMonth && sameYear) {
        return `${startDate.toLocaleDateString('en-US', { month: 'short', day: 'numeric' })} - ${endDate.getDate()}, ${endDate.getFullYear()}`;
    }

    return `${formatDate(start)} - ${formatDate(end)}`;
}
