import { useState, useEffect, useRef, useCallback } from 'react';
import {
    View,
    Text,
    StyleSheet,
    ActivityIndicator,
    TextInput,
    TouchableOpacity,
    KeyboardAvoidingView,
    Platform,
    Alert,
    Dimensions
} from 'react-native';
import { useLocalSearchParams, Stack, router } from 'expo-router';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import Animated, { useSharedValue, useAnimatedStyle, withSpring, interpolate, Extrapolation, useAnimatedScrollHandler, runOnJS } from 'react-native-reanimated';
import { GestureHandlerRootView, Gesture, GestureDetector } from 'react-native-gesture-handler';
import { Ionicons } from '@expo/vector-icons';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { api } from '@/lib/api';
import ItineraryMap from '@/components/ItineraryMap';
import SheetForm from '@/components/SheetForm';
import { VStack } from '@gluestack-ui/themed';
import { BottomSheetModal, BottomSheetView, BottomSheetBackdrop, BottomSheetTextInput } from '@gorhom/bottom-sheet';
import PlaceAutocomplete from '@/components/PlaceAutocomplete';
import { format } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { Colors } from '@/constants/colors';
import ActivitySkeleton from '@/components/ActivitySkeleton';


export default function ActivityScreen() {
    const { id, itineraryId, activityId } = useLocalSearchParams<{ id: string; itineraryId: string; activityId: string }>();
    const queryClient = useQueryClient();
    const insets = useSafeAreaInsets();
    const [commentText, setCommentText] = useState('');
    const assignSheetRef = useRef<BottomSheetModal>(null);
    const [showEditSheet, setShowEditSheet] = useState(false);
    const [editData, setEditData] = useState({
        title: '',
        description: '',
        startTime: '',
        latitude: 0,
        longitude: 0,
        googlePlaceId: null as string | null,
        address: null as string | null,
    });

    const { height: SCREEN_HEIGHT } = Dimensions.get('window');
    const MAP_COLLAPSED_HEIGHT = 120;
    const MAP_EXPANDED_HEIGHT = SCREEN_HEIGHT * 0.5;

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

    const { data: activity, isLoading: isLoadingActivity } = useQuery({
        queryKey: ['activity', activityId],
        queryFn: () => api.getActivity(activityId!),
    });

    const { data: travel } = useQuery({
        queryKey: ['travel', id],
        queryFn: () => api.getTravel(id!),
        enabled: !!id
    });

    const { data: comments, isLoading: isLoadingComments } = useQuery({
        queryKey: ['comments', activityId],
        queryFn: () => api.getActivityComments(activityId!),
        enabled: !!activityId,
    });

    useEffect(() => {
        if (activity) {
            setEditData({
                title: activity.title,
                description: activity.description || '',
                startTime: activity.startTime || '',
                latitude: activity.latitude || 0,
                longitude: activity.longitude || 0,
                googlePlaceId: activity.googlePlaceId || null,
                address: activity.address || null,
            });
        }
    }, [activity]);

    const createComment = useMutation({
        mutationFn: (content: string) => api.createComment(activityId!, content),
        onSuccess: () => {
            setCommentText('');
            queryClient.invalidateQueries({ queryKey: ['comments', activityId] });
        },
    });

    const updateActivity = useMutation({
        mutationFn: () => api.updateActivity(activityId!, {
            title: editData.title,
            description: editData.description || null,
            startTime: editData.startTime || null,
            latitude: editData.latitude,
            longitude: editData.longitude,
            googlePlaceId: editData.googlePlaceId,
            address: editData.address,
        }),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['activity', activityId] });
            queryClient.invalidateQueries({ queryKey: ['itinerary', itineraryId] });
            queryClient.invalidateQueries({ queryKey: ['travel', id] });
            setShowEditSheet(false);
        },
        onError: (err) => Alert.alert('Erro', err instanceof Error ? err.message : 'Falha ao atualizar'),
    });

    const deleteActivity = useMutation({
        mutationFn: () => api.deleteActivity(activityId!),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['itinerary', itineraryId] });
            queryClient.invalidateQueries({ queryKey: ['travel', id] });
            router.back();
        },
        onError: (err) => Alert.alert('Erro', err instanceof Error ? err.message : 'Falha ao remover'),
    });

    const assignActivity = useMutation({
        mutationFn: (targetItineraryId: string | null) => api.assignActivity(activityId!, targetItineraryId),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['activity', activityId] });
            queryClient.invalidateQueries({ queryKey: ['travel', id] });
            queryClient.invalidateQueries({ queryKey: ['travel', id, 'wishlist'] });
            assignSheetRef.current?.dismiss();
            Alert.alert('Sucesso', 'Atividade movida para o roteiro');
        },
        onError: (err) => Alert.alert('Erro', err instanceof Error ? err.message : 'Falha ao mover atividade'),
    });

    if (isLoadingActivity || !activity) {
        return <ActivitySkeleton />;
    }

    const handleSendComment = () => {
        if (!commentText.trim()) return;
        createComment.mutate(commentText);
    };

    const handleDelete = () => {
        Alert.alert(
            'Remover local',
            `Deseja remover "${activity.title}"?`,
            [
                { text: 'Cancelar', style: 'cancel' },
                { text: 'Remover', style: 'destructive', onPress: () => deleteActivity.mutate() }
            ]
        );
    };

    return (
        <GestureHandlerRootView style={styles.container}>
            <Stack.Screen options={{ headerShown: false }} />

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
                <TouchableOpacity onPress={() => setShowEditSheet(true)} style={styles.headerButton}>
                    <Ionicons name="pencil" size={22} color={Colors.black} />
                </TouchableOpacity>
            </View>

            {/* Collapsible Header Content */}
            <Animated.View style={[
                {
                    position: 'absolute',
                    top: insets.top + 60,
                    left: 24,
                    right: 24,
                    zIndex: 10,
                },
                headerContentStyle
            ]}>
                <Text numberOfLines={1} style={styles.bigTitle}>{activity.title}</Text>

                <View style={styles.subtitleRow}>
                    {activity.startTime && (
                        <View style={styles.subtitleItem}>
                            <Ionicons name="time-outline" size={16} color={Colors.text.secondary} />
                            <Text style={styles.subtitleText}>{activity.startTime}</Text>
                        </View>
                    )}
                    {activity.address && (
                        <View style={styles.subtitleItem}>
                            <Ionicons name="location-outline" size={16} color={Colors.text.secondary} />
                            <Text style={styles.subtitleText} numberOfLines={1}>
                                {activity.address}
                            </Text>
                        </View>
                    )}
                </View>
            </Animated.View>

            <Animated.ScrollView
                contentContainerStyle={[styles.content, { paddingBottom: MAP_COLLAPSED_HEIGHT + 100, paddingTop: insets.top + 160 }]}
                onScroll={scrollHandler}
                scrollEventThrottle={16}
            >
                <KeyboardAvoidingView
                    behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
                    style={{ flex: 1 }}
                    keyboardVerticalOffset={Platform.OS === 'ios' ? 0 : 20}
                >
                    {/* Activity Details Card */}
                    <View style={styles.card}>
                        {/* Title removed from here as it is in header now */}

                        {activity.description && (
                            <Text style={[styles.description, { borderTopWidth: 0, paddingTop: 0 }]}>{activity.description}</Text>
                        )}

                        {/* Added By Section */}
                        {activity.createdBy && (
                            <View style={activity.description ? styles.addedBySection : { ...styles.addedBySection, borderTopWidth: 0, paddingTop: 0, marginTop: 0 }}>
                                <Ionicons name="person-outline" size={16} color={Colors.text.secondary} />
                                <Text style={styles.addedByText}>
                                    Adicionado por <Text style={styles.addedByName}>{activity.createdBy.name}</Text>
                                    {' em '}
                                    {format(new Date(activity.createdAt), "d 'de' MMMM", { locale: ptBR })}
                                </Text>
                            </View>
                        )}

                        <TouchableOpacity
                            style={[styles.assignButton, activity.itineraryId && styles.assignButtonOutline]}
                            onPress={() => assignSheetRef.current?.present()}
                        >
                            <Ionicons
                                name="calendar-outline"
                                size={20}
                                color={activity.itineraryId ? Colors.text.primary : Colors.text.primary}
                            />
                            <Text style={[styles.assignButtonText, activity.itineraryId && styles.assignButtonTextOutline]}>
                                {activity.itineraryId ? "Mover para outro dia" : "Adicionar ao Roteiro"}
                            </Text>
                        </TouchableOpacity>
                    </View>

                    {/* Comments Section */}
                    <View style={styles.commentsSection}>
                        <Text style={styles.sectionTitle}>Comentários</Text>

                        {isLoadingComments ? (
                            <ActivityIndicator color={Colors.text.secondary} style={{ marginTop: 20 }} />
                        ) : comments?.length === 0 ? (
                            <View style={styles.emptyCommentsContainer}>
                                <Text style={styles.emptyComments}>Nenhum comentário ainda.</Text>
                            </View>
                        ) : (
                            <View style={styles.commentsList}>
                                {comments?.map((comment) => (
                                    <View key={comment.id} style={styles.commentItem}>
                                        <View style={styles.commentHeader}>
                                            <Text style={styles.commentAuthor}>{comment.user.name}</Text>
                                            <Text style={styles.commentDate}>
                                                {format(new Date(comment.createdAt), 'dd MMM, HH:mm')}
                                            </Text>
                                        </View>
                                        <Text style={styles.commentContent}>{comment.content}</Text>
                                    </View>
                                ))}
                            </View>
                        )}
                    </View>

                </KeyboardAvoidingView>
            </Animated.ScrollView>

            {/* Fixed Comment Input (Above Map) */}
            <KeyboardAvoidingView
                behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
                keyboardVerticalOffset={Platform.OS === 'ios' ? 0 : 20}
                style={{
                    position: 'absolute',
                    bottom: MAP_COLLAPSED_HEIGHT - 20 + insets.bottom, // Account for insets
                    left: 0,
                    right: 0,
                    zIndex: 900
                }}
            >
                <View style={styles.inputContainer}>
                    <TextInput
                        style={styles.input}
                        placeholder="Adicionar comentário..."
                        placeholderTextColor="#999"
                        value={commentText}
                        onChangeText={setCommentText}
                        multiline
                    />
                    <TouchableOpacity
                        style={[styles.sendButton, !commentText.trim() && styles.sendButtonDisabled]}
                        onPress={handleSendComment}
                        disabled={!commentText.trim() || createComment.isPending}
                    >
                        {createComment.isPending ? (
                            <ActivityIndicator size="small" color={Colors.text.primary} />
                        ) : (
                            <Ionicons name="arrow-up" size={20} color={Colors.text.primary} />
                        )}
                    </TouchableOpacity>
                </View>
            </KeyboardAvoidingView>

            {/* Expandable Map at Bottom */}
            <GestureDetector gesture={mapGesture}>
                <Animated.View style={[styles.mapContainer, { bottom: insets.bottom }, animatedMapStyle]}>
                    <View style={styles.mapHandleContainer}>
                        <Animated.View style={animatedHandleStyle}>
                            <Ionicons name="chevron-up" size={24} color={Colors.border.medium} />
                        </Animated.View>
                    </View>

                    {/* Map Component */}
                    <View style={[{ flex: 1, marginTop: 10 }]}>
                        <ItineraryMap
                            activities={[activity]}
                        />
                    </View>
                </Animated.View>
            </GestureDetector>

            {/* Edit Sheet */}
            <SheetForm
                isOpen={showEditSheet}
                onClose={() => setShowEditSheet(false)}
                title="Editar Local"
                onSubmit={() => editData.title.trim() && updateActivity.mutate()}
                isSubmitting={updateActivity.isPending}
                submitLabel="Salvar"
            >
                <VStack space="md">
                    <PlaceAutocomplete
                        onSelect={(place) => {
                            setEditData(d => ({
                                ...d,
                                title: place.name,
                                latitude: place.latitude ?? place.lat ?? 0,
                                longitude: place.longitude ?? place.lon ?? 0,
                                googlePlaceId: place.placeId,
                                address: place.address || null,
                            }));
                        }}
                    />
                    {editData.title && (
                        <View style={styles.selectedPlace}>
                            <Ionicons name="location" size={16} color={Colors.black} />
                            <Text style={styles.selectedPlaceText}>{editData.title}</Text>
                        </View>
                    )}

                    <TouchableOpacity style={styles.deleteBtn} onPress={handleDelete}>
                        <Ionicons name="trash-outline" size={18} color={Colors.error} />
                        <Text style={styles.deleteBtnText}>Remover local</Text>
                    </TouchableOpacity>
                </VStack>
            </SheetForm>

            {/* Assign Sheet */}
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
                    <Text style={styles.sheetTitle}>Escolher dia</Text>

                    {activity?.itineraryId && (
                        <TouchableOpacity
                            style={styles.sheetItem}
                            onPress={() => assignActivity.mutate(null)}
                        >
                            <Ionicons name="heart-outline" size={20} color={Colors.text.secondary} style={{ marginRight: 8 }} />
                            <Text style={styles.sheetItemText}>Mover para Wishlist</Text>
                        </TouchableOpacity>
                    )}

                    {travel?.itineraries?.map((itinerary) => (
                        <TouchableOpacity
                            key={itinerary.id}
                            style={styles.sheetItem}
                            onPress={() => assignActivity.mutate(itinerary.id)}
                        >
                            <Text style={styles.sheetItemText}>
                                {itinerary?.date ? format(new Date(itinerary.date), "EEEE, d 'de' MMMM", { locale: ptBR }) : 'Sem data'}
                            </Text>
                        </TouchableOpacity>
                    ))}
                </BottomSheetView>
            </BottomSheetModal>
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
    },
    content: {
        paddingHorizontal: 20,
        paddingBottom: 100,
    },
    card: {
        backgroundColor: '#fff',
        borderRadius: 24,
        padding: 24,
        marginBottom: 24,
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.05,
        shadowRadius: 8,
        elevation: 2,
    },
    title: {
        fontSize: 24,
        fontWeight: '600',
        color: Colors.text.primary,
        marginBottom: 12,
        fontFamily: 'Serif',
    },
    metaRow: {
        flexDirection: 'row',
        gap: 16,
        marginBottom: 16,
        flexWrap: 'wrap',
    },
    metaItem: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 6,
    },
    metaText: {
        fontSize: 15,
        color: Colors.text.secondary,
    },
    description: {
        fontSize: 16,
        color: '#3A3A3C',
        lineHeight: 24,
        borderTopWidth: 1,
        borderTopColor: '#F2F2F7',
        paddingTop: 16,
    },
    addedBySection: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 8,
        marginTop: 16,
        paddingTop: 16,
        borderTopWidth: 1,
        borderTopColor: '#F2F2F7',
    },
    addedByText: {
        fontSize: 14,
        color: Colors.text.secondary,
    },
    addedByName: {
        fontWeight: '600',
        color: Colors.text.primary,
    },
    sectionTitle: {
        fontSize: 18,
        fontWeight: '600',
        color: Colors.text.primary,
        marginBottom: 16,
        fontFamily: 'Serif',
    },
    commentsSection: {
        marginBottom: 20,
    },
    commentsList: {
        gap: 16,
    },
    commentItem: {
        backgroundColor: '#fff',
        padding: 16,
        borderRadius: 16,
    },
    commentHeader: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
        marginBottom: 6,
    },
    commentAuthor: {
        fontSize: 14,
        fontWeight: '600',
        color: Colors.text.primary,
    },
    commentDate: {
        fontSize: 12,
        color: Colors.text.secondary,
    },
    commentContent: {
        fontSize: 15,
        color: '#3A3A3C',
        lineHeight: 20,
    },
    emptyComments: {
        textAlign: 'center',
        color: Colors.text.secondary,
        fontSize: 16,
        fontWeight: '500',
    },
    emptyCommentsContainer: {
        backgroundColor: '#fff',
        borderRadius: 16,
        paddingVertical: 40,
        alignItems: 'center',
        justifyContent: 'center',
        gap: 8,
    },
    emptyCommentsAction: {
        fontSize: 14,
        color: '#007AFF', // iOS Blue or any primary color
    },
    inputContainer: {
        backgroundColor: 'transparent',
        paddingHorizontal: 16,
        paddingBottom: 40, // Add bottom padding for better spacing above map
        flexDirection: 'row',
        alignItems: 'flex-end',
        gap: 12,
        // Removed borderTop as it looks weird floating
    },
    input: {
        flex: 1,
        backgroundColor: 'white',
        borderRadius: 20,
        paddingHorizontal: 16,
        paddingTop: 10,
        paddingBottom: 10,
        minHeight: 40,
        maxHeight: 100,
        fontSize: 16,
        color: Colors.text.primary,
    },
    sendButton: {
        width: 40,
        height: 40,
        borderRadius: 20,
        backgroundColor: Colors.primary,
        alignItems: 'center',
        justifyContent: 'center',
        marginBottom: 2,
    },
    sendButtonDisabled: {
        backgroundColor: '#D1D1D6',
    },
    inputLabel: {
        fontSize: 13,
        fontWeight: '600',
        color: '#666',
    },
    deleteBtn: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
        gap: 8,
        paddingVertical: 16,
        marginTop: 8,
    },
    deleteBtnText: {
        fontSize: 16,
        color: Colors.error,
        fontWeight: '500',
    },
    assignButton: {
        backgroundColor: Colors.primary,
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'center',
        paddingVertical: 12,
        borderRadius: 12,
        gap: 8,
        marginTop: 20,
    },
    assignButtonText: {
        color: Colors.text.primary,
        fontSize: 16,
        fontWeight: '600',
    },
    assignButtonOutline: {
        backgroundColor: 'transparent',
        borderWidth: 1,
        borderColor: Colors.border.light,
    },
    assignButtonTextOutline: {
        color: Colors.black,
    },
    sheetTitle: {
        fontSize: 17,
        fontWeight: '600',
        padding: 16,
        textAlign: 'center',
        width: '100%',
    },
    headerButton: {
        width: 40,
        height: 40,
        borderRadius: 20,
        backgroundColor: '#fff',
        alignItems: 'center',
        justifyContent: 'center',
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.1,
        shadowRadius: 8,
        elevation: 2,
    },
    bigTitle: {
        fontSize: 32,
        fontWeight: '700',
        color: Colors.text.primary,
        marginBottom: 8,
        fontFamily: 'Serif',
    },
    subtitleRow: {
        flexDirection: 'row',
        flexWrap: 'wrap',
        gap: 12,
    },
    subtitleItem: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 4,
    },
    subtitleText: {
        fontSize: 15,
        color: Colors.text.secondary,
        fontWeight: '500',
    },
    mapContainer: {
        position: 'absolute',
        bottom: 0,
        left: 10,
        right: 10,
        backgroundColor: '#fff',
        borderTopLeftRadius: 24,
        borderTopRightRadius: 24,
        borderBottomLeftRadius: 24,
        borderBottomRightRadius: 24,
        shadowColor: '#000',
        shadowOffset: { width: 0, height: -4 },
        shadowOpacity: 0.1,
        shadowRadius: 12,
        elevation: 8,
        padding: 24,
        paddingTop: 12,
        zIndex: 1000,
    },
    mapHandleContainer: {
        width: '100%',
        alignItems: 'center',
        paddingBottom: 8,
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
        backgroundColor: '#F5F5F5',
        borderRadius: 12,
        paddingHorizontal: 16,
        paddingVertical: 12,
        fontSize: 16,
        color: Colors.text.primary,
    },
    sheetInputMultiline: {
        minHeight: 80,
        textAlignVertical: 'top',
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
});
