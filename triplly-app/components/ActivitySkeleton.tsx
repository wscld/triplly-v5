import { View, StyleSheet } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Colors } from '@/constants/colors';
import Skeleton from './Skeleton';

export default function ActivitySkeleton() {
    const insets = useSafeAreaInsets();

    return (
        <View
            style={styles.container}
            accessibilityLabel="Loading activity details"
        >
            {/* Header buttons */}
            <View style={[styles.header, { paddingTop: insets.top + 10 }]}>
                <Skeleton width={40} height={40} borderRadius={20} />
                <Skeleton width={40} height={40} borderRadius={20} />
            </View>

            {/* Content */}
            <View style={[styles.content, { paddingTop: insets.top + 70 }]}>
                {/* Title */}
                <Skeleton width="75%" height={28} borderRadius={6} style={{ marginBottom: 16 }} />

                {/* Details card */}
                <View style={styles.card}>
                    <Skeleton width="100%" height={16} borderRadius={4} style={{ marginBottom: 12 }} />
                    <Skeleton width="60%" height={14} borderRadius={4} style={{ marginBottom: 24 }} />
                    <Skeleton width="100%" height={44} borderRadius={10} />
                </View>

                {/* Comments section */}
                <Skeleton width="30%" height={16} borderRadius={4} style={{ marginBottom: 12 }} />
                <Skeleton width="100%" height={80} borderRadius={12} />
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
    },
    content: {
        paddingHorizontal: 24,
    },
    card: {
        backgroundColor: Colors.white,
        borderRadius: 20,
        padding: 20,
        marginBottom: 24,
    },
});
