import React, { createContext, useContext, useEffect, useState, useCallback } from 'react';
import { api } from './api';
import type { User } from './types';

interface AuthState {
    user: User | null;
    isLoading: boolean;
    isAuthenticated: boolean;
}

interface AuthContextValue extends AuthState {
    login: (email: string, password: string) => Promise<void>;
    register: (email: string, password: string, name: string) => Promise<void>;
    logout: () => Promise<void>;
}

const AuthContext = createContext<AuthContextValue | null>(null);

export function AuthProvider({ children }: { children: React.ReactNode }) {
    const [state, setState] = useState<AuthState>({
        user: null,
        isLoading: true,
        isAuthenticated: false,
    });

    useEffect(() => {
        // Initialize API and check auth status
        api.init().then(async () => {
            try {
                const user = await api.getMe();
                setState({ user, isLoading: false, isAuthenticated: true });
            } catch {
                setState({ user: null, isLoading: false, isAuthenticated: false });
            }
        });
    }, []);

    const login = useCallback(async (email: string, password: string) => {
        const { user } = await api.login(email, password);
        setState({ user, isLoading: false, isAuthenticated: true });
    }, []);

    const register = useCallback(async (email: string, password: string, name: string) => {
        const { user } = await api.register(email, password, name);
        setState({ user, isLoading: false, isAuthenticated: true });
    }, []);

    const logout = useCallback(async () => {
        await api.logout();
        setState({ user: null, isLoading: false, isAuthenticated: false });
    }, []);

    return (
        <AuthContext.Provider value={{ ...state, login, register, logout }}>
            {children}
        </AuthContext.Provider>
    );
}

export function useAuth() {
    const context = useContext(AuthContext);
    if (!context) {
        throw new Error('useAuth must be used within AuthProvider');
    }
    return context;
}
