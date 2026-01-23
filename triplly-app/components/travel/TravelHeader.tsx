import React, { memo } from 'react';
import { View, Text, TouchableOpacity, Image, StyleSheet } from 'react-native';
import { Ionicons } from '@expo/vector-icons';
import { router } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Colors } from '@/constants/colors';
import type { TravelMember } from '@/lib/types';

interface TravelHeaderProps {
    members: TravelMember[] | undefined;
    onMembersPress: () => void;
}

function TravelHeaderComponent({ members, onMembersPress }: TravelHeaderProps) {
    const insets = useSafeAreaInsets();

    return (
        <View style={[styles.container, { top: insets.top + 10 }]}>
            <TouchableOpacity
                onPress={() => router.back()}
                style={styles.headerButton}
                accessibilityRole="button"
                accessibilityLabel="Go back"
            >
                <Ionicons name="arrow-back" size={24} color={Colors.black} />
            </TouchableOpacity>

            {members && members.length > 0 && (
                <TouchableOpacity
                    style={styles.membersButton}
                    onPress={onMembersPress}
                    activeOpacity={0.7}
                    accessibilityRole="button"
                    accessibilityLabel={`${members.length} members, tap to manage`}
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
    );
}

export const TravelHeader = memo(TravelHeaderComponent);

const styles = StyleSheet.create({
    container: {
        position: 'absolute',
        left: 24,
        right: 24,
        zIndex: 100,
        flexDirection: 'row',
        justifyContent: 'space-between',
        alignItems: 'center',
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
    membersButton: {
        marginTop: 12,
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
});
