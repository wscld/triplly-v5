import { createClient } from '@supabase/supabase-js';

const supabaseUrl = process.env.SUPABASE_URL;
const supabaseKey = process.env.SUPABASE_KEY;

let supabase: ReturnType<typeof createClient> | null = null;

if (supabaseUrl && supabaseKey) {
    supabase = createClient(supabaseUrl, supabaseKey);
} else {
    console.warn('Missing SUPABASE_URL or SUPABASE_KEY env vars');
}

export async function uploadImage(file: Blob, path: string): Promise<string | null> {
    if (!supabase) {
        throw new Error('Supabase not configured');
    }

    const { error } = await supabase.storage
        .from('travel-covers')
        .upload(path, file, {
            contentType: file.type || 'image/jpeg',
            upsert: true
        });

    if (error) {
        console.error('Supabase upload error:', error);
        throw error;
    }

    const { data } = supabase.storage
        .from('travel-covers')
        .getPublicUrl(path);

    return data.publicUrl;
}
