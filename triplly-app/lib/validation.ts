export function isValidEmail(email: string): boolean {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    return emailRegex.test(email.trim());
}

export interface PasswordValidation {
    valid: boolean;
    error?: string;
}

export function isValidPassword(password: string): PasswordValidation {
    if (password.length < 6) {
        return { valid: false, error: 'Password must be at least 6 characters' };
    }
    return { valid: true };
}

export function getEmailError(email: string): string | null {
    if (!email.trim()) {
        return null;
    }
    if (!isValidEmail(email)) {
        return 'Please enter a valid email address';
    }
    return null;
}

export function getPasswordError(password: string): string | null {
    if (!password) {
        return null;
    }
    const validation = isValidPassword(password);
    return validation.error ?? null;
}
