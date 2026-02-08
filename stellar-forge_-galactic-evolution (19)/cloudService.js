import { Capacitor } from '@capacitor/core';
import { Preferences } from '@capacitor/preferences';

export class CloudService {
    static get isAvailable() {
        return Capacitor.getPlatform() === 'android';
    }

    // Access the new 'GameConnect' plugin via the global proxy
    static get GameConnect() {
        return Capacitor.Plugins.GameConnect;
    }

    static async isAuthenticated() {
        // The GameConnect plugin is primarily for sign-in.
        // We assume false and require an explicit login call.
        return false;
    }

    static async login() {
        if (!this.isAvailable) {
            console.warn("Cloud features are only available on Android.");
            return false;
        }
        try {
            console.log("Signing into Google Play Games via GameConnect...");
            
            if (this.GameConnect) {
                // The new plugin uses 'signIn'
                await this.GameConnect.signIn();
                return true;
            } else {
                console.error("GameConnect plugin not found. Ensure @openforge/capacitor-game-connect is installed and synced.");
                return false;
            }
        } catch (e) {
            console.error("Login Failed", e);
            return false;
        }
    }

    static async saveGame(gameState, description = "Stellar Forge Auto-Save") {
        try {
            console.log("Saving Game Data...");
            const jsonString = JSON.stringify(gameState);
            
            // We use Capacitor Preferences for data storage.
            // On Android, this specific storage is automatically backed up to the user's Google Drive
            // if they have 'Back up my data' enabled in Android Settings.
            await Preferences.set({
                key: 'stellar_forge_save_v1',
                value: jsonString
            });

            console.log("Save Complete");
            return true;
        } catch (e) {
            console.error("Save Failed", e);
            throw e;
        }
    }

    static async loadGame() {
        try {
            console.log("Loading Game Data...");
            const { value } = await Preferences.get({ key: 'stellar_forge_save_v1' });
            
            if (value) {
                console.log("Load Successful");
                return JSON.parse(value);
            }
            return null;
        } catch (e) {
            console.error("Load Failed", e);
            throw e;
        }
    }

    static async unlockAchievement(achievementId) {
        if (!this.isAvailable) return;
        try {
            if (this.GameConnect) {
                // Assuming standard API for achievements in GameConnect
                await this.GameConnect.unlockAchievement({
                    achievementId: achievementId
                });
                console.log(`Achievement ${achievementId} unlock requested`);
            }
        } catch (e) {
            console.warn("Achievement Unlock Failed", e);
        }
    }
}