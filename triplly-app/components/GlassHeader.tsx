import { View, Text, TouchableOpacity, StyleSheet, Platform } from 'react-native';

import { Ionicons } from '@expo/vector-icons';
import { router } from 'expo-router';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Colors } from '@/constants/colors';

interface Props {
    title: string;
    showBack?: boolean;
    rightElement?: React.ReactNode;
}

export default function GlassHeader({ title, showBack = true, rightElement }: Props) {
    const insets = useSafeAreaInsets();

    return (
        <View style={[styles.header, { paddingTop: insets.top }]}>
            <View style={styles.content}>
                <View style={styles.left}>
                    {showBack && (
                        <TouchableOpacity onPress={() => router.back()} style={styles.backButton}>
                            <Ionicons name="chevron-back" size={28} color={Colors.black} />
                        </TouchableOpacity>
                    )}
                </View>
                <Text style={styles.title} numberOfLines={1}>{title}</Text>
                <View style={styles.right}>
                    {rightElement}
                </View>
            </View>
        </View>
    );
}

const styles = StyleSheet.create({
    header: {
        position: 'absolute',
        top: 0,
        left: 0,
        right: 0,
        zIndex: 100,
        backgroundColor: Colors.background, // Warm beige solid background
        borderBottomWidth: 1,
        borderBottomColor: 'rgba(0,0,0,0.05)',
    },
    content: {
        height: 44, // Standard nav bar height
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        paddingHorizontal: 8,
    },
    left: {
        width: 60,
        alignItems: 'flex-start',
    },
    right: {
        width: 60,
        alignItems: 'flex-end',
    },
    title: {
        flex: 1,
        textAlign: 'center',
        fontSize: 17,
        fontWeight: '600',
        color: Colors.text.primary,
        fontFamily: 'Serif',
    },
    backButton: {
        padding: 8,
    },
});
