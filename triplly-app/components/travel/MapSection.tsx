import React, { memo, useCallback } from 'react';
import { View, Text, StyleSheet, Dimensions } from 'react-native';
import { GestureDetector, Gesture } from 'react-native-gesture-handler';
import Animated, {
    SharedValue,
    useAnimatedStyle,
    withSpring,
    interpolate,
    Extrapolation,
    runOnJS,
} from 'react-native-reanimated';
import { Ionicons } from '@expo/vector-icons';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Colors } from '@/constants/colors';
import ItineraryMap from '@/components/ItineraryMap';
import type { Activity } from '@/lib/types';

const { height: SCREEN_HEIGHT } = Dimensions.get('window');
const MAP_COLLAPSED_HEIGHT = 120;
const MAP_EXPANDED_HEIGHT = SCREEN_HEIGHT * 0.5;

interface MapSectionProps {
    activities: Activity[];
    mapHeight: SharedValue<number>;
    isMapExpanded: boolean;
    onToggleExpand: (expanded: boolean) => void;
}

function MapSectionComponent({
    activities,
    mapHeight,
    isMapExpanded,
    onToggleExpand,
}: MapSectionProps) {
    const insets = useSafeAreaInsets();

    const toggleMapExpansion = useCallback(() => {
        if (isMapExpanded) {
            mapHeight.value = withSpring(MAP_COLLAPSED_HEIGHT, { damping: 30, stiffness: 150 });
            onToggleExpand(false);
        } else {
            mapHeight.value = withSpring(MAP_EXPANDED_HEIGHT, { damping: 30, stiffness: 150 });
            onToggleExpand(true);
        }
    }, [isMapExpanded, mapHeight, onToggleExpand]);

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
                runOnJS(onToggleExpand)(true);
            } else if (shouldCollapse) {
                mapHeight.value = withSpring(MAP_COLLAPSED_HEIGHT, { damping: 30, stiffness: 150 });
                runOnJS(onToggleExpand)(false);
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

    return (
        <Animated.View
            style={[styles.container, { bottom: insets.bottom }, animatedMapStyle]}
            accessibilityLabel="Map section"
            accessibilityHint="Tap or drag to expand"
        >
            <GestureDetector gesture={mapGesture}>
                <Animated.View style={styles.handleContainer}>
                    <View style={styles.handle} />
                    <View style={styles.headerRow}>
                        <Text style={styles.title}>MAPA</Text>
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
    );
}

export const MapSection = memo(MapSectionComponent);

export { MAP_COLLAPSED_HEIGHT, MAP_EXPANDED_HEIGHT };

const styles = StyleSheet.create({
    container: {
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
    handleContainer: {
        paddingTop: 12,
        paddingBottom: 8,
        paddingHorizontal: 24,
        backgroundColor: Colors.white,
    },
    handle: {
        backgroundColor: Colors.border.medium,
        width: 40,
        height: 4,
        borderRadius: 2,
        alignSelf: 'center',
        marginBottom: 12,
    },
    headerRow: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
    },
    title: {
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
});
