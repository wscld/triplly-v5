interface NominatimResult {
    place_id: number;
    display_name: string;
    lat: string;
    lon: string;
}

export interface PlaceSearchResult {
    name: string;
    address: string;
    latitude: number;
    longitude: number;
    externalId: string;
    provider: string;
}

export async function searchPlaces(query: string, limit = 10): Promise<PlaceSearchResult[]> {
    const url = `https://nominatim.openstreetmap.org/search?q=${encodeURIComponent(query)}&format=json&limit=${limit}`;

    const response = await fetch(url, {
        headers: {
            'User-Agent': 'Triplly/1.0',
        },
    });

    if (!response.ok) {
        throw new Error(`Nominatim search failed: ${response.status}`);
    }

    const results: NominatimResult[] = await response.json();

    return results.map((r) => ({
        name: r.display_name.split(',')[0]?.trim() ?? r.display_name,
        address: r.display_name,
        latitude: parseFloat(r.lat),
        longitude: parseFloat(r.lon),
        externalId: String(r.place_id),
        provider: 'nominatim',
    }));
}
