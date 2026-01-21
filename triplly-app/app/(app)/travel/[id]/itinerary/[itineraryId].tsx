import { useState, useMemo, useRef, useCallback } from 'react';
import {
    View,
    Text,
    TouchableOpacity,
    StyleSheet,
    ActivityIndicator,
    Alert,
    ScrollView,
} from 'react-native';
import { router, useLocalSearchParams } from 'expo-router';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Ionicons } from '@expo/vector-icons';
import { api } from '@/lib/api';
import type { Activity, Itinerary } from '@/lib/types';
import ItineraryMap from '@/components/ItineraryMap';
import SheetForm from '@/components/SheetForm';
import PlaceAutocomplete from '@/components/PlaceAutocomplete';
import GlassHeader from '@/components/GlassHeader';
import { VStack } from '@gluestack-ui/themed';
import { BottomSheetModal, BottomSheetView, BottomSheetBackdrop } from '@gorhom/bottom-sheet';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { format, parseISO } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { Colors } from '@/constants/colors';

const MAP_HEIGHT = 200;

export default function ItineraryScreen() {
    const { id, itineraryId: initialItineraryId } = useLocalSearchParams<{ id: string; itineraryId: string }>();
    const queryClient = useQueryClient();
    const insets = useSafeAreaInsets();

    // Selected itinerary state (local, not via navigation)
    const [selectedItineraryId, setSelectedItineraryId] = useState<string>(initialItineraryId!);

    // Current view tab
    const [activeTab, setActiveTab] = useState<'roteiro' | 'mapa' | 'config'>('roteiro');

    // Form State
    const [showAddSheet, setShowAddSheet] = useState(false);
    const editSheetRef = useRef<BottomSheetModal>(null);
    const [selectedActivity, setSelectedActivity] = useState<Activity | null>(null);
    const [formData, setFormData] = useState({
        title: '',
        latitude: 0,
        longitude: 0,
        googlePlaceId: null as string | null,
        address: null as string | null,
    });

    // Fetch travel to get all itineraries for day selector
    const { data: travel } = useQuery({
        queryKey: ['travel', id],
        queryFn: () => api.getTravel(id!),
        enabled: !!id,
    });

    // Fetch current selected itinerary
    const { data: itinerary, isLoading, error } = useQuery({
        queryKey: ['itinerary', selectedItineraryId],
        queryFn: () => api.getItinerary(selectedItineraryId!),
        enabled: !!selectedItineraryId,
    });

    // Sort itineraries by date for day selector
    const sortedItineraries = useMemo(() => {
        return [...(travel?.itineraries || [])].sort((a, b) => {
            if (!a.date && !b.date) return 0;
            if (!a.date) return 1;
            if (!b.date) return -1;
            return new Date(a.date).getTime() - new Date(b.date).getTime();
        });
    }, [travel?.itineraries]);



    // Mutations
    const createActivity = useMutation({
        mutationFn: () => api.createActivity({
            travelId: id!,
            itineraryId: selectedItineraryId!,
            title: formData.title,
            latitude: formData.latitude,
            longitude: formData.longitude,
            googlePlaceId: formData.googlePlaceId,
            address: formData.address,
        }),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['itinerary', selectedItineraryId] });
            queryClient.invalidateQueries({ queryKey: ['travel', id] });
            setShowAddSheet(false);
            setFormData({ title: '', latitude: 0, longitude: 0, googlePlaceId: null, address: null });
        },
        onError: (err) => Alert.alert('Error', err instanceof Error ? err.message : 'Failed to add activity'),
    });

    const deleteActivity = useMutation({
        mutationFn: (activityId: string) => api.deleteActivity(activityId),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['itinerary', selectedItineraryId] });
            queryClient.invalidateQueries({ queryKey: ['travel', id] });
            editSheetRef.current?.dismiss();
        },
        onError: (err) => Alert.alert('Error', err instanceof Error ? err.message : 'Failed to delete activity'),
    });

    const activities = itinerary?.activities ?? [];

    // Format date for header
    const formatItineraryDate = (dateStr: string | null) => {
        if (!dateStr) return 'Sem data';
        try {
            // Parse at noon to avoid timezone shift issues
            const date = parseISO(`${dateStr}T12:00:00`);
            return format(date, "EEEE, d 'de' MMMM", { locale: ptBR });
        } catch {
            return dateStr;
        }
    };

    // Handle day selection (local state change, no navigation)
    const handleDaySelect = (itinerary: Itinerary) => {
        setSelectedItineraryId(itinerary.id);
    };

    if (isLoading) {
        return (
            <View style={styles.centered}>
                <ActivityIndicator size="large" color={Colors.black} />
            </View>
        );
    }

    if (error || !itinerary) {
        return (
            <View style={styles.centered}>
                <Text style={styles.errorText}>Falha ao carregar roteiro</Text>
            </View>
        );
    }

    return (
        <View style={styles.container}>
            {/* Header */}
            <GlassHeader title={travel?.title || 'Roteiro'} />

            {/* Main Content */}
            <ScrollView
                style={styles.content}
                contentContainerStyle={{
                    paddingTop: 60 + insets.top,
                    paddingBottom: MAP_HEIGHT + 80 + insets.bottom
                }}
            >
                {/* Date Display */}
                <Text style={styles.dateText}>
                    {formatItineraryDate(itinerary.date)}
                </Text>

                {/* Day Selector */}
                {sortedItineraries.length > 1 && (
                    <ScrollView
                        horizontal
                        showsHorizontalScrollIndicator={false}
                        contentContainerStyle={styles.daySelector}
                    >
                        {sortedItineraries.map((it, index) => (
                            <TouchableOpacity
                                key={it.id}
                                onPress={() => handleDaySelect(it)}
                                style={[
                                    styles.dayCircle,
                                    it.id === selectedItineraryId && styles.dayCircleActive
                                ]}
                            >
                                <Text style={[
                                    styles.dayText,
                                    it.id === selectedItineraryId && styles.dayTextActive
                                ]}>
                                    {index + 1}
                                </Text>
                            </TouchableOpacity>
                        ))}
                    </ScrollView>
                )}

                {/* Activities Section */}
                {activeTab === 'roteiro' && (
                    <View style={styles.section}>
                        <View style={styles.sectionHeader}>
                            <Text style={styles.sectionTitle}>ROTEIRO</Text>
                            <TouchableOpacity onPress={() => setShowAddSheet(true)}>
                                <Ionicons name="add-circle" size={28} color={Colors.black} />
                            </TouchableOpacity>
                        </View>

                        {activities.length === 0 ? (
                            <View style={styles.emptyState}>
                                <Text style={styles.emptyText}>Nenhum local adicionado</Text>
                                <Text style={styles.emptySubtext}>Toque no + para adicionar</Text>
                            </View>
                        ) : (
                            activities.map((activity) => (
                                <TouchableOpacity
                                    key={activity.id}
                                    style={styles.activityCard}
                                    onPress={() => router.push(`/(app)/travel/${id}/itinerary/activity/${activity.id}?itineraryId=${selectedItineraryId}`)}
                                    onLongPress={() => {
                                        setSelectedActivity(activity);
                                        editSheetRef.current?.present();
                                    }}
                                >
                                    <View style={styles.activityIcon}>
                                        <Ionicons name="location-outline" size={24} color={Colors.black} />
                                    </View>
                                    <Text style={styles.activityTitle} numberOfLines={1}>
                                        {activity.title}
                                    </Text>
                                    <Ionicons name="chevron-forward" size={20} color={Colors.border.medium} />
                                </TouchableOpacity>
                            ))
                        )}
                    </View>
                )}
            </ScrollView>

            {/* Fixed Map at Bottom */}
            <View style={[styles.fixedMapContainer, { bottom: 70 + (insets.bottom || 16) }]}>
                <View style={styles.mapHeader}>
                    <Text style={styles.mapTitle}>MAPA</Text>
                </View>
                <View style={styles.mapWrapper}>
                    {activities.length > 0 ? (
                        <ItineraryMap activities={activities} />
                    ) : (
                        <View style={styles.mapEmpty}>
                            <Ionicons name="map-outline" size={32} color={Colors.border.medium} />
                            <Text style={styles.mapEmptyText}>Adicione locais para ver o mapa</Text>
                        </View>
                    )}
                </View>
            </View>

            {/* Bottom Tab Bar */}
            <View style={[styles.bottomTabs, { paddingBottom: insets.bottom || 16 }]}>
                <TouchableOpacity
                    style={styles.tabItem}
                    onPress={() => setActiveTab('roteiro')}
                >
                    <Ionicons
                        name={activeTab === 'roteiro' ? 'location' : 'location-outline'}
                        size={24}
                        color={activeTab === 'roteiro' ? Colors.black : Colors.text.secondary}
                    />
                    <Text style={[styles.tabLabel, activeTab === 'roteiro' && styles.tabLabelActive]}>
                        Roteiro
                    </Text>
                </TouchableOpacity>

                <TouchableOpacity
                    style={styles.tabItem}
                    onPress={() => setActiveTab('mapa')}
                >
                    <Ionicons
                        name={activeTab === 'mapa' ? 'map' : 'map-outline'}
                        size={24}
                        color={activeTab === 'mapa' ? Colors.black : Colors.text.secondary}
                    />
                    <Text style={[styles.tabLabel, activeTab === 'mapa' && styles.tabLabelActive]}>
                        Mapa
                    </Text>
                </TouchableOpacity>

                <TouchableOpacity
                    style={styles.tabItem}
                    onPress={() => router.back()}
                >
                    <Ionicons
                        name="settings-outline"
                        size={24}
                        color={Colors.text.secondary}
                    />
                    <Text style={styles.tabLabel}>Configurações</Text>
                </TouchableOpacity>
            </View>

            {/* Add Activity Sheet */}
            <SheetForm
                isOpen={showAddSheet}
                onClose={() => {
                    setShowAddSheet(false);
                    setFormData({ title: '', latitude: 0, longitude: 0, googlePlaceId: null, address: null });
                }}
                title="Adicionar Local"
                onSubmit={() => formData.title && createActivity.mutate()}
                isSubmitting={createActivity.isPending}
                submitLabel="Adicionar"
            >
                <VStack space="md">
                    <PlaceAutocomplete
                        onSelect={(place) => {
                            setFormData({
                                title: place.name,
                                latitude: place.latitude || 0,
                                longitude: place.longitude || 0,
                                googlePlaceId: place.placeId,
                                address: place.address || null,
                            });
                        }}
                    />
                    {formData.title && (
                        <View style={styles.selectedPlace}>
                            <Ionicons name="location" size={16} color={Colors.black} />
                            <Text style={styles.selectedPlaceText}>{formData.title}</Text>
                        </View>
                    )}
                </VStack>
            </SheetForm>

            {/* Edit/Delete Activity Sheet */}
            <BottomSheetModal
                ref={editSheetRef}
                enableDynamicSizing
                enablePanDownToClose
                backdropComponent={(props) => (
                    <BottomSheetBackdrop {...props} disappearsOnIndex={-1} appearsOnIndex={0} opacity={0.5} />
                )}
                handleIndicatorStyle={{ backgroundColor: '#D1D1D6', width: 36 }}
                backgroundStyle={{ backgroundColor: '#fff' }}
            >
                <BottomSheetView style={{ padding: 16, paddingBottom: 32 }}>
                    <Text style={styles.sheetTitle}>{selectedActivity?.title}</Text>
                    <TouchableOpacity
                        style={styles.sheetItem}
                        onPress={() => {
                            editSheetRef.current?.dismiss();
                            if (selectedActivity) {
                                router.push(`/(app)/travel/${id}/itinerary/activity/${selectedActivity.id}?itineraryId=${selectedItineraryId}`);
                            }
                        }}
                    >
                        <Text style={styles.sheetItemText}>Ver detalhes</Text>
                    </TouchableOpacity>
                    <TouchableOpacity
                        style={styles.sheetItem}
                        onPress={() => {
                            editSheetRef.current?.dismiss();
                            if (selectedActivity) {
                                Alert.alert(
                                    'Remover local',
                                    `Deseja remover "${selectedActivity.title}"?`,
                                    [
                                        { text: 'Cancelar', style: 'cancel' },
                                        { text: 'Remover', style: 'destructive', onPress: () => deleteActivity.mutate(selectedActivity.id) }
                                    ]
                                );
                            }
                        }}
                    >
                        <Text style={[styles.sheetItemText, { color: '#FF3B30' }]}>Remover</Text>
                    </TouchableOpacity>
                </BottomSheetView>
            </BottomSheetModal>
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
    content: {
        flex: 1,
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
        width: 44,
        height: 44,
        borderRadius: 22,
        borderWidth: 2,
        borderColor: Colors.black,
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: 'transparent',
    },
    dayCircleActive: {
        backgroundColor: Colors.black,
    },
    dayText: {
        fontSize: 16,
        fontWeight: '600',
        color: Colors.black,
    },
    dayTextActive: {
        color: '#fff',
    },
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
    activityCard: {
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: '#fff',
        paddingVertical: 16,
        paddingHorizontal: 16,
        borderRadius: 16,
        marginBottom: 12,
        borderWidth: 1,
        borderColor: 'rgba(0,0,0,0.08)',
    },
    activityIcon: {
        marginRight: 12,
    },
    activityTitle: {
        flex: 1,
        fontSize: 17,
        fontWeight: '500',
        color: Colors.text.primary,
    },
    emptyState: {
        alignItems: 'center',
        paddingVertical: 40,
    },
    emptyText: {
        fontSize: 17,
        fontWeight: '500',
        color: '#636366',
    },
    emptySubtext: {
        fontSize: 14,
        color: Colors.text.secondary,
        marginTop: 4,
    },
    mapContainer: {
        height: 200,
        borderRadius: 16,
        overflow: 'hidden',
        marginTop: 12,
    },
    fixedMapContainer: {
        position: 'absolute',
        left: 0,
        right: 0,
        height: MAP_HEIGHT + 30,
        backgroundColor: Colors.background,
        paddingHorizontal: 24,
    },
    mapHeader: {
        marginBottom: 8,
    },
    mapTitle: {
        fontSize: 14,
        fontWeight: '700',
        color: Colors.text.primary,
        letterSpacing: 1,
    },
    mapWrapper: {
        height: MAP_HEIGHT,
        borderRadius: 16,
        overflow: 'hidden',
        backgroundColor: Colors.border.light,
    },
    mapEmpty: {
        flex: 1,
        alignItems: 'center',
        justifyContent: 'center',
        gap: 8,
    },
    mapEmptyText: {
        fontSize: 14,
        color: Colors.text.secondary,
    },
    bottomTabs: {
        position: 'absolute',
        bottom: 0,
        left: 0,
        right: 0,
        flexDirection: 'row',
        backgroundColor: Colors.background,
        borderTopWidth: 1,
        borderTopColor: 'rgba(0,0,0,0.08)',
        paddingTop: 12,
    },
    tabItem: {
        flex: 1,
        alignItems: 'center',
        gap: 4,
    },
    tabLabel: {
        fontSize: 12,
        color: Colors.text.secondary,
    },
    tabLabelActive: {
        color: Colors.text.primary,
        fontWeight: '600',
    },
    selectedPlace: {
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: '#E8F5E9',
        padding: 12,
        borderRadius: 8,
        gap: 8,
    },
    selectedPlaceText: {
        fontSize: 15,
        color: Colors.text.primary,
        flex: 1,
    },
    sheetTitle: {
        fontSize: 17,
        fontWeight: '600',
        padding: 16,
        textAlign: 'center',
    },
    errorText: {
        fontSize: 16,
        color: '#666',
    },
    sheetItem: {
        flexDirection: 'row',
        alignItems: 'center',
        paddingVertical: 16,
        borderBottomWidth: 1,
        borderBottomColor: Colors.border.light,
    },
    sheetItemText: {
        fontSize: 16,
        color: Colors.text.primary,
    },
});
