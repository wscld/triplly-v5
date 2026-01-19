import { View, Text, StyleSheet } from 'react-native';
import type { Activity } from '@/lib/types';
import { Ionicons } from '@expo/vector-icons';

interface Props {
    activities: Activity[];
}

export default function ItineraryMap({ activities }: Props) {
    return (
        <View style={styles.container}>
            <View style={styles.content}>
                <Ionicons name="map-outline" size={48} color="#C7C7CC" />
                <Text style={styles.text}>Map view not available on web</Text>
                <Text style={styles.subtext}>Use method to visualize itinerary</Text>
            </View>
        </View>
    );
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: '#F2F2F7',
        alignItems: 'center',
        justifyContent: 'center',
    },
    content: {
        alignItems: 'center',
        gap: 8,
    },
    text: {
        fontSize: 16,
        fontWeight: '600',
        color: '#666',
        marginTop: 8,
    },
    subtext: {
        fontSize: 14,
        color: '#999',
    },
});
