import React, { useState, useEffect } from 'react';
import { View, Text, TouchableOpacity, ActivityIndicator, ScrollView } from 'react-native';
import { Input, InputField, VStack, Box } from '@gluestack-ui/themed';
import { Ionicons } from '@expo/vector-icons';

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
            // ... existing logic ...
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
        <VStack space="md" zIndex={999}>
            <Input>
                <InputField
                    placeholder={placeholder}
                    value={query}
                    onChangeText={setQuery}
                    onFocus={() => query.length >= 3 && setShowResults(true)}
                />
                {loading && (
                    <Box position="absolute" right={12} top={12}>
                        <ActivityIndicator size="small" color="#007AFF" />
                    </Box>
                )}
            </Input>

            {showResults && results.length > 0 && (
                <View
                    style={{
                        backgroundColor: 'white',
                        borderRadius: 8,
                        borderWidth: 1,
                        borderColor: '#E5E5E5',
                        marginTop: 4,
                        maxHeight: 200,
                    }}
                >
                    <ScrollView keyboardShouldPersistTaps="handled">
                        {results.map((item) => (
                            <TouchableOpacity
                                key={item.place_id}
                                onPress={() => handleSelect(item)}
                                style={{
                                    padding: 12,
                                    borderBottomWidth: 1,
                                    borderBottomColor: '#F0F0F0',
                                    flexDirection: 'row',
                                    alignItems: 'center',
                                    gap: 10,
                                }}
                            >
                                <Ionicons name="location-outline" size={20} color="#666" />
                                <Text style={{ fontSize: 14, color: '#333', flex: 1 }}>{item.display_name}</Text>
                            </TouchableOpacity>
                        ))}
                    </ScrollView>
                </View>
            )}
        </VStack>
    );
}
