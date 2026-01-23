import React, { memo, useCallback } from 'react';
import { View, Text, TouchableOpacity, Alert, StyleSheet } from 'react-native';
import { GestureHandlerRootView } from 'react-native-gesture-handler';
import Swipeable from 'react-native-gesture-handler/ReanimatedSwipeable';
import DraggableFlatList, { ScaleDecorator, RenderItemParams } from 'react-native-draggable-flatlist';
import { Ionicons } from '@expo/vector-icons';
import { router } from 'expo-router';
import { Colors } from '@/constants/colors';
import type { Activity } from '@/lib/types';

interface ActivitiesListProps {
    activities: Activity[];
    travelId: string;
    itineraryId: string | null;
    selectedDayIndex: number;
    onReorder: (data: {
        activityId: string;
        afterActivityId: string | null;
        beforeActivityId: string | null;
        newActivities: Activity[];
    }) => void;
    onDelete: (activityId: string) => void;
    onAddActivity: () => void;
}

function ActivitiesListComponent({
    activities,
    travelId,
    itineraryId,
    selectedDayIndex,
    onReorder,
    onDelete,
    onAddActivity,
}: ActivitiesListProps) {
    const navigateToActivity = useCallback((activityId: string) => {
        const targetItineraryId = itineraryId || 'wishlist';
        router.push(`/(app)/travel/${travelId}/itinerary/activity/${activityId}?itineraryId=${targetItineraryId}`);
    }, [travelId, itineraryId]);

    const handleDelete = useCallback((activity: Activity) => {
        Alert.alert(
            'Remover local',
            `Deseja remover "${activity.title}"?`,
            [
                { text: 'Cancelar', style: 'cancel' },
                { text: 'Remover', style: 'destructive', onPress: () => onDelete(activity.id) }
            ]
        );
    }, [onDelete]);

    const renderRightActions = useCallback((activity: Activity) => {
        return (
            <View style={styles.swipeActionsContainer}>
                <TouchableOpacity
                    onPress={() => navigateToActivity(activity.id)}
                    style={[styles.swipeAction, { backgroundColor: Colors.primary }]}
                    accessibilityRole="button"
                    accessibilityLabel="Edit activity"
                >
                    <Ionicons name="pencil" size={20} color={Colors.text.primary} />
                </TouchableOpacity>
                <TouchableOpacity
                    onPress={() => handleDelete(activity)}
                    style={[styles.swipeAction, { backgroundColor: Colors.error }]}
                    accessibilityRole="button"
                    accessibilityLabel="Delete activity"
                >
                    <Ionicons name="trash-outline" size={20} color={Colors.white} />
                </TouchableOpacity>
            </View>
        );
    }, [navigateToActivity, handleDelete]);

    const renderItem = useCallback(({ item, getIndex, drag, isActive }: RenderItemParams<Activity>) => {
        const index = getIndex() ?? 0;
        const isFirst = index === 0;
        const isLast = index === activities.length - 1;

        return (
            <ScaleDecorator>
                <View style={styles.timelineRow}>
                    {!isActive && (
                        <View style={styles.timelineContainer}>
                            {!isFirst && <View style={styles.timelineLineTop} />}
                            <View style={styles.timelineDot} />
                            {!isLast && <View style={styles.timelineLineBottom} />}
                        </View>
                    )}

                    <View style={{ flex: 1 }}>
                        <Swipeable
                            renderRightActions={() => renderRightActions(item)}
                            containerStyle={{ overflow: 'visible' }}
                        >
                            <TouchableOpacity
                                style={[styles.activityCard, isActive && styles.activityCardActive]}
                                onPress={() => navigateToActivity(item.id)}
                                onLongPress={drag}
                                activeOpacity={1}
                                accessibilityRole="button"
                                accessibilityLabel={item.title}
                                accessibilityHint="Swipe for options, long press to reorder"
                            >
                                <TouchableOpacity onPressIn={drag} style={styles.dragHandle}>
                                    <Ionicons name="reorder-two" size={20} color={Colors.border.medium} />
                                </TouchableOpacity>
                                <Text style={styles.activityTitle} numberOfLines={1}>
                                    {item.title}
                                </Text>
                                <Ionicons name="chevron-forward" size={20} color={Colors.border.medium} />
                            </TouchableOpacity>
                        </Swipeable>
                    </View>
                </View>
            </ScaleDecorator>
        );
    }, [activities.length, navigateToActivity, renderRightActions]);

    const handleDragEnd = useCallback(({ data, from, to }: { data: Activity[]; from: number; to: number }) => {
        if (from !== to && data[to]) {
            const movedActivity = data[to];
            const afterActivityId = to > 0 ? data[to - 1]?.id : null;
            const beforeActivityId = to < data.length - 1 ? data[to + 1]?.id : null;

            onReorder({
                activityId: movedActivity.id,
                afterActivityId,
                beforeActivityId,
                newActivities: data,
            });
        }
    }, [onReorder]);

    return (
        <View style={styles.section}>
            <View style={styles.sectionHeader}>
                <Text style={styles.sectionTitle}>
                    {selectedDayIndex === -1 ? 'LISTA DE DESEJOS' : 'ROTEIRO'}
                </Text>
                <TouchableOpacity
                    onPress={onAddActivity}
                    accessibilityRole="button"
                    accessibilityLabel="Add activity"
                >
                    <Ionicons name="add-circle" size={28} color={Colors.black} />
                </TouchableOpacity>
            </View>

            {activities.length === 0 ? (
                <View style={styles.emptyState}>
                    <Text style={styles.emptyText}>
                        {selectedDayIndex === -1 ? 'Nenhum local na lista' : 'Nenhum local adicionado'}
                    </Text>
                    <Text style={styles.emptyStateSubtext}>
                        Clique em &quot;+&quot; para adicionar atividades
                    </Text>
                </View>
            ) : (
                <GestureHandlerRootView style={{ flex: 1 }}>
                    <DraggableFlatList
                        key={`draggable-${selectedDayIndex}`}
                        data={activities}
                        scrollEnabled={false}
                        keyExtractor={(item) => item.id}
                        onDragEnd={handleDragEnd}
                        renderItem={renderItem}
                    />
                </GestureHandlerRootView>
            )}
        </View>
    );
}

export const ActivitiesList = memo(ActivitiesListComponent);

const styles = StyleSheet.create({
    section: {
        paddingHorizontal: 24,
        paddingTop: 24,
    },
    sectionHeader: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: 16,
    },
    sectionTitle: {
        fontSize: 14,
        fontWeight: '700',
        color: Colors.text.primary,
        letterSpacing: 1,
    },
    emptyState: {
        alignItems: 'center',
        paddingVertical: 40,
    },
    emptyText: {
        fontSize: 17,
        fontWeight: '500',
        color: Colors.text.secondary,
    },
    emptyStateSubtext: {
        fontSize: 14,
        color: Colors.text.secondary,
        marginTop: 4,
    },
    timelineRow: {
        flexDirection: 'row',
        alignItems: 'flex-start',
        minHeight: 60,
    },
    timelineContainer: {
        width: 24,
        alignItems: 'center',
        position: 'relative',
    },
    timelineDot: {
        width: 10,
        height: 10,
        borderRadius: 5,
        backgroundColor: Colors.primary,
        marginTop: 22,
        zIndex: 1,
    },
    timelineLineTop: {
        position: 'absolute',
        top: 0,
        left: 11,
        width: 2,
        height: 22,
        backgroundColor: Colors.border.light,
    },
    timelineLineBottom: {
        position: 'absolute',
        top: 32,
        left: 11,
        width: 2,
        height: '100%',
        backgroundColor: Colors.border.light,
    },
    activityCard: {
        flex: 1,
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: Colors.white,
        paddingVertical: 16,
        paddingHorizontal: 16,
        borderRadius: 16,
        marginBottom: 12,
        marginLeft: 12,
        borderWidth: 1,
        borderColor: 'rgba(0,0,0,0.08)',
    },
    activityCardActive: {
        backgroundColor: Colors.successLight,
        transform: [{ scale: 0.88 }],
    },
    dragHandle: {
        padding: 4,
        marginRight: 4,
    },
    activityTitle: {
        flex: 1,
        fontSize: 17,
        fontWeight: '500',
        color: Colors.text.primary,
    },
    swipeActionsContainer: {
        flexDirection: 'row',
        alignItems: 'center',
        marginBottom: 12,
        marginRight: 12,
        marginLeft: 8,
    },
    swipeAction: {
        width: 48,
        height: '100%',
        justifyContent: 'center',
        alignItems: 'center',
        borderRadius: 12,
        marginLeft: 8,
    },
});
