import { View, StyleSheet } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { Colors } from '@/constants/colors';
import Skeleton from './Skeleton';

export default function TravelDetailSkeleton() {
    const insets = useSafeAreaInsets();

    return (
        <View
            style={[styles.container, { paddingTop: insets.top }]}
            accessibilityLabel="Loading travel details"
        >
            {/* Header placeholder */}
            <View style={styles.header}>
                <Skeleton width={40} height={40} borderRadius={20} />
                <Skeleton width={80} height={36} borderRadius={18} />
            </View>

            {/* Cover image placeholder */}
            <Skeleton width="100%" height={200} borderRadius={0} />

            {/* Content */}
            <View style={styles.content}>
                {/* Title */}
                <Skeleton width="70%" height={28} borderRadius={6} style={{ marginBottom: 8 }} />
                {/* Date */}
                <Skeleton width="40%" height={14} borderRadius={4} style={{ marginBottom: 24 }} />

                {/* Day selector area */}
                <Skeleton width="100%" height={60} borderRadius={16} style={{ marginBottom: 24 }} />

                {/* Activity lines */}
                <Skeleton width="100%" height={56} borderRadius={12} style={{ marginBottom: 12 }} />
                <Skeleton width="100%" height={56} borderRadius={12} style={{ marginBottom: 12 }} />
                <Skeleton width="100%" height={56} borderRadius={12} />
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
        alignItems: 'center',
        paddingHorizontal: 24,
        paddingVertical: 12,
    },
    content: {
        paddingHorizontal: 24,
        paddingTop: 24,
    },
});
