import { View, StyleSheet } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Colors } from '@/constants/colors';
import Skeleton from './Skeleton';
import { Ionicons } from '@expo/vector-icons';

export default function ActivitySkeleton() {
    const insets = useSafeAreaInsets();

    return (
        <View style={styles.container}>
            {/* Header Area */}
            <View style={[styles.header, { paddingTop: insets.top + 10 }]}>
                <View style={styles.headerButton}>
                    <Ionicons name="arrow-back" size={24} color={Colors.border.medium} />
                </View>
                <View style={styles.headerButton}>
                    <Ionicons name="pencil" size={22} color={Colors.border.medium} />
                </View>
            </View>

            {/* Content Content - Simulating layout */}
            <View style={[styles.content, { paddingTop: insets.top + 60 }]}>
                {/* Title */}
                <Skeleton width="80%" height={32} borderRadius={8} style={{ marginBottom: 12 }} />

                {/* Subtitle Row */}
                <View style={styles.subtitleRow}>
                    <Skeleton width={100} height={16} borderRadius={4} />
                    <Skeleton width={150} height={16} borderRadius={4} />
                </View>

                {/* Details Card */}
                <View style={styles.card}>
                    <Skeleton width="100%" height={16} borderRadius={4} style={{ marginBottom: 8 }} />
                    <Skeleton width="90%" height={16} borderRadius={4} style={{ marginBottom: 8 }} />
                    <Skeleton width="40%" height={16} borderRadius={4} style={{ marginBottom: 24 }} />

                    {/* Added By Section */}
                    <View style={styles.addedBy}>
                        <Skeleton width="60%" height={14} borderRadius={4} />
                    </View>

                    {/* Action Button */}
                    <Skeleton width="100%" height={48} borderRadius={12} style={{ marginTop: 24 }} />
                </View>

                {/* Comments Header */}
                <Skeleton width={120} height={20} borderRadius={4} style={{ marginBottom: 16 }} />

                {/* Empty State / Comments Placeholder */}
                <Skeleton width="100%" height={100} borderRadius={16} />

            </View>
        </View>
    );
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: Colors.background,
    },
    header: {
        flexDirection: 'row',
        justifyContent: 'space-between',
        paddingHorizontal: 24,
        position: 'absolute',
        top: 0,
        left: 0,
        right: 0,
        zIndex: 10,
    },
    headerButton: {
        width: 40,
        height: 40,
        borderRadius: 20,
        backgroundColor: '#fff',
        alignItems: 'center',
        justifyContent: 'center',
        borderWidth: 1,
        borderColor: Colors.border.light,
    },
    content: {
        paddingHorizontal: 24,
    },
    subtitleRow: {
        flexDirection: 'row',
        gap: 12,
        marginBottom: 32,
    },
    card: {
        backgroundColor: '#fff',
        borderRadius: 24,
        padding: 24,
        marginBottom: 32,
        borderWidth: 1,
        borderColor: Colors.border.light,
    },
    addedBy: {
        paddingTop: 16,
        borderTopWidth: 1,
        borderTopColor: Colors.border.light,
    },
});
