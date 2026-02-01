import ogs from 'open-graph-scraper';

export interface LinkMetadata {
    url: string;
    title: string | null;
    description: string | null;
    imageUrl: string | null;
}

const URL_REGEX = /https?:\/\/[^\s<>"')\]]+/i;

export function extractFirstUrl(text: string): string | null {
    const match = text.match(URL_REGEX);
    return match ? match[0] : null;
}

export async function fetchLinkMetadata(url: string): Promise<LinkMetadata | null> {
    try {
        const { result } = await ogs({ url, timeout: 5000 });
        return {
            url,
            title: result.ogTitle ?? null,
            description: result.ogDescription ?? null,
            imageUrl: result.ogImage?.[0]?.url ?? null,
        };
    } catch {
        return null;
    }
}
