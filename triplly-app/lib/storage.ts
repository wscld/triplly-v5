import * as SecureStore from 'expo-secure-store';
import { Platform } from 'react-native';

const TOKEN_KEY = 'auth_token';

/**
 * Platform-agnostic token storage
 * Native: Uses Expo SecureStore
 * Web: Uses localStorage
 */
export const tokenStorage = {
    async getItem(): Promise<string | null> {
        if (Platform.OS === 'web') {
            try {
                if (typeof localStorage !== 'undefined') {
                    return localStorage.getItem(TOKEN_KEY);
                }
            } catch (e) {
                console.warn('LocalStorage unavailable', e);
            }
            return null;
        }
        return SecureStore.getItemAsync(TOKEN_KEY);
    },

    async setItem(value: string): Promise<void> {
        if (Platform.OS === 'web') {
            try {
                if (typeof localStorage !== 'undefined') {
                    localStorage.setItem(TOKEN_KEY, value);
                }
            } catch (e) {
                console.warn('LocalStorage unavailable', e);
            }
            return;
        }
        return SecureStore.setItemAsync(TOKEN_KEY, value);
    },

    async removeItem(): Promise<void> {
        if (Platform.OS === 'web') {
            try {
                if (typeof localStorage !== 'undefined') {
                    localStorage.removeItem(TOKEN_KEY);
                }
            } catch (e) {
                console.warn('LocalStorage unavailable', e);
            }
            return;
        }
        return SecureStore.deleteItemAsync(TOKEN_KEY);
    },
};
