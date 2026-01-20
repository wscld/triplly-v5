import React, { useState, useMemo, useRef, useCallback } from 'react';
import { View, TouchableOpacity, Text, StyleSheet } from 'react-native';
import { BottomSheetModal, BottomSheetView, BottomSheetBackdrop } from '@gorhom/bottom-sheet';
import { Calendar, DateData } from 'react-native-calendars';
import { Ionicons } from '@expo/vector-icons';
import { Colors } from '@/constants/colors';
import { format, isBefore, eachDayOfInterval } from 'date-fns';

interface Props {
    startDate: Date | null;
    endDate: Date | null;
    onChange: (range: { startDate: Date | null; endDate: Date | null }) => void;
    label?: string;
}

export default function DateRangePicker({ startDate, endDate, onChange, label = "DATES" }: Props) {
    const bottomSheetModalRef = useRef<BottomSheetModal>(null);

    const openSheet = () => {
        bottomSheetModalRef.current?.present();
    };

    const closeSheet = () => {
        bottomSheetModalRef.current?.dismiss();
    };

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

    // Marking state based on props
    const markedDates = useMemo(() => {
        const marks: any = {};
        if (!startDate) return marks;

        const startStr = format(startDate, 'yyyy-MM-dd');
        marks[startStr] = { startingDay: true, color: Colors.primary, textColor: 'white' };

        if (endDate) {
            const endStr = format(endDate, 'yyyy-MM-dd');
            marks[endStr] = { endingDay: true, color: Colors.primary, textColor: 'white' };

            // Fill in between
            if (isBefore(startDate, endDate)) {
                const range = eachDayOfInterval({ start: startDate, end: endDate });
                range.forEach(date => {
                    const str = format(date, 'yyyy-MM-dd');
                    if (str !== startStr && str !== endStr) {
                        marks[str] = { color: '#E5E5EA', textColor: 'black' };
                    }
                });
            }
        } else {
            marks[startStr] = { startingDay: true, endingDay: true, color: Colors.primary, textColor: 'white' };
        }
        return marks;
    }, [startDate, endDate]);

    const handleDayPress = (day: DateData) => {
        const date = new Date(day.dateString + 'T00:00:00');

        if (!startDate || (startDate && endDate)) {
            // Start new range
            onChange({ startDate: date, endDate: null });
        } else if (startDate && !endDate) {
            // Complete range
            if (isBefore(date, startDate)) {
                onChange({ startDate: date, endDate: null });
            } else {
                onChange({ startDate, endDate: date });
            }
        }
    };

    const displayText = useMemo(() => {
        if (!startDate) return 'Select dates';
        if (!endDate) return format(startDate, 'dd/MM/yyyy') + ' - ...';
        return `${format(startDate, 'dd/MM/yyyy')} - ${format(endDate, 'dd/MM/yyyy')}`;
    }, [startDate, endDate]);

    return (
        <View style={styles.container}>
            <Text style={styles.label}>{label}</Text>
            <TouchableOpacity onPress={openSheet}>
                <View style={styles.inputTrigger}>
                    <Text style={[styles.inputText, !startDate && styles.inputPlaceholder]}>
                        {displayText}
                    </Text>
                    <Ionicons name="calendar-outline" size={20} color="#666" />
                </View>
            </TouchableOpacity>

            <BottomSheetModal
                ref={bottomSheetModalRef}
                enableDynamicSizing
                enablePanDownToClose
                stackBehavior="push"
                backdropComponent={renderBackdrop}
                handleIndicatorStyle={styles.handle}
                backgroundStyle={styles.background}
            >
                <BottomSheetView style={styles.sheetContent}>
                    <View style={styles.modalHeader}>
                        <Text style={styles.modalTitle}>Select Travel Dates</Text>
                        <TouchableOpacity onPress={closeSheet}>
                            <Ionicons name="close" size={24} color={Colors.black} />
                        </TouchableOpacity>
                    </View>

                    <Calendar
                        markingType={'period'}
                        markedDates={markedDates}
                        onDayPress={handleDayPress}
                        theme={{
                            todayTextColor: Colors.primary,
                            arrowColor: Colors.primary,
                            selectedDayBackgroundColor: Colors.primary,
                            selectedDayTextColor: 'white',
                        }}
                    />

                    <TouchableOpacity
                        style={styles.confirmButton}
                        onPress={closeSheet}
                    >
                        <Text style={styles.confirmButtonText}>Confirm</Text>
                    </TouchableOpacity>
                </BottomSheetView>
            </BottomSheetModal>
        </View>
    );
}

const styles = StyleSheet.create({
    container: {
        gap: 4,
    },
    label: {
        fontSize: 12,
        fontWeight: '500',
        color: Colors.text.secondary,
        textTransform: 'uppercase',
    },
    inputTrigger: {
        borderWidth: 1,
        borderColor: '#E5E5E5',
        borderRadius: 4,
        paddingHorizontal: 12,
        paddingVertical: 10,
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        backgroundColor: '#fff',
    },
    inputText: {
        fontSize: 16,
        color: Colors.text.primary,
    },
    inputPlaceholder: {
        color: Colors.text.secondary,
    },
    handle: {
        backgroundColor: '#D1D1D6',
        width: 36,
    },
    background: {
        backgroundColor: '#fff',
    },
    sheetContent: {
        padding: 20,
        paddingBottom: 40,
    },
    modalHeader: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: 20,
    },
    modalTitle: {
        fontSize: 18,
        fontWeight: '600',
    },
    confirmButton: {
        backgroundColor: Colors.primary,
        padding: 16,
        borderRadius: 12,
        alignItems: 'center',
        marginTop: 20,
    },
    confirmButtonText: {
        color: 'black',
        fontWeight: '600',
        fontSize: 16,
    }
});
