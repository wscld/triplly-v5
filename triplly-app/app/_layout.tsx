import { DefaultTheme, ThemeProvider } from '@react-navigation/native';
import { Stack } from 'expo-router';
import { QueryClientProvider } from '@tanstack/react-query';
import 'react-native-reanimated';
import { GluestackUIProvider } from '@gluestack-ui/themed';
import { config } from '../gluestack-ui.config';

import { AuthProvider } from '@/lib/auth';
import { queryClient } from '@/lib/queryClient';
import ToastConfig from '@/components/ToastConfig';

export default function RootLayout() {
  return (
    <GluestackUIProvider config={config}>
      <QueryClientProvider client={queryClient}>
        <ToastConfig />
        <AuthProvider>
          <ThemeProvider value={DefaultTheme}>
            <Stack screenOptions={{ headerShown: false }}>
              <Stack.Screen name="(auth)" />
              <Stack.Screen name="(app)" />
            </Stack>
          </ThemeProvider>
        </AuthProvider>
      </QueryClientProvider>
    </GluestackUIProvider>
  );
}
