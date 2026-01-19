import React from 'react';
import {
    Actionsheet,
    ActionsheetBackdrop,
    ActionsheetContent,
    ActionsheetDragIndicator,
    ActionsheetDragIndicatorWrapper,
    Box,
    VStack,
    Text,
    Button,
    ButtonText,
    HStack,
} from '@gluestack-ui/themed';
import { KeyboardAvoidingView, Platform } from 'react-native';

interface Props {
    isOpen: boolean;
    onClose: () => void;
    title: string;
    children: React.ReactNode;
    onSubmit?: () => void;
    submitLabel?: string;
    isSubmitting?: boolean;
}

export default function SheetForm({
    isOpen,
    onClose,
    title,
    children,
    onSubmit,
    submitLabel = 'Save',
    isSubmitting = false,
}: Props) {
    return (
        <Actionsheet isOpen={isOpen} onClose={onClose} zIndex={999}>
            <ActionsheetBackdrop />
            <ActionsheetContent zIndex={999}>
                <ActionsheetDragIndicatorWrapper>
                    <ActionsheetDragIndicator />
                </ActionsheetDragIndicatorWrapper>

                <KeyboardAvoidingView
                    behavior={Platform.OS === "ios" ? "padding" : undefined}
                    style={{ width: '100%' }}
                >
                    <VStack space="md" w="$full" p="$4" pb="$8">
                        <HStack justifyContent="space-between" alignItems="center" mb="$2">
                            <Text size="xl" bold>{title}</Text>
                            {onSubmit && (
                                <Button
                                    size="sm"
                                    variant="link"
                                    onPress={onSubmit}
                                    isDisabled={isSubmitting}
                                >
                                    <ButtonText fontWeight="$bold">{submitLabel}</ButtonText>
                                </Button>
                            )}
                        </HStack>

                        <Box>
                            {children}
                        </Box>
                    </VStack>
                </KeyboardAvoidingView>
            </ActionsheetContent>
        </Actionsheet>
    );
}
