import React, { memo, useCallback } from 'react';
import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { Image } from 'expo-image';
import { Link } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import type { TravelListItem } from '@/lib/types';
import { formatDateRange } from '@/utils/distance';
import { Colors } from '@/constants/colors';

interface TravelCardProps {
    travel: TravelListItem;
}

function TravelCardComponent({ travel }: TravelCardProps) {
    const dateText = (travel.startDate || travel.endDate)
        ? formatDateRange(travel.startDate, travel.endDate)
        : null;

    return (
        <Link href={`/(app)/travel/${travel.id}`} asChild>
            <TouchableOpacity
                style={styles.card}
                accessibilityRole="button"
                accessibilityLabel={`Travel to ${travel.title}`}
                accessibilityHint="Opens travel details"
            >
                {travel.coverImageUrl ? (
                    <>
                        <Image
                            source={{ uri: travel.coverImageUrl }}
                            style={StyleSheet.absoluteFill}
                            contentFit="cover"
                            transition={200}
                            placeholder={{ blurhash: 'L6PZfSi_.AyE_3t7t7R**0o#DgR4' }}
                        />
                        <View style={styles.cardOverlay}>
                            <View style={styles.cardContent}>
                                <View>
                                    <Text style={[styles.cardTitle, styles.cardTitleLight]}>{travel.title}</Text>
                                    {dateText && (
                                        <Text style={[styles.cardDates, styles.cardDatesLight]}>
                                            {dateText}
                                        </Text>
                                    )}
                                </View>
                                <View style={styles.cardFooter}>
                                    <View style={styles.roleBadge}>
                                        <Text style={styles.roleText}>{travel.role}</Text>
                                    </View>
                                    <Ionicons name="arrow-forward" size={20} color={Colors.white} />
                                </View>
                            </View>
                        </View>
                    </>
                ) : (
                    <View style={styles.cardContent}>
                        <View>
                            <Text style={styles.cardTitle}>{travel.title}</Text>
                            {dateText && (
                                <Text style={styles.cardDates}>{dateText}</Text>
                            )}
                        </View>
                        <View style={styles.cardFooter}>
                            <View style={styles.roleBadge}>
                                <Text style={styles.roleText}>{travel.role}</Text>
                            </View>
                            <Ionicons name="arrow-forward" size={20} color={Colors.black} />
                        </View>
                    </View>
                )}
            </TouchableOpacity>
        </Link>
    );
}

export const TravelCard = memo(TravelCardComponent);

const styles = StyleSheet.create({
    card: {
        height: 200,
        backgroundColor: Colors.white,
        borderRadius: 32,
        overflow: 'hidden',
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 8 },
        shadowOpacity: 0.05,
        shadowRadius: 24,
        elevation: 4,
        marginBottom: 20,
    },
    cardOverlay: {
        flex: 1,
        backgroundColor: 'rgba(0,0,0,0.3)',
        borderRadius: 32,
        padding: 24,
    },
    cardContent: {
        flex: 1,
        justifyContent: 'space-between',
        padding: 24,
    },
    cardTitle: {
        fontSize: 32,
        fontWeight: '400',
        color: Colors.text.primary,
        lineHeight: 36,
    },
    cardTitleLight: {
        color: Colors.white,
    },
    cardDates: {
        fontSize: 15,
        color: Colors.text.secondary,
        fontWeight: '500',
        marginTop: 4,
        textTransform: 'uppercase',
        letterSpacing: 1,
    },
    cardDatesLight: {
        color: Colors.white,
    },
    cardFooter: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
    },
    roleBadge: {
        backgroundColor: Colors.background,
        paddingHorizontal: 12,
        paddingVertical: 6,
        borderRadius: 100,
    },
    roleText: {
        fontSize: 12,
        color: Colors.text.primary,
        textTransform: 'uppercase',
        fontWeight: '600',
        letterSpacing: 0.5,
    },
});
