import { Redirect, Stack } from 'expo-router';
import { useAuth } from '@/lib/auth';
import { ActivityIndicator, View } from 'react-native';

export default function AppLayout() {
    const { isAuthenticated, isLoading } = useAuth();

    if (isLoading) {
        return (
            <View style={{ flex: 1, justifyContent: 'center', alignItems: 'center' }}>
                <ActivityIndicator size="large" color="#007AFF" />
            </View>
        );
    }

    if (!isAuthenticated) {
        return <Redirect href="/(auth)/login" />;
    }

    return (
        <Stack>
            <Stack.Screen name="(tabs)" options={{ headerShown: false }} />
            <Stack.Screen
                name="travel/[id]/index"
                options={{ title: 'Travel', headerBackTitle: 'Back', headerShown: false }}
            />
            <Stack.Screen
                name="travel/[id]/itinerary/[itineraryId]"
                options={{ title: 'Itinerary', headerBackTitle: 'Back', headerShown: false }}
            />
            <Stack.Screen
                name="travel/[id]/itinerary/[itineraryId]/activity/[activityId]"
                options={{ title: 'Activity', headerBackTitle: 'Back', headerShown: false }}
            />
            <Stack.Screen
                name="travel/new"
                options={{ title: 'New Travel', presentation: 'modal' }}
            />
        </Stack>
    );
}
