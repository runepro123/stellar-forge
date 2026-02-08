
export const MODIO_CONFIG = {
    API_KEY: '2506d4a46de11cceeb4690a7de9deebb',
    GAME_ID: '12018',
    BASE_URL: 'https://api.mod.io/v1'
};

export class ModIOService {
    static async getMods() {
        try {
            const response = await fetch(`${MODIO_CONFIG.BASE_URL}/games/${MODIO_CONFIG.GAME_ID}/mods?api_key=${MODIO_CONFIG.API_KEY}&_sort=-date_added`, {
                method: 'GET',
                headers: {
                    'Accept': 'application/json',
                }
            });
            
            if (!response.ok) throw new Error('Failed to fetch mods');
            return await response.json();
        } catch (error) {
            console.error("Mod.io Error:", error);
            return { data: [] };
        }
    }

    static async downloadModFile(fileUrl) {
        try {
            // NOTE: mod.io download links are usually redirects to S3/CDN.
            // We fetch the content directly. For this game, we expect the mod file to be a JSON text file.
            // If the user uploads a ZIP, this text parsing will fail, but for simple mods JSON is best.
            const response = await fetch(fileUrl);
            if (!response.ok) throw new Error('Download failed');
            return await response.json();
        } catch (error) {
            console.error("Download Error:", error);
            throw error;
        }
    }
}
