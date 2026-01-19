import { View, Text, TouchableOpacity, StyleSheet, Alert, ScrollView, ActivityIndicator, Dimensions, Image } from 'react-native';
import { GestureHandlerRootView, GestureDetector, Gesture, Directions } from 'react-native-gesture-handler';
import DraggableFlatList, { ScaleDecorator, RenderItemParams } from 'react-native-draggable-flatlist';
import Animated, { FadeIn, FadeOut, SlideInRight, SlideInLeft, SlideOutLeft, SlideOutRight, runOnJS, useSharedValue, useAnimatedStyle, withSpring, interpolate, Extrapolation, useAnimatedScrollHandler } from 'react-native-reanimated';
import { useLocalSearchParams, router } from 'expo-router';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Ionicons } from '@expo/vector-icons';
import { api } from '@/lib/api';
import type { Itinerary, Activity, TravelMember } from '@/lib/types';
import { useState, useRef, useEffect } from 'react';
import SheetForm from '@/components/SheetForm';
import TodoList from '@/components/TodoList';
import PlaceAutocomplete from '@/components/PlaceAutocomplete';
import ItineraryMap from '@/components/ItineraryMap';
import { VStack, HStack, Input, InputField, Actionsheet, ActionsheetBackdrop, ActionsheetContent, ActionsheetItem, ActionsheetItemText } from '@gluestack-ui/themed';
import { Colors } from '@/constants/colors';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import DatePickerInput from '@/components/DatePickerInput';
import { format, parseISO } from 'date-fns';
import { ptBR } from 'date-fns/locale';


const { height: SCREEN_HEIGHT } = Dimensions.get('window');
const MAP_COLLAPSED_HEIGHT = 120;
const MAP_EXPANDED_HEIGHT = SCREEN_HEIGHT * 0.5;

export default function TravelDetailScreen() {
    const { id } = useLocalSearchParams<{ id: string }>();
    const queryClient = useQueryClient();
    const insets = useSafeAreaInsets();

    // Map expansion state
    const mapHeight = useSharedValue(MAP_COLLAPSED_HEIGHT);
    const [isMapExpanded, setIsMapExpanded] = useState(false);

    // Toggle map expansion
    const toggleMapExpansion = () => {
        if (isMapExpanded) {
            mapHeight.value = withSpring(MAP_COLLAPSED_HEIGHT, { damping: 20, stiffness: 150 });
            setIsMapExpanded(false);
        } else {
            mapHeight.value = withSpring(MAP_EXPANDED_HEIGHT, { damping: 20, stiffness: 150 });
            setIsMapExpanded(true);
        }
    };

    // Gesture for expanding/collapsing map
    const mapTapGesture = Gesture.Tap()
        .onEnd(() => {
            runOnJS(toggleMapExpansion)();
        });

    const mapPanGesture = Gesture.Pan()
        .onUpdate((event) => {
            const newHeight = isMapExpanded
                ? MAP_EXPANDED_HEIGHT - event.translationY
                : MAP_COLLAPSED_HEIGHT - event.translationY;
            mapHeight.value = Math.max(MAP_COLLAPSED_HEIGHT, Math.min(MAP_EXPANDED_HEIGHT, newHeight));
        })
        .onEnd((event) => {
            const velocity = event.velocityY;
            const shouldExpand = velocity < -500 || (!isMapExpanded && mapHeight.value > (MAP_COLLAPSED_HEIGHT + MAP_EXPANDED_HEIGHT) / 2);
            const shouldCollapse = velocity > 500 || (isMapExpanded && mapHeight.value < (MAP_COLLAPSED_HEIGHT + MAP_EXPANDED_HEIGHT) / 2);

            if (shouldExpand) {
                mapHeight.value = withSpring(MAP_EXPANDED_HEIGHT, { damping: 20, stiffness: 150 });
                runOnJS(setIsMapExpanded)(true);
            } else if (shouldCollapse) {
                mapHeight.value = withSpring(MAP_COLLAPSED_HEIGHT, { damping: 20, stiffness: 150 });
                runOnJS(setIsMapExpanded)(false);
            } else {
                // Snap back to current state
                mapHeight.value = withSpring(
                    isMapExpanded ? MAP_EXPANDED_HEIGHT : MAP_COLLAPSED_HEIGHT,
                    { damping: 20, stiffness: 150 }
                );
            }
        });

    const mapGesture = Gesture.Race(mapTapGesture, mapPanGesture);

    const animatedMapStyle = useAnimatedStyle(() => ({
        height: mapHeight.value,
    }));

    const animatedHandleStyle = useAnimatedStyle(() => ({
        transform: [{
            rotate: `${interpolate(
                mapHeight.value,
                [MAP_COLLAPSED_HEIGHT, MAP_EXPANDED_HEIGHT],
                [0, 180],
                Extrapolation.CLAMP
            )}deg`
        }],
    }));



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

    // Selected day state: -1 = wishlist, 0+ = itinerary index
    const [selectedDayIndex, setSelectedDayIndex] = useState(-1);
    const [direction, setDirection] = useState(0);

    // Form states
    const [showAddItinerary, setShowAddItinerary] = useState(false);
    const [showAddActivity, setShowAddActivity] = useState(false);
    const [showTodoList, setShowTodoList] = useState(false);
    const [showMembers, setShowMembers] = useState(false);
    const [newItineraryTitle, setNewItineraryTitle] = useState('');
    const [newItineraryDate, setNewItineraryDate] = useState<Date | null>(null);
    const [inviteEmail, setInviteEmail] = useState('');
    const [activityFormData, setActivityFormData] = useState({
        title: '',
        latitude: 0,
        longitude: 0,
        googlePlaceId: null as string | null,
        address: null as string | null,
    });

    // Activity menu
    const [showActivityMenu, setShowActivityMenu] = useState(false);
    const [selectedActivity, setSelectedActivity] = useState<Activity | null>(null);
    const [showAssignSheet, setShowAssignSheet] = useState(false);

    // Queries
    const { data: travel, isLoading, error } = useQuery({
        queryKey: ['travel', id],
        queryFn: () => api.getTravel(id!),
        enabled: !!id,
    });

    const { data: wishlistActivities } = useQuery({
        queryKey: ['travel', id, 'wishlist'],
        queryFn: () => api.getWishlistActivities(id!),
        enabled: !!id,
    });

    const { data: members, isLoading: membersLoading } = useQuery({
        queryKey: ['travel', id, 'members'],
        queryFn: () => api.getTravelMembers(id!),
        enabled: !!id,
    });

    const { data: currentUser } = useQuery({
        queryKey: ['me'],
        queryFn: () => api.getMe(),
    });

    // Sort itineraries by date
    const sortedItineraries = travel?.itineraries?.sort((a, b) => {
        if (!a.date && !b.date) return 0;
        if (!a.date) return 1;
        if (!b.date) return -1;
        return new Date(a.date).getTime() - new Date(b.date).getTime();
    }) || [];

    const selectedItinerary = selectedDayIndex >= 0 ? sortedItineraries[selectedDayIndex] : null;
    const activities = selectedDayIndex === -1 ? (wishlistActivities ?? []) : (selectedItinerary?.activities ?? []);

    const isOwner = members?.some(m => m.userId === currentUser?.id && m.role === 'owner');

    // Mutations
    const createItinerary = useMutation({
        mutationFn: (data: { title: string; date: string | null }) =>
            api.createItinerary({ travelId: id!, ...data }),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['travel', id] });
            setShowAddItinerary(false);
            setNewItineraryTitle('');
            setNewItineraryDate(null);
        },
        onError: (err) => Alert.alert('Erro', err instanceof Error ? err.message : 'Falha ao criar dia'),
    });

    const createActivity = useMutation({
        mutationFn: () => {
            const payload = {
                travelId: id!,
                itineraryId: selectedDayIndex === -1 ? null : selectedItinerary?.id,
                title: activityFormData.title,
                latitude: activityFormData.latitude,
                longitude: activityFormData.longitude,
                googlePlaceId: activityFormData.googlePlaceId,
                address: activityFormData.address,
            };
            console.log('DEBUG: submitting activity:', payload);
            return api.createActivity(payload);
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['travel', id] });
            queryClient.invalidateQueries({ queryKey: ['travel', id, 'wishlist'] });
            setShowAddActivity(false);
            setActivityFormData({ title: '', latitude: 0, longitude: 0, googlePlaceId: null, address: null });
        },
        onError: (err) => Alert.alert('Erro', err instanceof Error ? err.message : 'Falha ao adicionar local'),
    });

    const deleteActivity = useMutation({
        mutationFn: (activityId: string) => api.deleteActivity(activityId),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['travel', id] });
            queryClient.invalidateQueries({ queryKey: ['travel', id, 'wishlist'] });
            setShowActivityMenu(false);
        },
        onError: (err) => Alert.alert('Erro', err instanceof Error ? err.message : 'Falha ao remover'),
    });

    const assignActivity = useMutation({
        mutationFn: (data: { activityId: string; itineraryId: string }) =>
            api.assignActivity(data.activityId, data.itineraryId),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['travel', id] });
            queryClient.invalidateQueries({ queryKey: ['travel', id, 'wishlist'] });
            setShowAssignSheet(false);
            setSelectedActivity(null);
        },
        onError: (err) => Alert.alert('Erro', err instanceof Error ? err.message : 'Falha ao mover'),
    });

    const reorderActivity = useMutation({
        mutationFn: (data: {
            activityId: string;
            afterActivityId: string | null;
            beforeActivityId: string | null;
            newActivities: Activity[]; // Passing for optimistic update
        }) => api.reorderActivity('', {
            activityId: data.activityId,
            afterActivityId: data.afterActivityId,
            beforeActivityId: data.beforeActivityId
        }),
        onMutate: async (newOrder) => {
            // Cancel any outgoing refetches (so they don't overwrite our optimistic update)
            await queryClient.cancelQueries({ queryKey: ['travel', id] });
            await queryClient.cancelQueries({ queryKey: ['travel', id, 'wishlist'] });

            // Snapshot the previous value
            const previousTravel = queryClient.getQueryData(['travel', id]);
            const previousWishlist = queryClient.getQueryData(['travel', id, 'wishlist']);

            // Optimistically update to the new value
            if (selectedDayIndex === -1) {
                // Wishlist update
                queryClient.setQueryData(['travel', id, 'wishlist'], newOrder.newActivities);
            } else {
                // Itinerary update
                queryClient.setQueryData<Travel | undefined>(['travel', id], (old) => {
                    if (!old || !old.itineraries) return old;
                    return {
                        ...old,
                        itineraries: old.itineraries.map((it, idx) => {
                            if (idx === selectedDayIndex) {
                                return { ...it, activities: newOrder.newActivities };
                            }
                            return it;
                        }),
                    };
                });
            }

            // Return a context object with the snapshotted value
            return { previousTravel, previousWishlist };
        },
        onError: (err, newOrder, context) => {
            if (context?.previousTravel) {
                queryClient.setQueryData(['travel', id], context.previousTravel);
            }
            if (context?.previousWishlist) {
                queryClient.setQueryData(['travel', id, 'wishlist'], context.previousWishlist);
            }
            Alert.alert('Erro', 'Falha ao reordenar locais');
        },
        onSettled: () => {
            // We can choose NOT to invalidate immediately to keep the UI stable,
            // or invalidate to ensure eventual consistency.
            // Given the lag report, let's wait a bit or rely on the successful mutation.
            // For now, let's invalidate to be safe but the optimistic update should hold.
            queryClient.invalidateQueries({ queryKey: ['travel', id] });
            queryClient.invalidateQueries({ queryKey: ['travel', id, 'wishlist'] });
        },
    });

    const inviteMember = useMutation({
        mutationFn: (email: string) => api.inviteMember(id!, email),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['travel', id, 'members'] });
            setInviteEmail('');
        },
        onError: (err) => Alert.alert('Erro', err instanceof Error ? err.message : 'Falha ao convidar'),
    });

    const removeMember = useMutation({
        mutationFn: (memberId: string) => api.removeMember(id!, memberId),
        onSuccess: () => queryClient.invalidateQueries({ queryKey: ['travel', id, 'members'] }),
        onError: (err) => Alert.alert('Erro', err instanceof Error ? err.message : 'Falha ao remover'),
    });

    // Format date
    const formatItineraryDate = (dateStr: string | null) => {
        if (!dateStr) return 'Sem data';
        try {
            const date = parseISO(dateStr);
            return format(date, "EEEE, d 'de' MMMM", { locale: ptBR });
        } catch {
            return dateStr;
        }
    };

    if (isLoading) {
        return (
            <View style={styles.centered}>
                <ActivityIndicator size="large" color={Colors.text.primary} />
            </View>
        );
    }

    if (error || !travel) {
        return (
            <View style={styles.centered}>
                <Text style={styles.errorText}>Falha ao carregar viagem</Text>
            </View>
        );
    }

    return (
        <GestureHandlerRootView style={styles.container}>
            {/* Header */}
            {/* Header Buttons (Fixed) */}
            <View style={{
                position: 'absolute',
                top: insets.top + 10,
                left: 24,
                right: 24,
                zIndex: 100,
                flexDirection: 'row',
                justifyContent: 'space-between',
                alignItems: 'center'
            }}>
                <TouchableOpacity
                    onPress={() => router.back()}
                    style={styles.headerButton}
                >
                    <Ionicons name="arrow-back" size={24} color={Colors.black} />
                </TouchableOpacity>
                {/* Members Section - Simply Avatars */}
                {members && members.length > 0 && (
                    <TouchableOpacity
                        style={{ marginTop: 12 }}
                        onPress={() => setShowMembers(true)}
                        activeOpacity={0.7}
                    >
                        <View style={styles.memberAvatars}>
                            {members.slice(0, 5).map((member, index) => (
                                <View
                                    key={member.id}
                                    style={[
                                        styles.memberAvatarWrapper,
                                        { marginLeft: index > 0 ? -12 : 0, zIndex: members.length - index }
                                    ]}
                                >
                                    {member.user?.profilePhotoUrl ? (
                                        <Image
                                            source={{ uri: member.user.profilePhotoUrl }}
                                            style={styles.memberAvatar}
                                        />
                                    ) : (
                                        <View style={[styles.memberAvatar, styles.memberAvatarFallback]}>
                                            <Text style={styles.memberAvatarText}>
                                                {(member.user?.name || member.user?.email || '?').charAt(0).toUpperCase()}
                                            </Text>
                                        </View>
                                    )}
                                </View>
                            ))}
                            {members.length > 5 && (
                                <View style={[styles.memberAvatarWrapper, { marginLeft: -12, zIndex: 0 }]}>
                                    <View style={[styles.memberAvatar, styles.memberAvatarMore]}>
                                        <Text style={styles.memberAvatarMoreText}>+{members.length - 5}</Text>
                                    </View>
                                </View>
                            )}
                            <View style={[styles.memberAvatarWrapper, { marginLeft: -12, zIndex: 0, backgroundColor: Colors.white }]}>
                                <View style={[styles.memberAvatar, styles.memberAvatarFallback, { backgroundColor: Colors.border.light }]}>
                                    <Ionicons name="add" size={20} color={Colors.black} />
                                </View>
                            </View>
                        </View>
                    </TouchableOpacity>
                )}
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
                <Text style={styles.bigTitle}>{travel.title}</Text>
                <Text style={styles.subtitle}>
                    {travel.startDate && travel.endDate
                        ? `${format(new Date(travel.startDate), "d MMM", { locale: ptBR })} - ${format(new Date(travel.endDate), "d MMM, yyyy", { locale: ptBR })}`
                        : 'Sem data definida'
                    }
                </Text>
            </Animated.View>

            {/* Main Content */}
            <Animated.View
                style={{ flex: 1 }}
                key={selectedDayIndex}
                entering={FadeIn}
                exiting={FadeOut}
            >
                <Animated.ScrollView
                    style={styles.content}
                    contentContainerStyle={{
                        paddingTop: insets.top + 160, // Space for expanded header
                        paddingBottom: MAP_COLLAPSED_HEIGHT + 40
                    }}
                    onScroll={scrollHandler}
                    scrollEventThrottle={16}
                >
                    {/* Date Display */}
                    {selectedDayIndex === -1 ? (
                        <Text style={styles.dateText}>Lista de Desejos</Text>
                    ) : selectedItinerary && (
                        <Text style={styles.dateText}>
                            {formatItineraryDate(selectedItinerary.date)}
                        </Text>
                    )}

                    {/* Day Selector with Wishlist */}
                    <ScrollView
                        horizontal
                        showsHorizontalScrollIndicator={false}
                        contentContainerStyle={styles.daySelector}
                    >
                        {/* Todo List Button */}
                        <TouchableOpacity
                            onPress={() => setShowTodoList(true)}
                            style={styles.dayCircle}
                        >
                            <Ionicons
                                name="checkbox-outline"
                                size={20}
                                color={Colors.black}
                            />
                        </TouchableOpacity>

                        {/* Wishlist Circle */}
                        <TouchableOpacity
                            onPress={() => {
                                setDirection(selectedDayIndex > -1 ? -1 : 0);
                                setSelectedDayIndex(-1);
                            }}
                            style={[
                                styles.dayCircle,
                                selectedDayIndex === -1 && styles.dayCircleActive
                            ]}
                        >
                            <Ionicons
                                name="heart"
                                size={20}
                                color={selectedDayIndex === -1 ? Colors.text.primary : Colors.text.primary}
                            />
                        </TouchableOpacity>

                        {/* Day Circles */}
                        {sortedItineraries.map((it, index) => {
                            const date = it.date ? parseISO(it.date) : null;
                            const dayOfWeek = date ? format(date, 'EEEEEE', { locale: ptBR }).toUpperCase() : null;
                            const dayOfMonth = date ? format(date, 'd', { locale: ptBR }) : (index + 1).toString();

                            return (
                                <TouchableOpacity
                                    key={it.id}
                                    onPress={() => {
                                        setDirection(index > selectedDayIndex ? 1 : -1);
                                        setSelectedDayIndex(index);
                                    }}
                                    style={[
                                        styles.dayCircle,
                                        index === selectedDayIndex && styles.dayCircleActive
                                    ]}
                                >
                                    {dayOfWeek && (
                                        <Text style={[
                                            styles.dayLabel,
                                            index === selectedDayIndex && styles.dayLabelActive
                                        ]}>
                                            {dayOfWeek}
                                        </Text>
                                    )}
                                    <Text style={[
                                        styles.dayText,
                                        index === selectedDayIndex && styles.dayTextActive
                                    ]}>
                                        {dayOfMonth}
                                    </Text>
                                </TouchableOpacity>
                            );
                        })}

                        {/* Add Day Button */}
                        <TouchableOpacity
                            onPress={() => setShowAddItinerary(true)}
                            style={styles.addDayCircle}
                        >
                            <Ionicons name="add" size={24} color={Colors.text.secondary} />
                        </TouchableOpacity>
                    </ScrollView>

                    {/* Activities Section */}
                    <View style={styles.section}>
                        <View style={styles.sectionHeader}>
                            <Text style={styles.sectionTitle}>
                                {selectedDayIndex === -1 ? 'LISTA DE DESEJOS' : 'ROTEIRO'}
                            </Text>
                            <TouchableOpacity onPress={() => setShowAddActivity(true)}>
                                <Ionicons name="add-circle" size={28} color={Colors.black} />
                            </TouchableOpacity>
                        </View>

                        {activities.length === 0 ? (
                            <View style={styles.emptyState}>
                                <Text style={styles.emptyText}>
                                    {selectedDayIndex === -1 ? 'Nenhum local na lista' : 'Nenhum local adicionado'}
                                </Text>
                                <Text style={styles.emptySubtext}>Toque no + para adicionar</Text>
                            </View>
                        ) : (
                            // Draggable list for both wishlist and itinerary
                            <GestureHandlerRootView style={{ flex: 1 }}>
                                <DraggableFlatList
                                    data={activities}
                                    scrollEnabled={false}
                                    keyExtractor={(item) => item.id}
                                    onDragEnd={({ data, from, to }) => {
                                        if (from !== to && data[to]) {
                                            // Get the activity that was moved
                                            const movedActivity = data[to];
                                            // Get before/after activity IDs for reorder API
                                            const afterActivityId = to > 0 ? data[to - 1]?.id : null;
                                            const beforeActivityId = to < data.length - 1 ? data[to + 1]?.id : null;

                                            reorderActivity.mutate({
                                                activityId: movedActivity.id,
                                                afterActivityId,
                                                beforeActivityId,
                                                newActivities: data, // Pass the new order for optimistic update
                                            });
                                        }
                                    }}
                                    renderItem={({ item, getIndex, drag, isActive }: RenderItemParams<Activity>) => {
                                        return (
                                            <ScaleDecorator>
                                                <TouchableOpacity
                                                    style={[styles.activityCard, isActive && styles.activityCardActive]}
                                                    onPress={() => {
                                                        const targetItineraryId = selectedItinerary?.id || 'wishlist';
                                                        router.push(`/(app)/travel/${id}/itinerary/activity/${item.id}?itineraryId=${targetItineraryId}`);
                                                    }}
                                                    onLongPress={drag}
                                                >
                                                    <TouchableOpacity onPressIn={drag} style={styles.dragHandle}>
                                                        <Ionicons name="reorder-two" size={20} color={Colors.border.medium} />
                                                    </TouchableOpacity>
                                                    <Text style={styles.activityTitle} numberOfLines={1}>
                                                        {item.title}
                                                    </Text>
                                                    {selectedDayIndex === -1 ? (
                                                        <Ionicons name="chevron-forward" size={20} color={Colors.border.medium} />
                                                    ) : (
                                                        <Ionicons name="chevron-forward" size={20} color={Colors.border.medium} />
                                                    )}
                                                </TouchableOpacity>
                                            </ScaleDecorator>
                                        );
                                    }}
                                />
                            </GestureHandlerRootView>
                        )}
                    </View>

                </Animated.ScrollView>
            </Animated.View>

            {/* Expandable Map at Bottom */}
            <Animated.View style={[styles.fixedMapContainer, { bottom: insets.bottom }, animatedMapStyle]}>
                {/* Drag Handle */}
                <GestureDetector gesture={mapGesture}>
                    <Animated.View style={styles.mapDragHandleContainer}>
                        <View style={styles.mapDragHandlePill} />
                        <View style={styles.mapHeaderRow}>
                            <Text style={styles.mapTitle}>MAPA</Text>
                            <Animated.View style={animatedHandleStyle}>
                                <Ionicons name="chevron-up" size={20} color={Colors.text.secondary} />
                            </Animated.View>
                        </View>
                    </Animated.View>
                </GestureDetector>

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
            </Animated.View>

            {/* Add Day/Itinerary Sheet */}
            <SheetForm
                isOpen={showAddItinerary}
                onClose={() => {
                    setShowAddItinerary(false);
                    setNewItineraryTitle('');
                    setNewItineraryDate(null);
                }}
                title="Adicionar Dia"
                onSubmit={() => newItineraryTitle.trim() && createItinerary.mutate({
                    title: newItineraryTitle.trim(),
                    date: newItineraryDate ? newItineraryDate.toISOString().split('T')[0] : null,
                })}
                isSubmitting={createItinerary.isPending}
                submitLabel="Adicionar"
            >
                <VStack space="md">
                    <Input>
                        <InputField
                            placeholder="Nome do dia (ex: Dia 1 - Centro)"
                            value={newItineraryTitle}
                            onChangeText={setNewItineraryTitle}
                            autoFocus
                        />
                    </Input>
                    <DatePickerInput
                        label="DATA"
                        value={newItineraryDate}
                        onChange={setNewItineraryDate}
                        minDate={travel.startDate ? new Date(travel.startDate) : undefined}
                        maxDate={travel.endDate ? new Date(travel.endDate) : undefined}
                    />
                </VStack>
            </SheetForm>

            {/* Add Activity Sheet */}
            <SheetForm
                isOpen={showAddActivity}
                onClose={() => {
                    setShowAddActivity(false);
                    setActivityFormData({ title: '', latitude: 0, longitude: 0, googlePlaceId: null, address: null });
                }}
                title={selectedDayIndex === -1 ? "Adicionar à Lista" : "Adicionar Local"}
                onSubmit={() => activityFormData.title && createActivity.mutate()}
                isSubmitting={createActivity.isPending}
                submitLabel="Adicionar"
            >
                <VStack space="md">
                    <PlaceAutocomplete
                        onSelect={(place) => {
                            console.log('DEBUG: Place selected:', place);
                            setActivityFormData({
                                title: place.name,
                                latitude: place.latitude ?? place.lat ?? 0,
                                longitude: place.longitude ?? place.lon ?? 0,
                                googlePlaceId: place.placeId,
                                address: place.address || null,
                            });
                        }}
                    />
                    {activityFormData.title && (
                        <View style={styles.selectedPlace}>
                            <Ionicons name="location" size={16} color={Colors.black} />
                            <Text style={styles.selectedPlaceText}>{activityFormData.title}</Text>
                        </View>
                    )}
                </VStack>
            </SheetForm>

            {/* Activity Menu */}
            <Actionsheet isOpen={showActivityMenu} onClose={() => setShowActivityMenu(false)}>
                <ActionsheetBackdrop />
                <ActionsheetContent>
                    <Text style={styles.sheetTitle}>{selectedActivity?.title}</Text>
                    {selectedDayIndex === -1 && (
                        <ActionsheetItem onPress={() => {
                            setShowActivityMenu(false);
                            setShowAssignSheet(true);
                        }}>
                            <ActionsheetItemText>Mover para roteiro</ActionsheetItemText>
                        </ActionsheetItem>
                    )}
                    <ActionsheetItem onPress={() => {
                        setShowActivityMenu(false);
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
                    }}>
                        <ActionsheetItemText style={{ color: Colors.text.error }}>Remover</ActionsheetItemText>
                    </ActionsheetItem>
                </ActionsheetContent>
            </Actionsheet>

            {/* Assign to Itinerary Sheet */}
            <Actionsheet isOpen={showAssignSheet} onClose={() => setShowAssignSheet(false)}>
                <ActionsheetBackdrop />
                <ActionsheetContent>
                    <Text style={styles.sheetTitle}>
                        Mover "{selectedActivity?.title}" para:
                    </Text>
                    {sortedItineraries.map((itinerary, idx) => (
                        <ActionsheetItem
                            key={itinerary.id}
                            onPress={() => {
                                if (selectedActivity) {
                                    assignActivity.mutate({
                                        activityId: selectedActivity.id,
                                        itineraryId: itinerary.id,
                                    });
                                }
                            }}
                        >
                            <ActionsheetItemText>
                                Dia {idx + 1}: {itinerary.title}
                            </ActionsheetItemText>
                        </ActionsheetItem>
                    ))}
                    {sortedItineraries.length === 0 && (
                        <View style={{ padding: 16, alignItems: 'center' }}>
                            <Text style={{ color: Colors.text.secondary }}>Crie um dia primeiro</Text>
                        </View>
                    )}
                </ActionsheetContent>
            </Actionsheet>

            {/* Members Sheet */}
            <SheetForm
                isOpen={showMembers}
                onClose={() => setShowMembers(false)}
                title="Membros"
                onSubmit={() => {
                    if (inviteEmail.trim()) {
                        inviteMember.mutate(inviteEmail.trim());
                    } else {
                        setShowMembers(false);
                    }
                }}
                isSubmitting={inviteMember.isPending}
                submitLabel={inviteEmail.trim() ? "Convidar" : "OK"}
            >
                <VStack space="lg">
                    <VStack space="xs">
                        <Text style={styles.inputLabel}>Convidar por email</Text>
                        <Input>
                            <InputField
                                placeholder="email@exemplo.com"
                                value={inviteEmail}
                                onChangeText={setInviteEmail}
                                autoCapitalize="none"
                                keyboardType="email-address"
                            />
                        </Input>
                    </VStack>

                    <VStack space="md">
                        <Text style={styles.sectionTitleSmall}>Membros Atuais</Text>
                        {membersLoading ? (
                            <ActivityIndicator />
                        ) : (
                            members?.map((member) => (
                                <View key={member.id} style={styles.memberItem}>
                                    <HStack space="md" alignItems="center" style={{ flex: 1 }}>
                                        {member.user?.profilePhotoUrl ? (
                                            <Image
                                                source={{ uri: member.user.profilePhotoUrl }}
                                                style={styles.memberListAvatar}
                                            />
                                        ) : (
                                            <View style={[styles.memberListAvatar, styles.memberListAvatarFallback]}>
                                                <Text style={styles.memberListAvatarText}>
                                                    {(member.user?.name || member.user?.email || '?').charAt(0).toUpperCase()}
                                                </Text>
                                            </View>
                                        )}
                                        <VStack>
                                            <Text style={styles.memberName}>{member.user?.name || 'Usuário'}</Text>
                                            <Text style={styles.memberEmail}>{member.user?.email}</Text>
                                        </VStack>
                                    </HStack>
                                    {member.role === 'owner' && (
                                        <View style={styles.ownerBadge}>
                                            <Text style={styles.ownerBadgeText}>Dono</Text>
                                        </View>
                                    )}
                                    {isOwner && member.role !== 'owner' && (
                                        <TouchableOpacity
                                            onPress={() => Alert.alert(
                                                'Remover',
                                                `Remover ${member.user?.name}?`,
                                                [
                                                    { text: 'Cancelar', style: 'cancel' },
                                                    { text: 'Remover', style: 'destructive', onPress: () => removeMember.mutate(member.id) }
                                                ]
                                            )}
                                            style={styles.removeMemberBtn}
                                        >
                                            <Ionicons name="close" size={18} color={Colors.text.error} />
                                        </TouchableOpacity>
                                    )}
                                </View>
                            ))
                        )}
                    </VStack>
                </VStack>
            </SheetForm>

            <TodoList
                isOpen={showTodoList}
                onClose={() => setShowTodoList(false)}
                travelId={id!}
            />
        </GestureHandlerRootView>
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
    sheetTitle: {
        fontSize: 18,
        fontWeight: '600',
        color: Colors.text.primary,
        marginBottom: 16,
        paddingHorizontal: 16,
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
        gap: 2, // Spacing between label and number
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
    sectionTitleSmall: {
        fontSize: 13,
        fontWeight: '600',
        color: Colors.text.secondary,
    },
    activityCard: {
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: Colors.white,
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
        color: Colors.text.secondary,
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
        left: 10,
        right: 10,
        backgroundColor: Colors.white,
        borderTopLeftRadius: 24,
        borderTopRightRadius: 24,
        borderBottomLeftRadius: 24,
        borderBottomRightRadius: 24,
        shadowColor: Colors.black,
        shadowOffset: { width: 0, height: -4 },
        shadowOpacity: 0.1,
        shadowRadius: 12,
        elevation: 10,
        overflow: 'hidden',
    },
    mapDragHandleContainer: {
        paddingTop: 12,
        paddingBottom: 8,
        paddingHorizontal: 24,
        backgroundColor: Colors.white,
    },
    mapDragHandlePill: {
        width: 36,
        height: 4,
        backgroundColor: Colors.border.light,
        borderRadius: 2,
        alignSelf: 'center',
        marginBottom: 12,
    },
    mapHeaderRow: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
    },
    mapTitle: {
        fontSize: 14,
        fontWeight: '700',
        color: Colors.text.primary,
        letterSpacing: 1,
    },
    mapWrapper: {
        flex: 1,
        marginHorizontal: 16,
        marginBottom: 16,
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
    selectedPlace: {
        flexDirection: 'row',
        alignItems: 'center',
        backgroundColor: Colors.successLight,
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
    inputLabel: {
        fontSize: 13,
        fontWeight: '600',
        color: Colors.text.secondary,
    },
    memberItem: {
        flexDirection: 'row',
        alignItems: 'center',
        paddingVertical: 12,
        borderBottomWidth: 1,
        borderBottomColor: Colors.border.light,
    },
    bigTitle: {
        fontSize: 34,
        fontWeight: '700',
        color: Colors.black,
        marginTop: 0,
        marginBottom: 4,
        fontFamily: 'Serif',
    },
    subtitle: {
        fontSize: 15,
        color: Colors.text.secondary,
        fontWeight: '500',
    },

    memberAvatars: {
        flexDirection: 'row',
        alignItems: 'center',
    },
    memberAvatarWrapper: {
        borderRadius: 20,
        borderWidth: 2,
        borderColor: Colors.white,
    },
    memberAvatar: {
        width: 36,
        height: 36,
        borderRadius: 18,
    },
    memberAvatarFallback: {
        backgroundColor: Colors.text.primary,
        alignItems: 'center',
        justifyContent: 'center',
    },
    memberAvatarText: {
        color: Colors.white,
        fontSize: 14,
        fontWeight: '600',
    },
    memberAvatarMore: {
        backgroundColor: Colors.border.light,
        alignItems: 'center',
        justifyContent: 'center',
    },
    memberAvatarMoreText: {
        color: Colors.text.secondary,
        fontSize: 12,
        fontWeight: '600',
    },

    headerButton: {
        width: 40,
        height: 40,
        borderRadius: 20,
        backgroundColor: Colors.white,
        alignItems: 'center',
        justifyContent: 'center',
        shadowColor: Colors.black,
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 8,
        elevation: 3,
    },
    memberName: {
        fontSize: 15,
        fontWeight: '600',
        color: Colors.text.primary,
    },
    memberEmail: {
        fontSize: 13,
        color: Colors.text.secondary,
    },
    memberListAvatar: {
        width: 40,
        height: 40,
        borderRadius: 20,
    },
    memberListAvatarFallback: {
        backgroundColor: Colors.text.primary,
        alignItems: 'center',
        justifyContent: 'center',
    },
    memberListAvatarText: {
        color: Colors.white,
        fontSize: 16,
        fontWeight: '600',
    },
    ownerBadge: {
        backgroundColor: Colors.successLight,
        paddingHorizontal: 10,
        paddingVertical: 4,
        borderRadius: 12,
    },
    ownerBadgeText: {
        fontSize: 12,
        fontWeight: '600',
        color: Colors.success,
    },
    removeMemberBtn: {
        padding: 8,
        backgroundColor: 'rgba(255,59,48,0.1)',
        borderRadius: 8,
    },
    errorText: {
        fontSize: 16,
        color: Colors.text.secondary,
    },
    dragHandle: {
        padding: 4,
        marginRight: 4,
    },
    activityCardActive: {
        backgroundColor: Colors.successLight,
        transform: [{ scale: 1.02 }],
    },
});
