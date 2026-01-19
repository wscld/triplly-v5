import { View, Text, StyleSheet } from 'react-native';
import MapView, { Marker, Polyline, PROVIDER_DEFAULT } from 'react-native-maps';
import { useCallback } from 'react';
import type { Activity } from '@/lib/types';

interface Props {
    activities: Activity[];
}

export default function ItineraryMap({ activities }: Props) {
    const coordinates = activities.map((a) => ({
        latitude: a.latitude,
        longitude: a.longitude,
    }));

    const getMapRegion = useCallback(() => {
        if (coordinates.length === 0) {
            return {
                latitude: 35.6762,
                longitude: 139.6503,
                latitudeDelta: 0.1,
                longitudeDelta: 0.1,
            };
        }

        const lats = coordinates.map((c) => c.latitude);
        const lngs = coordinates.map((c) => c.longitude);
        const minLat = Math.min(...lats);
        const maxLat = Math.max(...lats);
        const minLng = Math.min(...lngs);
        const maxLng = Math.max(...lngs);

        return {
            latitude: (minLat + maxLat) / 2,
            longitude: (minLng + maxLng) / 2,
            latitudeDelta: Math.max(0.02, (maxLat - minLat) * 1.5),
            longitudeDelta: Math.max(0.02, (maxLng - minLng) * 1.5),
        };
    }, [coordinates]);

    return (
        <MapView
            style={StyleSheet.absoluteFill}
            provider={PROVIDER_DEFAULT}
            region={getMapRegion()}
            scrollEnabled={true}
            zoomEnabled={true}
        >
            {activities.map((activity, index) => (
                <Marker
                    key={activity.id}
                    coordinate={{
                        latitude: activity.latitude,
                        longitude: activity.longitude,
                    }}
                    title={activity.title}
                >
                    <View style={styles.markerContainer}>
                        <View style={styles.marker}>
                            <Text style={styles.markerText}>{index + 1}</Text>
                        </View>
                    </View>
                </Marker>
            ))}
            {coordinates.length >= 2 && (
                <Polyline
                    coordinates={coordinates}
                    strokeColor="#007AFF"
                    strokeWidth={3}
                />
            )}
        </MapView>
    );
}

const styles = StyleSheet.create({
    markerContainer: {
        alignItems: 'center',
    },
    marker: {
        width: 28,
        height: 28,
        borderRadius: 14,
        backgroundColor: '#007AFF',
        alignItems: 'center',
        justifyContent: 'center',
        borderWidth: 2,
        borderColor: '#fff',
    },
    markerText: {
        fontSize: 12,
        fontWeight: '700',
        color: '#fff',
    },
});
