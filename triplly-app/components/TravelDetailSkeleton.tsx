import { View, StyleSheet } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Colors } from '@/constants/colors';
import Skeleton from './Skeleton';

export default function TravelDetailSkeleton() {
    const insets = useSafeAreaInsets();

    return (
        <View style={[styles.container, { paddingTop: insets.top }]}>
            {/* Header Area */}
            <View style={styles.header}>
                <Skeleton width={40} height={40} borderRadius={20} />
                <View style={styles.avatars}>
                    <Skeleton width={32} height={32} borderRadius={16} style={{ marginLeft: -10 }} />
                    <Skeleton width={32} height={32} borderRadius={16} style={{ marginLeft: -10 }} />
                    <Skeleton width={32} height={32} borderRadius={16} style={{ marginLeft: -10 }} />
                </View>
            </View>

            {/* Map Placeholder */}
            <View style={styles.mapPlaceholder}>
                <Skeleton width="100%" height={120} borderRadius={0} />
            </View>

            {/* Content Content */}
            <View style={styles.content}>
                {/* Title and Date */}
                <View style={styles.titleSection}>
                    <Skeleton width="70%" height={32} borderRadius={8} style={{ marginBottom: 8 }} />
                    <Skeleton width="40%" height={16} borderRadius={4} />
                </View>

                {/* Day Selector */}
                <View style={styles.daySelector}>
                    {[1, 2, 3, 4].map((_, i) => (
                        <Skeleton
                            key={i}
                            width={50}
                            height={60}
                            borderRadius={12}
                            style={{ marginRight: 10 }}
                        />
                    ))}
                </View>

                {/* Activity List */}
                <View style={styles.activityList}>
                    {[1, 2].map((_, i) => (
                        <View key={i} style={styles.activityCard}>
                            <View style={styles.timeColumn}>
                                <Skeleton width={40} height={12} borderRadius={4} />
                            </View>
                            <View style={styles.cardContent}>
                                <Skeleton width="60%" height={16} borderRadius={4} style={{ marginBottom: 8 }} />
                                <Skeleton width="40%" height={12} borderRadius={4} />
                            </View>
                        </View>
                    ))}
                </View>
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
        paddingVertical: 10,
        marginBottom: 10,
    },
    avatars: {
        flexDirection: 'row',
        paddingLeft: 10,
    },
    mapPlaceholder: {
        marginBottom: 24,
    },
    content: {
        paddingHorizontal: 24,
    },
    titleSection: {
        marginBottom: 32,
    },
    daySelector: {
        flexDirection: 'row',
        marginBottom: 32,
        overflow: 'hidden',
    },
    activityList: {
        gap: 16,
    },
    activityCard: {
        flexDirection: 'row',
        marginBottom: 24,
    },
    timeColumn: {
        width: 50,
        marginRight: 12,
        alignItems: 'flex-end',
        paddingTop: 4,
    },
    cardContent: {
        flex: 1,
        backgroundColor: Colors.white,
        borderRadius: 16,
        padding: 16,
        borderWidth: 1,
        borderColor: Colors.border.light,
    },
});
