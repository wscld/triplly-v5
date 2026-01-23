import { View, Text, TouchableOpacity, StyleSheet, Alert, ScrollView, ActivityIndicator, Dimensions, Image } from 'react-native';
import { GestureHandlerRootView, GestureDetector, Gesture } from 'react-native-gesture-handler';
import DraggableFlatList, { ScaleDecorator, RenderItemParams } from 'react-native-draggable-flatlist';
import Animated, { FadeIn, FadeOut, runOnJS, useSharedValue, useAnimatedStyle, withSpring, interpolate, Extrapolation, useAnimatedScrollHandler } from 'react-native-reanimated';
import { useLocalSearchParams, router } from 'expo-router';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Ionicons } from '@expo/vector-icons';
import { api } from '@/lib/api';
import type { Activity, Travel, TravelMember, Itinerary } from '@/lib/types';
import { useState, useRef } from 'react';
import SheetForm from '@/components/SheetForm';
import TodoList from '@/components/TodoList';
import PlaceAutocomplete from '@/components/PlaceAutocomplete';
import ItineraryMap from '@/components/ItineraryMap';
import TravelDetailSkeleton from '@/components/TravelDetailSkeleton';
import DateRangePicker from '@/components/DateRangePicker';
import { VStack, HStack, Input, InputField, Button, ButtonText } from '@gluestack-ui/themed';
import { BottomSheetModal, BottomSheetView, BottomSheetBackdrop, BottomSheetTextInput } from '@gorhom/bottom-sheet';
import { Colors } from '@/constants/colors';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import DatePickerInput from '@/components/DatePickerInput';
import { format, parseISO } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import * as ImagePicker from 'expo-image-picker';

// Helper to parse date strings without timezone shift
// Appending T12:00:00 ensures the date stays correct regardless of local timezone
const parseDateSafe = (dateStr: string | null | undefined): Date | null => {
    if (!dateStr) return null;
    return parseISO(`${dateStr}T12:00:00`);
};

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
            mapHeight.value = withSpring(MAP_COLLAPSED_HEIGHT, { damping: 30, stiffness: 150 });
            setIsMapExpanded(false);
        } else {
            mapHeight.value = withSpring(MAP_EXPANDED_HEIGHT, { damping: 30, stiffness: 150 });
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
                mapHeight.value = withSpring(MAP_EXPANDED_HEIGHT, { damping: 30, stiffness: 150 });
                runOnJS(setIsMapExpanded)(true);
            } else if (shouldCollapse) {
                mapHeight.value = withSpring(MAP_COLLAPSED_HEIGHT, { damping: 30, stiffness: 150 });
                runOnJS(setIsMapExpanded)(false);
            } else {
                // Snap back to current state
                mapHeight.value = withSpring(
                    isMapExpanded ? MAP_EXPANDED_HEIGHT : MAP_COLLAPSED_HEIGHT,
                    { damping: 30, stiffness: 150 }
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

    const imageAnimatedStyle = useAnimatedStyle(() => {
        return {
            transform: [
                { translateY: interpolate(scrollY.value, [-300, 0, 300], [150, 0, -150]) },
                { scale: interpolate(scrollY.value, [-300, 0], [2, 1], Extrapolation.CLAMP) }
            ]
        };
    });
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

    // Edit Travel State
    const [showEditSheet, setShowEditSheet] = useState(false);
    const [editFormData, setEditFormData] = useState({
        title: '',
        startDate: null as Date | null,
        endDate: null as Date | null,
        coverImage: null as ImagePicker.ImagePickerAsset | null,
        latitude: null as number | null,
        longitude: null as number | null,
    });

    const [activityFormData, setActivityFormData] = useState({
        title: '',
        latitude: 0,
        longitude: 0,
        googlePlaceId: null as string | null,
        address: null as string | null,
    });

    // Activity menu
    const activityMenuRef = useRef<BottomSheetModal>(null);
    const [selectedActivity, setSelectedActivity] = useState<Activity | null>(null);
    const assignSheetRef = useRef<BottomSheetModal>(null);

    // Itinerary edit menu
    const itineraryMenuRef = useRef<BottomSheetModal>(null);
    const [selectedItineraryForEdit, setSelectedItineraryForEdit] = useState<Itinerary | null>(null);
    const [showEditItinerary, setShowEditItinerary] = useState(false);
    const [editItineraryData, setEditItineraryData] = useState({
        title: '',
        date: null as Date | null,
    });

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
    const updateTravel = useMutation({
        mutationFn: async () => {
            // 1. Update text details
            await api.updateTravel(id!, {
                title: editFormData.title,
                startDate: editFormData.startDate?.toISOString().split('T')[0] ?? null,
                endDate: editFormData.endDate?.toISOString().split('T')[0] ?? null,
                latitude: editFormData.latitude,
                longitude: editFormData.longitude,
            });

            // 2. Upload image if changed
            if (editFormData.coverImage) {
                await api.uploadTravelCover(id!, editFormData.coverImage);
            }
        },
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['travel', id] });
            setShowEditSheet(false);
            setEditFormData({ title: '', startDate: null, endDate: null, coverImage: null, latitude: null, longitude: null });
        },
        onError: (err) => Alert.alert('Erro', 'Falha ao atualizar viagem'),
    });

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

    const deleteItinerary = useMutation({
        mutationFn: (itineraryId: string) => api.deleteItinerary(itineraryId),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['travel', id] });
            itineraryMenuRef.current?.dismiss();
            setSelectedItineraryForEdit(null);
            setSelectedDayIndex(-1); // Go back to wishlist
        },
        onError: (err) => Alert.alert('Erro', err instanceof Error ? err.message : 'Falha ao excluir dia'),
    });

    const updateItinerary = useMutation({
        mutationFn: () => api.updateItinerary(selectedItineraryForEdit!.id, {
            title: editItineraryData.title,
            date: editItineraryData.date ? format(editItineraryData.date, 'yyyy-MM-dd') : null,
        }),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['travel', id] });
            setShowEditItinerary(false);
            setSelectedItineraryForEdit(null);
        },
        onError: (err) => Alert.alert('Erro', err instanceof Error ? err.message : 'Falha ao atualizar dia'),
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
            activityMenuRef.current?.dismiss();
        },
        onError: (err) => Alert.alert('Erro', err instanceof Error ? err.message : 'Falha ao remover'),
    });

    const assignActivity = useMutation({
        mutationFn: (data: { activityId: string; itineraryId: string }) =>
            api.assignActivity(data.activityId, data.itineraryId),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['travel', id] });
            queryClient.invalidateQueries({ queryKey: ['travel', id, 'wishlist'] });
            assignSheetRef.current?.dismiss();
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
                        itineraries: old.itineraries.map((it: Itinerary, idx: number) => {
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
        mutationFn: (email: string) => api.inviteMember(id!, email, 'viewer'),
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
        return <TravelDetailSkeleton />;
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

            {/* Travel Cover Image */}
            <Animated.View style={[{ position: 'absolute', top: 0, left: 0, right: 0, height: 310 }, imageAnimatedStyle]}>
                {travel.coverImageUrl ? (
                    <Image
                        source={{ uri: travel.coverImageUrl }}
                        style={{ width: '100%', height: '100%' }}
                        resizeMode="cover"
                    />
                ) : (
                    <View style={{ width: '100%', height: '100%', backgroundColor: Colors.border.light }} />
                )}
                {/* Gradient Overlay for text readability */}
                <View style={{
                    position: 'absolute',
                    top: 0, left: 0, right: 0, bottom: 0,
                    backgroundColor: 'rgba(0,0,0,0.3)'
                }} />

            </Animated.View>

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
                <Text style={[styles.bigTitle, { color: Colors.white }]}>{travel.title}</Text>
                <Text style={[styles.subtitle, { color: Colors.white }]}>
                    {travel.startDate && travel.endDate
                        ? `${format(parseDateSafe(travel.startDate)!, "d MMM", { locale: ptBR })} - ${format(parseDateSafe(travel.endDate)!, "d MMM, yyyy", { locale: ptBR })}`
                        : 'Sem data definida'
                    }
                </Text>

                {/* Edit Travel Button */}
                {isOwner && (
                    <TouchableOpacity
                        onPress={() => {
                            if (travel) {
                                setEditFormData({
                                    title: travel.title,
                                    startDate: parseDateSafe(travel.startDate),
                                    endDate: parseDateSafe(travel.endDate),
                                    coverImage: null,
                                    latitude: travel.latitude ?? null,
                                    longitude: travel.longitude ?? null,
                                });
                                setShowEditSheet(true);
                            }
                        }}
                        style={{
                            flexDirection: 'row',
                            alignItems: 'center',
                            marginTop: 12,
                            backgroundColor: 'rgba(255,255,255,0.2)',
                            paddingHorizontal: 12,
                            paddingVertical: 6,
                            borderRadius: 16,
                            alignSelf: 'flex-start'
                        }}
                    >
                        <Ionicons name="pencil" size={14} color={Colors.white} />
                        <Text style={{ color: Colors.white, marginLeft: 6, fontWeight: '600', fontSize: 13 }}>Editar viagem</Text>
                    </TouchableOpacity>
                )}
            </Animated.View>



            {/* Main Content */}
            <View
                style={{ flex: 1 }}
            >
                <Animated.ScrollView
                    style={styles.content}
                    contentContainerStyle={{
                        paddingBottom: MAP_COLLAPSED_HEIGHT + 40
                    }}
                    onScroll={scrollHandler}
                    scrollEventThrottle={16}
                >
                    {/* Spacer for Parallax Header */}
                    <View style={{ height: 280 }} />

                    {/* Content Wrapper */}
                    <View style={{
                        backgroundColor: Colors.background,
                        borderTopLeftRadius: 32,
                        borderTopRightRadius: 32,
                        paddingTop: 14,
                        paddingBottom: 100
                    }}>

                        {selectedItinerary?.title ? (
                            <Text style={[styles.dateText, { fontWeight: '800', fontSize: 18, marginBottom: -12 }]}>{selectedItinerary?.title}</Text>
                        ) : (
                            null
                        )}

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
                                        onLongPress={() => {
                                            setSelectedItineraryForEdit(it);
                                            itineraryMenuRef.current?.present();
                                        }}
                                        delayLongPress={300}
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
                                    <Text style={styles.emptyStateSubtext}>Clique em &quot;+&quot; para adicionar atividades</Text>
                                </View>
                            ) : (
                                <GestureHandlerRootView style={{ flex: 1 }}>
                                    <DraggableFlatList
                                        key={`draggable-${selectedDayIndex}`}
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
                                            const index = getIndex() ?? 0;
                                            const isFirst = index === 0;
                                            const isLast = index === activities.length - 1;

                                            return (
                                                <ScaleDecorator>
                                                    <View style={styles.timelineRow}>
                                                        {/* Timeline line and dot - hidden when dragging */}
                                                        {!isActive && (
                                                            <View style={styles.timelineContainer}>
                                                                {!isFirst && <View style={styles.timelineLineTop} />}
                                                                <View style={styles.timelineDot} />
                                                                {!isLast && <View style={styles.timelineLineBottom} />}
                                                            </View>
                                                        )}

                                                        {/* Activity Card */}
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
                                                            <Ionicons name="chevron-forward" size={20} color={Colors.border.medium} />
                                                        </TouchableOpacity>
                                                    </View>
                                                </ScaleDecorator>
                                            );
                                        }}
                                    />
                                </GestureHandlerRootView>
                            )}
                        </View>

                    </View>
                </Animated.ScrollView>
            </View>

            {/* Expandable Map at Bottom */}
            <Animated.View style={[styles.fixedMapContainer, { bottom: insets.bottom }, animatedMapStyle]}>
                {/* Drag Handle */}
                <GestureDetector gesture={mapGesture}>
                    <Animated.View style={styles.mapDragHandleContainer}>
                        <View style={styles.sheetHandle} />
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
                            <Ionicons name="map" size={22} color={Colors.text.secondary} />
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
                    <BottomSheetTextInput
                        style={styles.sheetInput}
                        placeholder="Nome do dia (ex: Dia 1 - Centro)"
                        value={newItineraryTitle}
                        onChangeText={setNewItineraryTitle}
                        placeholderTextColor={Colors.text.secondary}
                    />
                    <DatePickerInput
                        label="DATA"
                        value={newItineraryDate}
                        onChange={setNewItineraryDate}
                        minDate={parseDateSafe(travel.startDate) ?? undefined}
                        maxDate={parseDateSafe(travel.endDate) ?? undefined}
                        initialMonth={parseDateSafe(travel.startDate) ?? undefined}
                    />
                </VStack>
            </SheetForm>

            {/* Edit Travel Sheet */}
            <SheetForm
                isOpen={showEditSheet}
                onClose={() => setShowEditSheet(false)}
                title="Editar Viagem"
                onSubmit={() => editFormData.title && updateTravel.mutate()}
                isSubmitting={updateTravel.isPending}
                submitLabel="Salvar"
            >
                <VStack space="md">
                    <VStack space="xs">
                        <Text style={{ fontSize: 12, color: Colors.text.secondary, marginBottom: 4, fontWeight: '600' }}>DESTINO</Text>
                        <PlaceAutocomplete
                            placeholder="Para onde você vai?"
                            initialValue={editFormData.title}
                            onSelect={(place) => {
                                setEditFormData(prev => ({
                                    ...prev,
                                    title: place.name,
                                    latitude: place.lat ?? place.latitude ?? null,
                                    longitude: place.lon ?? place.longitude ?? null,
                                }));
                            }}
                        />
                    </VStack>

                    <DateRangePicker
                        startDate={editFormData.startDate}
                        endDate={editFormData.endDate}
                        onChange={({ startDate, endDate }) => setEditFormData(prev => ({ ...prev, startDate, endDate }))}
                        label="DATAS DA VIAGEM"
                    />

                    {/* Image Picker in Edit Form */}
                    <View>
                        <Text style={{ fontSize: 12, color: Colors.text.secondary, marginBottom: 8, fontWeight: '600' }}>CAPA DA VIAGEM</Text>
                        <TouchableOpacity
                            onPress={async () => {
                                try {
                                    const result = await ImagePicker.launchImageLibraryAsync({
                                        mediaTypes: ImagePicker.MediaTypeOptions.Images,
                                        allowsEditing: true,
                                        aspect: [16, 9],
                                        quality: 0.8,
                                    });
                                    if (!result.canceled && result.assets[0]) {
                                        setEditFormData(prev => ({ ...prev, coverImage: result.assets[0] }));
                                    }
                                } catch (err) {
                                    Alert.alert('Erro', 'Falha ao selecionar imagem');
                                }
                            }}
                            style={{
                                height: 120,
                                borderRadius: 12,
                                overflow: 'hidden',
                                backgroundColor: Colors.border.light,
                                justifyContent: 'center',
                                alignItems: 'center'
                            }}
                        >
                            {editFormData.coverImage ? (
                                <Image
                                    source={{ uri: editFormData.coverImage.uri }}
                                    style={{ width: '100%', height: '100%' }}
                                />
                            ) : travel?.coverImageUrl ? (
                                <View style={{ width: '100%', height: '100%' }}>
                                    <Image
                                        source={{ uri: travel.coverImageUrl }}
                                        style={{ width: '100%', height: '100%', opacity: 0.5 }}
                                    />
                                    <View style={{ position: 'absolute', inset: 0, justifyContent: 'center', alignItems: 'center' }}>
                                        <Ionicons name="camera" size={24} color={Colors.black} />
                                        <Text style={{ marginTop: 4, fontSize: 12, fontWeight: '500' }}>Alterar foto</Text>
                                    </View>
                                </View>
                            ) : (
                                <>
                                    <Ionicons name="image-outline" size={32} color={Colors.text.secondary} />
                                    <Text style={{ color: Colors.text.secondary, marginTop: 8 }}>Selecionar foto</Text>
                                </>
                            )}
                        </TouchableOpacity>
                    </View>
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
            <BottomSheetModal
                ref={activityMenuRef}
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
                    {selectedDayIndex === -1 && (
                        <TouchableOpacity
                            style={styles.sheetItem}
                            onPress={() => {
                                activityMenuRef.current?.dismiss();
                                assignSheetRef.current?.present();
                            }}
                        >
                            <Text style={styles.sheetItemText}>Mover para roteiro</Text>
                        </TouchableOpacity>
                    )}
                    <TouchableOpacity
                        style={styles.sheetItem}
                        onPress={() => {
                            activityMenuRef.current?.dismiss();
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
                        <Text style={[styles.sheetItemText, { color: Colors.text.error }]}>Remover</Text>
                    </TouchableOpacity>
                </BottomSheetView>
            </BottomSheetModal>

            {/* Assign to Itinerary Sheet */}
            <BottomSheetModal
                ref={assignSheetRef}
                enableDynamicSizing
                enablePanDownToClose
                backdropComponent={(props) => (
                    <BottomSheetBackdrop {...props} disappearsOnIndex={-1} appearsOnIndex={0} opacity={0.5} />
                )}
                handleIndicatorStyle={{ backgroundColor: '#D1D1D6', width: 36 }}
                backgroundStyle={{ backgroundColor: '#fff' }}
            >
                <BottomSheetView style={{ padding: 16, paddingBottom: 32 }}>
                    <Text style={styles.sheetTitle}>
                        Mover &quot;{selectedActivity?.title}&quot; para:
                    </Text>
                    {sortedItineraries.map((itinerary, idx) => (
                        <TouchableOpacity
                            key={itinerary.id}
                            style={styles.sheetItem}
                            onPress={() => {
                                if (selectedActivity) {
                                    assignActivity.mutate({
                                        activityId: selectedActivity.id,
                                        itineraryId: itinerary.id,
                                    });
                                }
                            }}
                        >
                            <Text style={styles.sheetItemText}>
                                Dia {idx + 1}: {itinerary.title}
                            </Text>
                        </TouchableOpacity>
                    ))}
                    {sortedItineraries.length === 0 && (
                        <View style={{ padding: 16, alignItems: 'center' }}>
                            <Text style={{ color: Colors.text.secondary }}>Crie um dia primeiro</Text>
                        </View>
                    )}
                </BottomSheetView>
            </BottomSheetModal>

            {/* Itinerary Edit/Delete Sheet */}
            <BottomSheetModal
                ref={itineraryMenuRef}
                enableDynamicSizing
                enablePanDownToClose
                backdropComponent={(props) => (
                    <BottomSheetBackdrop {...props} disappearsOnIndex={-1} appearsOnIndex={0} opacity={0.5} />
                )}
                handleIndicatorStyle={{ backgroundColor: '#D1D1D6', width: 36 }}
                backgroundStyle={{ backgroundColor: '#fff' }}
            >
                <BottomSheetView style={{ padding: 16, paddingBottom: 32 }}>
                    <Text style={styles.sheetTitle}>
                        {selectedItineraryForEdit?.title || 'Dia'}
                    </Text>
                    <TouchableOpacity
                        style={styles.sheetItem}
                        onPress={() => {
                            if (selectedItineraryForEdit) {
                                setEditItineraryData({
                                    title: selectedItineraryForEdit.title,
                                    date: selectedItineraryForEdit.date ? new Date(selectedItineraryForEdit.date) : null,
                                });
                                itineraryMenuRef.current?.dismiss();
                                setShowEditItinerary(true);
                            }
                        }}
                    >
                        <Ionicons name="pencil" size={20} color={Colors.text.primary} style={{ marginRight: 12 }} />
                        <Text style={styles.sheetItemText}>Editar dia</Text>
                    </TouchableOpacity>
                    <TouchableOpacity
                        style={styles.sheetItem}
                        onPress={() => {
                            if (selectedItineraryForEdit) {
                                Alert.alert(
                                    'Excluir dia',
                                    `Deseja excluir "${selectedItineraryForEdit.title}"? Todas as atividades serão movidas para a lista de desejos.`,
                                    [
                                        { text: 'Cancelar', style: 'cancel' },
                                        {
                                            text: 'Excluir',
                                            style: 'destructive',
                                            onPress: () => deleteItinerary.mutate(selectedItineraryForEdit.id)
                                        }
                                    ]
                                );
                            }
                        }}
                    >
                        <Ionicons name="trash-outline" size={20} color={Colors.error} style={{ marginRight: 12 }} />
                        <Text style={[styles.sheetItemText, { color: Colors.error }]}>Excluir dia</Text>
                    </TouchableOpacity>
                </BottomSheetView>
            </BottomSheetModal>

            {/* Edit Itinerary Sheet */}
            <SheetForm
                isOpen={showEditItinerary}
                onClose={() => {
                    setShowEditItinerary(false);
                    setSelectedItineraryForEdit(null);
                }}
                title="Editar Dia"
                onSubmit={() => editItineraryData.title.trim() && updateItinerary.mutate()}
                isSubmitting={updateItinerary.isPending}
                submitLabel="Salvar"
            >
                <VStack space="md">
                    <VStack space="xs">
                        <Text style={styles.inputLabel}>NOME</Text>
                        <Input>
                            <InputField
                                value={editItineraryData.title}
                                onChangeText={(t) => setEditItineraryData(d => ({ ...d, title: t }))}
                                autoFocus
                            />
                        </Input>
                    </VStack>
                    <DatePickerInput
                        label="DATA"
                        value={editItineraryData.date}
                        onChange={(date) => setEditItineraryData(d => ({ ...d, date }))}
                        minDate={parseDateSafe(travel?.startDate) ?? undefined}
                        maxDate={parseDateSafe(travel?.endDate) ?? undefined}
                        initialMonth={parseDateSafe(travel?.startDate) ?? undefined}
                    />
                </VStack>
            </SheetForm>

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
                        <BottomSheetTextInput
                            style={styles.sheetInput}
                            placeholder="email@exemplo.com"
                            value={inviteEmail}
                            onChangeText={setInviteEmail}
                            autoCapitalize="none"
                            keyboardType="email-address"
                            placeholderTextColor={Colors.text.secondary}
                        />
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
        </GestureHandlerRootView >
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
    emptyStateSubtext: {
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
    sheetHandle: {
        backgroundColor: Colors.border.medium,
        width: 40,
        height: 4,
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
        backgroundColor: Colors.white,
    },
    mapEmpty: {
        flex: 1,
        alignItems: 'center',
        flexDirection: 'row',
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
        transform: [{ scale: 0.88 }],
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
    sheetInput: {
        backgroundColor: '#F9F9F9',
        borderRadius: 8,
        paddingHorizontal: 16,
        paddingVertical: 12,
        fontSize: 16,
        color: Colors.text.primary,
        borderWidth: 1,
        borderColor: Colors.border.light,
    },
});
