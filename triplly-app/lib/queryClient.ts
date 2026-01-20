import { QueryClient, QueryCache, MutationCache } from '@tanstack/react-query';

let showErrorToast: ((message: string) => void) | null = null;

export const registerToastError = (fn: (message: string) => void) => {
    showErrorToast = fn;
};

const handleError = (error: unknown) => {
    if (showErrorToast) {
        const message = error instanceof Error ? error.message : 'An unknown error occurred';
        showErrorToast(message);
    }
};

export const queryClient = new QueryClient({
    queryCache: new QueryCache({
        onError: handleError,
    }),
    mutationCache: new MutationCache({
        onError: handleError,
    }),
    defaultOptions: {
        queries: {
            staleTime: 1000 * 60 * 5, // 5 minutes
            retry: 1,
        },
    },
});
