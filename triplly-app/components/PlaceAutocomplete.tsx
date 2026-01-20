import React, { useState, useEffect } from 'react';
import { View, Text, TouchableOpacity, ActivityIndicator, ScrollView, StyleSheet } from 'react-native';
import { BottomSheetTextInput } from '@gorhom/bottom-sheet';
import { Ionicons } from '@expo/vector-icons';
import { Colors } from '@/constants/colors';

interface Place {
    place_id: number;
    lat: string;
    lon: string;
    display_name: string;
    address?: any;
}

interface Props {
    onSelect: (place: { lat: number; lon: number; latitude?: number; longitude?: number; name: string; placeId: string; address: string }) => void;
    placeholder?: string;
    initialValue?: string;
}

export default function PlaceAutocomplete({ onSelect, placeholder = "Search for a place...", initialValue }: Props) {
    const [query, setQuery] = useState(initialValue || '');
    const [results, setResults] = useState<Place[]>([]);
    const [loading, setLoading] = useState(false);
    const [showResults, setShowResults] = useState(false);

    // Debounced search function
    useEffect(() => {
        const searchPlaces = async () => {
            if (query.length < 3) {
                setResults([]);
                return;
            }

            setLoading(true);
            setShowResults(true);
            try {
                const response = await fetch(
                    `https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(query)}&limit=5&addressdetails=1`,
                    {
                        headers: {
                            'User-Agent': 'Triplly/1.0',
                        },
                    }
                );
                const data = await response.json();
                setResults(data);
            } catch (error) {
                console.error('Search failed:', error);
            } finally {
                setLoading(false);
            }
        };

        const debouncedSearch = setTimeout(searchPlaces, 500);
        return () => clearTimeout(debouncedSearch);
    }, [query]);

    useEffect(() => {
        if (initialValue) {
            setQuery(initialValue);
        }
    }, [initialValue]);

    const handleSelect = (place: Place) => {
        setQuery(place.display_name.split(',')[0]); // Set simple name in input
        setShowResults(false);
        onSelect({
            lat: parseFloat(place.lat),
            lon: parseFloat(place.lon),
            latitude: parseFloat(place.lat),
            longitude: parseFloat(place.lon),
            name: place.display_name.split(',')[0],
            placeId: place.place_id.toString(),
            address: place.display_name,
        });
    };

    return (
        <View style={styles.container}>
            <View style={styles.inputContainer}>
                <BottomSheetTextInput
                    style={styles.input}
                    placeholder={placeholder}
                    placeholderTextColor={Colors.text.secondary}
                    value={query}
                    onChangeText={setQuery}
                    onFocus={() => query.length >= 3 && setShowResults(true)}
                />
                {loading && (
                    <View style={styles.loadingContainer}>
                        <ActivityIndicator size="small" color={Colors.primary} />
                    </View>
                )}
            </View>

            {showResults && results.length > 0 && (
                <View style={styles.resultsContainer}>
                    <ScrollView keyboardShouldPersistTaps="handled">
                        {results.map((item) => (
                            <TouchableOpacity
                                key={item.place_id}
                                onPress={() => handleSelect(item)}
                                style={styles.resultItem}
                            >
                                <Ionicons name="location-outline" size={20} color="#666" />
                                <Text style={styles.resultText}>{item.display_name}</Text>
                            </TouchableOpacity>
                        ))}
                    </ScrollView>
                </View>
            )}
        </View>
    );
}

const styles = StyleSheet.create({
    container: {
        zIndex: 999,
    },
    inputContainer: {
        position: 'relative',
    },
    input: {
        borderWidth: 1,
        borderColor: '#E5E5E5',
        borderRadius: 4,
        paddingHorizontal: 12,
        paddingVertical: 10,
        fontSize: 16,
        backgroundColor: '#fff',
        color: Colors.text.primary,
    },
    loadingContainer: {
        position: 'absolute',
        right: 12,
        top: 12,
    },
    resultsContainer: {
        backgroundColor: 'white',
        borderRadius: 8,
        borderWidth: 1,
        borderColor: '#E5E5E5',
        marginTop: 4,
        maxHeight: 200,
    },
    resultItem: {
        padding: 12,
        borderBottomWidth: 1,
        borderBottomColor: '#F0F0F0',
        flexDirection: 'row',
        alignItems: 'center',
        gap: 10,
    },
    resultText: {
        fontSize: 14,
        color: '#333',
        flex: 1,
    },
});
