const UNSPLASH_ACCESS_KEY = process.env.UNSPLASH_ACCESS_KEY;
export async function getPlaceImage(placeName) {
    if (!UNSPLASH_ACCESS_KEY) {
        console.warn('UNSPLASH_ACCESS_KEY not set');
        return null;
    }
    try {
        const query = encodeURIComponent(placeName);
        const response = await fetch(`https://api.unsplash.com/search/photos?query=${query}&per_page=1&orientation=landscape`, {
            headers: {
                'Authorization': `Client-ID ${UNSPLASH_ACCESS_KEY}`,
            },
        });
        if (!response.ok)
            return null;
        const data = await response.json();
        if (data.results && data.results.length > 0) {
            return data.results[0].urls.regular;
        }
        return null;
    }
    catch (error) {
        console.error('Unsplash fetch failed:', error);
        return null;
    }
}
