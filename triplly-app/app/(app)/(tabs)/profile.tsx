import { View, Text, TouchableOpacity, StyleSheet, Alert } from 'react-native';
import { router } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { useAuth } from '@/lib/auth';

import { SafeAreaView } from 'react-native-safe-area-context';

import { Colors } from '@/constants/colors';

export default function ProfileScreen() {
    const { user, logout } = useAuth();

    const handleLogout = () => {
        Alert.alert('Sign Out', 'Are you sure you want to sign out?', [
            { text: 'Cancel', style: 'cancel' },
            {
                text: 'Sign Out',
                style: 'destructive',
                onPress: async () => {
                    await logout();
                    router.replace('/(auth)/login');
                },
            },
        ]);
    };

    return (
        <View style={styles.container}>
            <SafeAreaView style={{ flex: 1 }}>
                <View style={styles.header}>
                    <View style={styles.avatarContainer}>
                        <View style={styles.avatarPlaceholder}>
                            <Text style={styles.avatarText}>
                                {user?.name?.charAt(0).toUpperCase() || 'U'}
                            </Text>
                        </View>
                    </View>
                    <Text style={styles.name}>{user?.name}</Text>
                    <Text style={styles.email}>{user?.email}</Text>
                </View>

                <View style={styles.section}>
                    <TouchableOpacity onPress={handleLogout} style={styles.itemContainer}>
                        <View style={styles.item}>
                            <Ionicons name="log-out-outline" size={22} color={Colors.text.error} />
                            <Text style={[styles.itemText, { color: Colors.text.error }]}>Sign Out</Text>
                            <Ionicons name="chevron-forward" size={18} color={Colors.border.medium} style={{ marginLeft: 'auto' }} />
                        </View>
                    </TouchableOpacity>
                </View>
            </SafeAreaView>
        </View>
    );
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: Colors.background, // Warm beige
    },
    header: {
        alignItems: 'center',
        paddingVertical: 40,
    },
    avatarContainer: {
        width: 100,
        height: 100,
        borderRadius: 50,
        marginBottom: 16,
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.1,
        shadowRadius: 12,
        elevation: 4,
    },
    avatarPlaceholder: {
        flex: 1,
        borderRadius: 50,
        alignItems: 'center',
        justifyContent: 'center',
        backgroundColor: Colors.black, // Dark avatar
    },
    avatarText: {
        fontSize: 36,
        fontWeight: '400',
        fontFamily: 'Serif',
        color: Colors.background,
    },
    name: {
        fontSize: 32,
        fontWeight: '400',
        fontFamily: 'Serif',
        color: Colors.text.primary,
        marginBottom: 4,
        letterSpacing: -0.5,
    },
    email: {
        fontSize: 16,
        color: Colors.text.secondary,
    },
    section: {
        paddingHorizontal: 20,
        marginTop: 20,
    },
    itemContainer: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 2 },
        shadowOpacity: 0.05,
        shadowRadius: 8,
        elevation: 2,
    },
    item: {
        flexDirection: 'row',
        alignItems: 'center',
        gap: 12,
        paddingHorizontal: 20,
        paddingVertical: 18,
        borderRadius: 20,
        backgroundColor: '#fff',
    },
    itemText: {
        fontSize: 17,
        fontWeight: '500',
    },
});
