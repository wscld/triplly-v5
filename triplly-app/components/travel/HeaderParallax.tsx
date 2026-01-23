import React, { memo, useCallback } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, Image } from 'react-native';
import Animated, { SharedValue, useAnimatedStyle, interpolate, Extrapolation } from 'react-native-reanimated';
import { Ionicons } from '@expo/vector-icons';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { format } from 'date-fns';
import { ptBR } from 'date-fns/locale';
import { Colors } from '@/constants/colors';

interface HeaderParallaxProps {
    coverImageUrl: string | null;
    title: string;
    startDate: string | null;
    endDate: string | null;
    scrollY: SharedValue<number>;
    isOwner: boolean;
    onEditPress: () => void;
}

const parseDateSafe = (dateStr: string | null | undefined): Date | null => {
    if (!dateStr) return null;
    return new Date(`${dateStr}T12:00:00`);
};

function HeaderParallaxComponent({
    coverImageUrl,
    title,
    startDate,
    endDate,
    scrollY,
    isOwner,
    onEditPress,
}: HeaderParallaxProps) {
    const insets = useSafeAreaInsets();

    const imageAnimatedStyle = useAnimatedStyle(() => ({
        transform: [
            { translateY: interpolate(scrollY.value, [-300, 0, 300], [150, 0, -150]) },
            { scale: interpolate(scrollY.value, [-300, 0], [2, 1], Extrapolation.CLAMP) }
        ]
    }));

    const headerContentStyle = useAnimatedStyle(() => ({
        opacity: interpolate(scrollY.value, [0, 60], [1, 0], Extrapolation.CLAMP),
        transform: [
            { translateY: interpolate(scrollY.value, [0, 100], [0, -50], Extrapolation.CLAMP) }
        ],
    }));

    const startDateParsed = parseDateSafe(startDate);
    const endDateParsed = parseDateSafe(endDate);
    const dateText = startDateParsed && endDateParsed
        ? `${format(startDateParsed, "d MMM", { locale: ptBR })} - ${format(endDateParsed, "d MMM, yyyy", { locale: ptBR })}`
        : 'Sem data definida';

    return (
        <>
            <Animated.View style={[styles.coverContainer, imageAnimatedStyle]}>
                {coverImageUrl ? (
                    <Image
                        source={{ uri: coverImageUrl }}
                        style={styles.coverImage}
                        resizeMode="cover"
                    />
                ) : (
                    <View style={styles.coverPlaceholder} />
                )}
                <View style={styles.coverOverlay} />
            </Animated.View>

            <Animated.View style={[styles.headerContent, { top: insets.top + 60 }, headerContentStyle]}>
                <Text style={styles.title}>{title}</Text>
                <Text style={styles.subtitle}>{dateText}</Text>

                {isOwner && (
                    <TouchableOpacity
                        onPress={onEditPress}
                        style={styles.editButton}
                        accessibilityRole="button"
                        accessibilityLabel="Edit travel"
                    >
                        <Ionicons name="pencil" size={14} color={Colors.white} />
                        <Text style={styles.editButtonText}>Editar viagem</Text>
                    </TouchableOpacity>
                )}
            </Animated.View>
        </>
    );
}

export const HeaderParallax = memo(HeaderParallaxComponent);

const styles = StyleSheet.create({
    coverContainer: {
        position: 'absolute',
        top: 0,
        left: 0,
        right: 0,
        height: 310,
    },
    coverImage: {
        width: '100%',
        height: '100%',
    },
    coverPlaceholder: {
        width: '100%',
        height: '100%',
        backgroundColor: Colors.border.light,
    },
    coverOverlay: {
        position: 'absolute',
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        backgroundColor: 'rgba(0,0,0,0.3)',
    },
    headerContent: {
        position: 'absolute',
        left: 24,
        right: 24,
        zIndex: 10,
    },
    title: {
        fontSize: 34,
        fontWeight: '700',
        color: Colors.white,
        marginBottom: 4,
        fontFamily: 'Serif',
    },
    subtitle: {
        fontSize: 15,
        color: Colors.white,
        fontWeight: '500',
    },
    editButton: {
        flexDirection: 'row',
        alignItems: 'center',
        marginTop: 12,
        backgroundColor: 'rgba(255,255,255,0.2)',
        paddingHorizontal: 12,
        paddingVertical: 6,
        borderRadius: 16,
        alignSelf: 'flex-start',
    },
    editButtonText: {
        color: Colors.white,
        marginLeft: 6,
        fontWeight: '600',
        fontSize: 13,
    },
});
