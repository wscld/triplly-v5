import React, { memo, useCallback } from 'react';
import { View, Text, TouchableOpacity, ScrollView, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { format, parseISO } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { Colors } from '@/constants/colors';
import type { Itinerary } from '@/lib/types';

interface DaySelectorProps {
    itineraries: Itinerary[];
    selectedIndex: number;
    selectedItinerary: Itinerary | null;
    onSelect: (index: number) => void;
    onAddDay: () => void;
    onLongPress: (itinerary: Itinerary) => void;
    onTodoPress: () => void;
}

function DaySelectorComponent({
    itineraries,
    selectedIndex,
    selectedItinerary,
    onSelect,
    onAddDay,
    onLongPress,
    onTodoPress,
}: DaySelectorProps) {
    const formatItineraryDate = (dateStr: string | null) => {
        if (!dateStr) return 'Sem data';
        try {
            const date = parseISO(dateStr);
            return format(date, "EEEE, d 'de' MMMM", { locale: ptBR });
        } catch {
            return dateStr;
        }
    };

    return (
        <View>
            {selectedItinerary?.title && (
                <Text style={styles.titleText}>{selectedItinerary.title}</Text>
            )}

            <Text style={styles.dateText}>
                {selectedIndex === -1
                    ? 'Lista de Desejos'
                    : selectedItinerary
                        ? formatItineraryDate(selectedItinerary.date)
                        : ''
                }
            </Text>

            <ScrollView
                horizontal
                showsHorizontalScrollIndicator={false}
                contentContainerStyle={styles.daySelector}
            >
                <TouchableOpacity
                    onPress={onTodoPress}
                    style={styles.dayCircle}
                    accessibilityRole="button"
                    accessibilityLabel="Open todo list"
                >
                    <Ionicons name="checkbox-outline" size={20} color={Colors.black} />
                </TouchableOpacity>

                <TouchableOpacity
                    onPress={() => onSelect(-1)}
                    style={[styles.dayCircle, selectedIndex === -1 && styles.dayCircleActive]}
                    accessibilityRole="button"
                    accessibilityLabel="View wishlist"
                >
                    <Ionicons
                        name="heart"
                        size={20}
                        color={Colors.text.primary}
                    />
                </TouchableOpacity>

                {itineraries.map((it, index) => {
                    const date = it.date ? parseISO(it.date) : null;
                    const dayOfWeek = date ? format(date, 'EEEEEE', { locale: ptBR }).toUpperCase() : null;
                    const dayOfMonth = date ? format(date, 'd', { locale: ptBR }) : (index + 1).toString();

                    return (
                        <TouchableOpacity
                            key={it.id}
                            onPress={() => onSelect(index)}
                            onLongPress={() => onLongPress(it)}
                            delayLongPress={300}
                            style={[styles.dayCircle, index === selectedIndex && styles.dayCircleActive]}
                            accessibilityRole="button"
                            accessibilityLabel={`Day ${index + 1}${it.title ? `: ${it.title}` : ''}`}
                            accessibilityHint="Long press to edit"
                        >
                            {dayOfWeek && (
                                <Text style={[styles.dayLabel, index === selectedIndex && styles.dayLabelActive]}>
                                    {dayOfWeek}
                                </Text>
                            )}
                            <Text style={[styles.dayText, index === selectedIndex && styles.dayTextActive]}>
                                {dayOfMonth}
                            </Text>
                        </TouchableOpacity>
                    );
                })}

                <TouchableOpacity
                    onPress={onAddDay}
                    style={styles.addDayCircle}
                    accessibilityRole="button"
                    accessibilityLabel="Add new day"
                >
                    <Ionicons name="add" size={24} color={Colors.text.secondary} />
                </TouchableOpacity>
            </ScrollView>
        </View>
    );
}

export const DaySelector = memo(DaySelectorComponent);

const styles = StyleSheet.create({
    titleText: {
        fontSize: 18,
        fontWeight: '800',
        color: Colors.text.primary,
        textAlign: 'center',
        paddingHorizontal: 24,
        paddingTop: 16,
    },
    dateText: {
        fontSize: 16,
        fontWeight: '500',
        color: Colors.text.primary,
        textAlign: 'center',
        paddingHorizontal: 24,
        paddingTop: 16,
        textTransform: 'capitalize',
    },
    daySelector: {
        flexDirection: 'row',
        paddingHorizontal: 24,
        paddingVertical: 16,
        gap: 12,
    },
    dayCircle: {
        width: 48,
        height: 60,
        borderRadius: 20,
        backgroundColor: Colors.border.light,
        alignItems: 'center',
        justifyContent: 'center',
        gap: 2,
    },
    dayCircleActive: {
        backgroundColor: Colors.primary,
    },
    dayLabel: {
        fontSize: 10,
        fontWeight: '600',
        color: Colors.text.secondary,
        textTransform: 'uppercase',
    },
    dayLabelActive: {
        color: Colors.text.primary,
        opacity: 0.6,
    },
    dayText: {
        fontSize: 16,
        fontWeight: '600',
        color: Colors.text.primary,
    },
    dayTextActive: {
        color: Colors.text.primary,
    },
    addDayCircle: {
        width: 48,
        height: 60,
        borderRadius: 20,
        borderWidth: 2,
        borderColor: Colors.border.medium,
        borderStyle: 'dashed',
        alignItems: 'center',
        justifyContent: 'center',
    },
});
