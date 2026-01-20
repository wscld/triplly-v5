import React, { useRef, useEffect, useCallback } from 'react';
import { View, TouchableOpacity, Text, StyleSheet } from 'react-native';
import { BottomSheetModal, BottomSheetScrollView, BottomSheetBackdrop } from '@gorhom/bottom-sheet';
import { Colors } from '@/constants/colors';

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
    const bottomSheetModalRef = useRef<BottomSheetModal>(null);

    useEffect(() => {
        if (isOpen) {
            bottomSheetModalRef.current?.present();
        } else {
            bottomSheetModalRef.current?.dismiss();
        }
    }, [isOpen]);

    const handleSheetChanges = useCallback((index: number) => {
        if (index === -1) {
            onClose();
        }
    }, [onClose]);

    const renderBackdrop = useCallback(
        (props: any) => (
            <BottomSheetBackdrop
                {...props}
                disappearsOnIndex={-1}
                appearsOnIndex={0}
                opacity={0.5}
            />
        ),
        []
    );

    return (
        <BottomSheetModal
            ref={bottomSheetModalRef}
            onChange={handleSheetChanges}
            snapPoints={['50%', '90%']}
            enablePanDownToClose
            backdropComponent={renderBackdrop}
            handleIndicatorStyle={styles.handle}
            backgroundStyle={styles.background}
            keyboardBehavior="extend"
            keyboardBlurBehavior="restore"
            android_keyboardInputMode="adjustResize"
        >
            <BottomSheetScrollView
                style={styles.scrollView}
                contentContainerStyle={styles.contentContainer}
            >
                <View style={styles.header}>
                    <Text style={styles.title}>{title}</Text>
                    {onSubmit && (
                        <TouchableOpacity
                            onPress={onSubmit}
                            disabled={isSubmitting}
                            style={styles.submitButton}
                        >
                            <Text style={[
                                styles.submitText,
                                isSubmitting && styles.submitTextDisabled
                            ]}>
                                {submitLabel}
                            </Text>
                        </TouchableOpacity>
                    )}
                </View>
                <View style={styles.body}>
                    {children}
                </View>
            </BottomSheetScrollView>
        </BottomSheetModal>
    );
}

const styles = StyleSheet.create({
    scrollView: {
        flex: 1,
    },
    contentContainer: {
        paddingHorizontal: 16,
        paddingBottom: 32,
    },
    handle: {
        backgroundColor: '#D1D1D6',
        width: 36,
    },
    background: {
        backgroundColor: '#fff',
    },
    header: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        paddingVertical: 8,
        marginBottom: 8,
    },
    title: {
        fontSize: 20,
        fontWeight: '700',
        color: Colors.text.primary,
    },
    submitButton: {
        paddingHorizontal: 4,
        paddingVertical: 4,
    },
    submitText: {
        fontSize: 16,
        fontWeight: '600',
        color: Colors.primary,
    },
    submitTextDisabled: {
        opacity: 0.5,
    },
    body: {
        marginTop: 8,
    },
});
