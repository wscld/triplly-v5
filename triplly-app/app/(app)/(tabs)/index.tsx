import { View, Text, TouchableOpacity, StyleSheet, Alert, SectionList } from 'react-native';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Ionicons } from '@expo/vector-icons';
import { api } from '@/lib/api';
import type { TravelListItem } from '@/lib/types';
import { useState, useMemo, useCallback } from 'react';
import SheetForm from '@/components/SheetForm';
import DateRangePicker from '@/components/DateRangePicker';
import { VStack, Text as GText } from '@gluestack-ui/themed';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import Skeleton from '@/components/Skeleton';
import { TravelCard } from '@/components/TravelCard';
import Animated, { useSharedValue, useAnimatedStyle, useAnimatedScrollHandler, interpolate, Extrapolation } from 'react-native-reanimated';
import { Colors } from '@/constants/colors';
import PlaceAutocomplete from '@/components/PlaceAutocomplete';

const AnimatedSectionList = Animated.createAnimatedComponent(SectionList);

function TravelCardSkeleton() {
    return (
        <View style={styles.card} accessibilityLabel="Loading travel card">
            <View style={styles.cardContent}>
                <Skeleton width="65%" height={28} borderRadius={6} style={{ marginBottom: 8 }} />
                <Skeleton width="40%" height={14} borderRadius={4} />
            </View>
        </View>
    );
}


export default function TravelListScreen() {
    const queryClient = useQueryClient();
    const insets = useSafeAreaInsets();
    const [showCreateSheet, setShowCreateSheet] = useState(false);

    const [formData, setFormData] = useState({
        title: '',
        description: '',
        startDate: null as Date | null,
        endDate: null as Date | null,
        latitude: null as number | null,
        longitude: null as number | null,
    });

    const { data: travels, isLoading, error } = useQuery({
        queryKey: ['travels'],
        queryFn: () => api.getTravels(),
    });

    const stats = useMemo(() => {
        if (!travels) return { total: 0, upcoming: 0, past: 0 };
        const now = new Date();
        const today = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();

        return travels.reduce((acc, travel) => {
            acc.total++;
            const start = travel.startDate ? new Date(travel.startDate).getTime() : null;
            const end = travel.endDate ? new Date(travel.endDate).getTime() : null;

            if ((start && start >= today) || (!start && !end) || (end && end >= today)) {
                acc.upcoming++;
            } else {
                acc.past++;
            }
            return acc;
        }, { total: 0, upcoming: 0, past: 0 });
    }, [travels]);

    const sections = useMemo(() => {
        if (!travels) return [];
        const now = new Date();
        const today = new Date(now.getFullYear(), now.getMonth(), now.getDate()).getTime();

        const upcoming: TravelListItem[] = [];
        const past: TravelListItem[] = [];

        travels.forEach(travel => {
            const start = travel.startDate ? new Date(travel.startDate).getTime() : null;
            const end = travel.endDate ? new Date(travel.endDate).getTime() : null;

            if ((start && start >= today) || (!start && !end) || (end && end >= today)) {
                upcoming.push(travel);
            } else {
                past.push(travel);
            }
        });

        // Sort upcoming by start date (ascending)
        upcoming.sort((a, b) => {
            if (!a.startDate) return 1;
            if (!b.startDate) return -1;
            return new Date(a.startDate).getTime() - new Date(b.startDate).getTime();
        });

        // Sort past by end date (descending)
        past.sort((a, b) => {
            if (!a.endDate) return 1;
            if (!b.endDate) return -1;
            return new Date(b.endDate).getTime() - new Date(a.endDate).getTime();
        });

        const result = [];
        if (upcoming.length > 0) result.push({ title: 'Próximas', data: upcoming });
        if (past.length > 0) result.push({ title: 'Concluídas', data: past });

        return result;
    }, [travels]);

    const createTravel = useMutation({
        mutationFn: () => api.createTravel({
            ...formData,
            startDate: formData.startDate ? formData.startDate.toISOString().split('T')[0] : '',
            endDate: formData.endDate ? formData.endDate.toISOString().split('T')[0] : '',
        }),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['travels'] });
            setShowCreateSheet(false);
            setFormData({ title: '', description: '', startDate: null, endDate: null, latitude: null, longitude: null });
        },
        onError: (err) => {
            Alert.alert('Error', err instanceof Error ? err.message : 'Failed to create travel');
        },
    });

    // Scroll handling for collapsible header
    const scrollY = useSharedValue(0);
    const scrollHandler = useAnimatedScrollHandler({
        onScroll: (event) => {
            scrollY.value = event.contentOffset.y;
        },
    });

    const headerContentStyle = useAnimatedStyle(() => {
        return {
            opacity: interpolate(scrollY.value, [0, 60], [1, 0], Extrapolation.CLAMP),
            transform: [
                { translateY: interpolate(scrollY.value, [0, 100], [0, -50], Extrapolation.CLAMP) }
            ],
        };
    });

    if (error) {
        return (
            <View style={styles.centered}>
                <Text style={styles.errorText}>Failed to load travels: {error instanceof Error ? error.message : 'Unknown error'}</Text>
                <TouchableOpacity
                    onPress={() => queryClient.refetchQueries({ queryKey: ['travels'] })}
                    style={styles.retryButton}
                    accessibilityRole="button"
                    accessibilityLabel="Retry loading travels"
                >
                    <Text style={styles.retryText}>Retry</Text>
                </TouchableOpacity>
            </View>
        );
    }

    return (
        <View style={styles.container}>
            {/* Fixed Header (Button) */}
            <View style={{
                position: 'absolute',
                top: insets.top + 10,
                left: 24,
                right: 24,
                zIndex: 100,
                alignItems: 'flex-end',
            }}>
                <TouchableOpacity
                    style={styles.headerButton}
                    onPress={() => setShowCreateSheet(true)}
                    accessibilityRole="button"
                    accessibilityLabel="Create new travel"
                >
                    <Ionicons name="add" size={24} color={Colors.text.primary} />
                </TouchableOpacity>
            </View>

            {/* Collapsible Header Content */}
            <Animated.View style={[
                {
                    position: 'absolute',
                    top: insets.top + 60,
                    left: 24,
                    right: 24,
                    zIndex: 10
                },
                headerContentStyle
            ]}>
                <Text style={styles.headerTitle}>Minhas Viagens</Text>
            </Animated.View>

            {isLoading ? (
                <View style={[styles.list, { paddingTop: (insets?.top ?? 0) + 140 }]}>
                    <TravelCardSkeleton />
                    <TravelCardSkeleton />
                    <TravelCardSkeleton />
                </View>
            ) : (
                <AnimatedSectionList
                    sections={sections}
                    keyExtractor={(item: any) => item.id}
                    renderItem={({ item }: { item: any }) => <TravelCard travel={item} />}
                    renderSectionHeader={({ section }: { section: any }) => (
                        <View style={styles.sectionHeader}>
                            <Text style={styles.sectionHeaderText}>{section.title}</Text>
                        </View>
                    )}
                    contentContainerStyle={{
                        paddingHorizontal: 20,
                        paddingBottom: 100,
                        paddingTop: (insets?.top ?? 0) + 130 // Space for expanded header
                    }}
                    onScroll={scrollHandler}
                    scrollEventThrottle={16}
                    ListHeaderComponent={
                        <View style={styles.statsContainer}>
                            <View style={styles.statItem}>
                                <Text style={styles.statValue}>{stats.total}</Text>
                                <Text style={styles.statLabel}>Total</Text>
                            </View>
                            <View style={styles.statDivider} />
                            <View style={styles.statItem}>
                                <Text style={styles.statValue}>{stats.upcoming}</Text>
                                <Text style={styles.statLabel}>Upcoming</Text>
                            </View>
                            <View style={styles.statDivider} />
                            <View style={styles.statItem}>
                                <Text style={styles.statValue}>{stats.past}</Text>
                                <Text style={styles.statLabel}>Past</Text>
                            </View>
                        </View>
                    }
                    ListEmptyComponent={
                        <View style={styles.empty}>
                            <Ionicons name="earth" size={64} color={Colors.border.medium} />
                            <Text style={styles.emptyTitle}>No travels yet</Text>
                            <Text style={styles.emptySubtext}>Plan your first adventure</Text>
                        </View>
                    }
                    stickySectionHeadersEnabled={false}
                />
            )}


            <SheetForm
                isOpen={showCreateSheet}
                onClose={() => setShowCreateSheet(false)}
                title="New Trip"
                onSubmit={() => createTravel.mutate()}
                isSubmitting={createTravel.isPending}
                submitLabel="Create"
            >
                <VStack space="md">
                    <VStack space="xs">
                        <GText size="xs" color="$coolGray500">DESTINATION</GText>
                        <PlaceAutocomplete
                            placeholder="Where are you going?"
                            initialValue={formData.title}
                            onSelect={(place) => {
                                setFormData(d => ({
                                    ...d,
                                    title: place.name,
                                    latitude: place.lat,
                                    longitude: place.lon
                                }));
                            }}
                        />
                    </VStack>

                    <DateRangePicker
                        startDate={formData.startDate}
                        endDate={formData.endDate}
                        onChange={({ startDate, endDate }) => setFormData(d => ({ ...d, startDate, endDate }))}
                        label="TRAVEL DATES"
                    />
                </VStack>
            </SheetForm>
        </View>
    );
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: Colors.background,
    },
    centered: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
        backgroundColor: Colors.background,
    },
    headerButton: {
        width: 44,
        height: 44,
        backgroundColor: Colors.primary,
        borderRadius: 22,
        alignItems: 'center',
        justifyContent: 'center',
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.1,
        shadowRadius: 8,
        elevation: 4,
    },
    headerTitle: {
        fontSize: 40,
        fontWeight: '400',
        color: Colors.text.primary,
        letterSpacing: -0.5,
    },
    list: {
        paddingHorizontal: 20,
        gap: 20,
        paddingBottom: 100,
    },
    sectionHeader: {
        marginBottom: 16,
        marginTop: 8,
    },
    sectionHeaderText: {
        fontSize: 18,
        fontWeight: '600',
        color: Colors.text.primary,
    },
    statsContainer: {
        flexDirection: 'row',
        marginBottom: 24,
        backgroundColor: Colors.white,
        borderRadius: 24,
        padding: 20,
        justifyContent: 'space-around',
        alignItems: 'center',
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.05,
        shadowRadius: 12,
        elevation: 2,
    },
    statItem: {
        alignItems: 'center',
        gap: 4,
    },
    statValue: {
        fontSize: 24,
        fontWeight: '600',
        color: Colors.text.primary,
    },
    statLabel: {
        fontSize: 13,
        color: Colors.text.secondary,
        fontWeight: '500',
        textTransform: 'uppercase',
        letterSpacing: 0.5,
    },
    statDivider: {
        width: 1,
        height: 32,
        backgroundColor: Colors.border.light,
    },
    card: {
        height: 200,
        backgroundColor: Colors.white,
        borderRadius: 32,
        padding: 24,
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 8 },
        shadowOpacity: 0.05,
        shadowRadius: 24,
        elevation: 4,
        marginBottom: 20,
    },
    cardContent: {
        flex: 1,
        justifyContent: 'center',
    },
    empty: {
        alignItems: 'center',
        paddingTop: 40,
        gap: 8,
    },
    emptyTitle: {
        fontSize: 20,
        fontWeight: '600',
        color: Colors.text.primary,
        marginTop: 16,
    },
    emptySubtext: {
        fontSize: 15,
        color: Colors.text.secondary,
    },
    errorText: {
        fontSize: 16,
        color: '#666',
        marginBottom: 16,
    },
    retryButton: {
        paddingHorizontal: 24,
        paddingVertical: 12,
        backgroundColor: Colors.primary,
        borderRadius: 100,
    },
    retryText: {
        color: Colors.text.primary,
        fontWeight: '600',
    },
});
