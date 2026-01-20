import React, { useState } from 'react';
import { View, TouchableOpacity, Platform, Modal, StyleSheet } from 'react-native';
import { Text, VStack, Input, InputField } from '@gluestack-ui/themed';
import DateTimePicker from '@react-native-community/datetimepicker';
import { Ionicons } from '@expo/vector-icons';

interface Props {
    label: string;
    value: Date | null;
    onChange: (date: Date) => void;
    minDate?: Date;
    maxDate?: Date;
}

export default function DatePickerInput({ label, value, onChange, minDate, maxDate }: Props) {
    const [show, setShow] = useState(false);

    const handleChange = (event: any, selectedDate?: Date) => {
        setShow(Platform.OS === 'ios'); // Keep open on iOS if we want, or close. Typically close for Android.
        if (selectedDate) {
            onChange(selectedDate);
            if (Platform.OS === 'android') {
                setShow(false);
            }
        }
    };

    const formatDate = (date: Date | null) => {
        if (!date) return '';
        return date.toISOString().split('T')[0];
    }

    // Web handling
    if (Platform.OS === 'web') {
        return (
            <VStack space="xs">
                <Text size="xs" color="$coolGray500">{label}</Text>
                <Input>
                    <InputField
                        value={formatDate(value)}
                        onChange={(e: any) => {
                            const date = new Date(e.target.value);
                            if (!isNaN(date.getTime())) {
                                onChange(date);
                            }
                        }}
                        placeholder="YYYY-MM-DD"
                    />
                </Input>
            </VStack>
        )
    }

    return (
        <VStack space="xs">
            <Text size="xs" color="$coolGray500">{label}</Text>
            <TouchableOpacity onPress={() => setShow(true)}>
                <View style={styles.inputTrigger}>
                    <Text color={value ? '$textLight900' : '$textLight400'}>
                        {value ? formatDate(value) : 'Select Date'}
                    </Text>
                    <Ionicons name="calendar-outline" size={20} color="#666" />
                </View>
            </TouchableOpacity>

            {show && (
                Platform.OS === 'ios' ? (
                    <Modal transparent animationType="slide" visible={show}>
                        <View style={styles.iosModalOverlay}>
                            <View style={styles.iosModalContent}>
                                <View style={styles.iosHeader}>
                                    <TouchableOpacity onPress={() => setShow(false)}>
                                        <Text color="$blue500" fontWeight="$bold">Done</Text>
                                    </TouchableOpacity>
                                </View>
                                <DateTimePicker
                                    value={value || new Date()}
                                    mode="date"
                                    display="spinner"
                                    onChange={handleChange}
                                    minimumDate={minDate}
                                    maximumDate={maxDate}
                                    textColor="black"
                                />
                            </View>
                        </View>
                    </Modal>
                ) : (
                    <DateTimePicker
                        value={value || new Date()}
                        mode="date"
                        display="default" // Android default
                        onChange={handleChange}
                        minimumDate={minDate}
                        maximumDate={maxDate}
                    />
                )
            )}
        </VStack>
    );
}

const styles = StyleSheet.create({
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
    iosModalOverlay: {
        flex: 1,
        justifyContent: 'flex-end',
        backgroundColor: 'rgba(0,0,0,0.3)',
    },
    iosModalContent: {
        backgroundColor: 'white',
        borderTopLeftRadius: 16,
        borderTopRightRadius: 16,
        paddingBottom: 20,
    },
    iosHeader: {
        flexDirection: 'row',
        justifyContent: 'flex-end',
        padding: 16,
        borderBottomWidth: 1,
        borderBottomColor: '#eee',
    }
});
