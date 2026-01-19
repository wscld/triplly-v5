import { View, Text, TouchableOpacity, StyleSheet, Alert, SectionList } from 'react-native';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Link } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { api } from '@/lib/api';
import type { TravelListItem } from '@/lib/types';
import { formatDateRange } from '@/utils/distance';
import { useState, useMemo } from 'react';
import SheetForm from '@/components/SheetForm';
import DatePickerInput from '@/components/DatePickerInput';
import { Input, InputField, VStack, Text as GText, Textarea, TextareaInput } from '@gluestack-ui/themed';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import Skeleton from '@/components/Skeleton';
import Animated, { useSharedValue, useAnimatedStyle, useAnimatedScrollHandler, interpolate, Extrapolation } from 'react-native-reanimated';

const AnimatedSectionList = Animated.createAnimatedComponent(SectionList);

function TravelCardSkeleton() {
    return (
        <View style={styles.card}>
            <View style={styles.cardContent}>
                <View>
                    <Skeleton width={200} height={32} borderRadius={8} />
                    <Skeleton width={120} height={16} borderRadius={4} style={{ marginTop: 8 }} />
                </View>
                <View style={styles.cardFooter}>
                    <Skeleton width={60} height={28} borderRadius={14} />
                    <Skeleton width={20} height={20} borderRadius={10} />
                </View>
            </View>
        </View>
    );
}

function TravelCard({ travel }: { travel: TravelListItem }) {
    return (
        <Link href={`/(app)/travel/${travel.id}`} asChild>
            <TouchableOpacity style={styles.card}>
                <View style={styles.cardContent}>
                    <View>
                        <Text style={styles.cardTitle}>{travel.title}</Text>
                        {(travel.startDate || travel.endDate) && (
                            <Text style={styles.cardDates}>
                                {formatDateRange(travel.startDate, travel.endDate)}
                            </Text>
                        )}
                    </View>
                    <View style={styles.cardFooter}>
                        <View style={styles.roleBadge}>
                            <Text style={styles.roleText}>{travel.role}</Text>
                        </View>
                        <Ionicons name="arrow-forward" size={20} color="#1C1C1E" />
                    </View>
                </View>
            </TouchableOpacity>
        </Link>
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
            setFormData({ title: '', description: '', startDate: null, endDate: null });
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
                <TouchableOpacity onPress={() => queryClient.refetchQueries({ queryKey: ['travels'] })} style={styles.retryButton}>
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
                >
                    <Ionicons name="add" size={24} color="#fff" />
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
                    keyExtractor={(item) => item.id}
                    renderItem={({ item }) => <TravelCard travel={item} />}
                    renderSectionHeader={({ section: { title } }) => (
                        <View style={styles.sectionHeader}>
                            <Text style={styles.sectionHeaderText}>{title}</Text>
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
                            <Ionicons name="earth" size={64} color="#C7C7CC" />
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
                        <GText size="xs" color="$coolGray500">TITLE</GText>
                        <Input>
                            <InputField
                                placeholder="Where are you going?"
                                value={formData.title}
                                onChangeText={(t) => setFormData(d => ({ ...d, title: t }))}
                                autoFocus
                            />
                        </Input>
                    </VStack>

                    <VStack space="xs">
                        <GText size="xs" color="$coolGray500">DESCRIPTION</GText>
                        <Textarea>
                            <TextareaInput
                                placeholder="Add details..."
                                value={formData.description}
                                onChangeText={(t) => setFormData(d => ({ ...d, description: t }))}
                            />
                        </Textarea>
                    </VStack>

                    <DatePickerInput
                        label="START DATE"
                        value={formData.startDate}
                        onChange={(date) => setFormData(d => ({ ...d, startDate: date }))}
                    />

                    <DatePickerInput
                        label="END DATE"
                        value={formData.endDate}
                        onChange={(date) => setFormData(d => ({ ...d, endDate: date }))}
                        minDate={formData.startDate || undefined}
                    />
                </VStack>
            </SheetForm>
        </View>
    );
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: '#F2F0E9',
    },
    centered: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
        backgroundColor: '#F2F0E9',
    },
    headerButton: {
        width: 44,
        height: 44,
        backgroundColor: '#1C1C1E',
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
        color: '#1C1C1E',
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
        color: '#1C1C1E',
    },
    statsContainer: {
        flexDirection: 'row',
        marginBottom: 24,
        backgroundColor: '#fff',
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
        color: '#1C1C1E',
    },
    statLabel: {
        fontSize: 13,
        color: '#636366',
        fontWeight: '500',
        textTransform: 'uppercase',
        letterSpacing: 0.5,
    },
    statDivider: {
        width: 1,
        height: 32,
        backgroundColor: '#E5E5EA',
    },
    card: {
        height: 200,
        backgroundColor: '#fff',
        borderRadius: 32,
        padding: 24,
        justifyContent: 'space-between',
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 8 },
        shadowOpacity: 0.05,
        shadowRadius: 24,
        elevation: 4,
        marginBottom: 20,
    },
    cardContent: {
        flex: 1,
        justifyContent: 'space-between',
    },
    cardTitle: {
        fontSize: 32,
        fontWeight: '400',
        color: '#1C1C1E',
        lineHeight: 36,
    },
    cardDates: {
        fontSize: 15,
        color: '#636366',
        fontWeight: '500',
        marginTop: 4,
        textTransform: 'uppercase',
        letterSpacing: 1,
    },
    cardFooter: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
    },
    roleBadge: {
        backgroundColor: '#F2F0E9',
        paddingHorizontal: 12,
        paddingVertical: 6,
        borderRadius: 100,
    },
    roleText: {
        fontSize: 12,
        color: '#1C1C1E',
        textTransform: 'uppercase',
        fontWeight: '600',
        letterSpacing: 0.5,
    },
    empty: {
        alignItems: 'center',
        paddingTop: 40,
        gap: 8,
    },
    emptyTitle: {
        fontSize: 20,
        fontWeight: '600',
        color: '#1C1C1E',
        marginTop: 16,
    },
    emptySubtext: {
        fontSize: 15,
        color: '#636366',
    },
    errorText: {
        fontSize: 16,
        color: '#666',
        marginBottom: 16,
    },
    retryButton: {
        paddingHorizontal: 24,
        paddingVertical: 12,
        backgroundColor: '#1C1C1E',
        borderRadius: 100,
    },
    retryText: {
        color: '#fff',
        fontWeight: '600',
    },
});
