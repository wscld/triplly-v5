import { useEffect } from 'react';
import { useToast, Toast, ToastTitle, ToastDescription, VStack } from '@gluestack-ui/themed';
import { registerToastError } from '@/lib/queryClient';
import { Ionicons } from '@expo/vector-icons';
import { Colors } from '@/constants/colors';

export default function ToastConfig() {
    const toast = useToast();

    useEffect(() => {
        registerToastError((message) => {
            toast.show({
                placement: "top",
                render: ({ id }) => {
                    return (
                        <Toast nativeID={'toast-' + id} action="error" variant="outline" style={{
                            backgroundColor: '#FFE5E5',
                            borderColor: Colors.error,
                            borderWidth: 1,
                            borderRadius: 12,
                            padding: 16,
                            shadowColor: '#000',
                            shadowOffset: { width: 0, height: 2 },
                            shadowOpacity: 0.1,
                            shadowRadius: 8,
                            elevation: 4,
                            marginTop: 40, // Top safe area
                            flexDirection: 'row',
                            alignItems: 'center',
                            gap: 12,
                            maxWidth: '90%',
                            alignSelf: 'center',
                        }}>
                            <Ionicons name="alert-circle" size={24} color={Colors.error} />
                            <VStack space="xs" style={{ flex: 1 }}>
                                <ToastTitle color={Colors.text.primary} fontWeight="$bold">Erro</ToastTitle>
                                <ToastDescription color={Colors.text.secondary}>
                                    {message}
                                </ToastDescription>
                            </VStack>
                        </Toast>
                    )
                },
            });
        });
    }, [toast]);

    return null;
}
