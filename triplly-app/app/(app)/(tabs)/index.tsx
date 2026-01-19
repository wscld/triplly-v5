import { View, Text, FlatList, TouchableOpacity, StyleSheet, Alert } from 'react-native';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { Link } from 'expo-router';
import { Ionicons } from '@expo/vector-icons';
import { api } from '@/lib/api';
import type { TravelListItem } from '@/lib/types';
import { formatDateRange } from '@/utils/distance';
import { useState } from 'react';
import SheetForm from '@/components/SheetForm';
import DatePickerInput from '@/components/DatePickerInput';
import { Input, InputField, VStack, Text as GText, Textarea, TextareaInput } from '@gluestack-ui/themed';
import { SafeAreaView } from 'react-native-safe-area-context';
import Skeleton from '@/components/Skeleton';

function TravelCardSkeleton() {
    return (
        <View style={styles.card}>
            <View style={styles.cardContent}>
                <View>
                    <Skeleton width={200} height={32} borderRadius={8} />
                    <Skeleton width={120} height={16} borderRadius={4} style={{ marginTop: 8 }} />
                </View>
                <View style={styles.cardFooter}>
                    <Skeleton width={60} height={28} borderRadius={14} />
                    <Skeleton width={20} height={20} borderRadius={10} />
                </View>
            </View>
        </View>
    );
}

function TravelCard({ travel }: { travel: TravelListItem }) {
    return (
        <Link href={`/(app)/travel/${travel.id}`} asChild>
            <TouchableOpacity style={styles.card}>
                <View style={styles.cardContent}>
                    <View>
                        <Text style={styles.cardTitle}>{travel.title}</Text>
                        {(travel.startDate || travel.endDate) && (
                            <Text style={styles.cardDates}>
                                {formatDateRange(travel.startDate, travel.endDate)}
                            </Text>
                        )}
                    </View>
                    <View style={styles.cardFooter}>
                        <View style={styles.roleBadge}>
                            <Text style={styles.roleText}>{travel.role}</Text>
                        </View>
                        <Ionicons name="arrow-forward" size={20} color="#1C1C1E" />
                    </View>
                </View>
            </TouchableOpacity>
        </Link>
    );
}

export default function TravelListScreen() {
    const queryClient = useQueryClient();
    const [showCreateSheet, setShowCreateSheet] = useState(false);

    const [formData, setFormData] = useState({
        title: '',
        description: '',
        startDate: null as Date | null,
        endDate: null as Date | null,
    });

    const { data: travels, isLoading, error } = useQuery({
        queryKey: ['travels'],
        queryFn: () => api.getTravels(),
    });

    const createTravel = useMutation({
        mutationFn: () => api.createTravel({
            ...formData,
            startDate: formData.startDate ? formData.startDate.toISOString().split('T')[0] : '',
            endDate: formData.endDate ? formData.endDate.toISOString().split('T')[0] : '',
        }),
        onSuccess: () => {
            queryClient.invalidateQueries({ queryKey: ['travels'] });
            setShowCreateSheet(false);
            setFormData({ title: '', description: '', startDate: null, endDate: null });
        },
        onError: (err) => {
            Alert.alert('Error', err instanceof Error ? err.message : 'Failed to create travel');
        },
    });

    if (error) {
        return (
            <View style={styles.centered}>
                <Text style={styles.errorText}>Failed to load travels: {error instanceof Error ? error.message : 'Unknown error'}</Text>
                <TouchableOpacity onPress={() => queryClient.refetchQueries({ queryKey: ['travels'] })} style={styles.retryButton}>
                    <Text style={styles.retryText}>Retry</Text>
                </TouchableOpacity>
            </View>
        );
    }

    return (
        <View style={styles.container}>
            <SafeAreaView style={{ flex: 1 }} edges={['top']}>
                <View style={styles.header}>
                    <Text style={styles.headerTitle}>Minhas Viagens</Text>
                </View>

                {isLoading ? (
                    <View style={styles.list}>
                        <TravelCardSkeleton />
                        <TravelCardSkeleton />
                        <TravelCardSkeleton />
                    </View>
                ) : (
                    <FlatList
                        data={travels}
                        keyExtractor={(item) => item.id}
                        renderItem={({ item }) => <TravelCard travel={item} />}
                        contentContainerStyle={styles.list}
                        ListEmptyComponent={
                            <View style={styles.empty}>
                                <Ionicons name="earth" size={64} color="#C7C7CC" />
                                <Text style={styles.emptyTitle}>No travels yet</Text>
                                <Text style={styles.emptySubtext}>Plan your first adventure</Text>
                            </View>
                        }
                    />
                )}

                <TouchableOpacity
                    style={styles.fab}
                    onPress={() => setShowCreateSheet(true)}
                >
                    <Ionicons name="add" size={32} color="#fff" />
                </TouchableOpacity>

                <SheetForm
                    isOpen={showCreateSheet}
                    onClose={() => setShowCreateSheet(false)}
                    title="New Trip"
                    onSubmit={() => createTravel.mutate()}
                    isSubmitting={createTravel.isPending}
                    submitLabel="Create"
                >
                    <VStack space="md">
                        <VStack space="xs">
                            <GText size="xs" color="$coolGray500">TITLE</GText>
                            <Input>
                                <InputField
                                    placeholder="Where are you going?"
                                    value={formData.title}
                                    onChangeText={(t) => setFormData(d => ({ ...d, title: t }))}
                                    autoFocus
                                />
                            </Input>
                        </VStack>

                        <VStack space="xs">
                            <GText size="xs" color="$coolGray500">DESCRIPTION</GText>
                            <Textarea>
                                <TextareaInput
                                    placeholder="Add details..."
                                    value={formData.description}
                                    onChangeText={(t) => setFormData(d => ({ ...d, description: t }))}
                                />
                            </Textarea>
                        </VStack>

                        <DatePickerInput
                            label="START DATE"
                            value={formData.startDate}
                            onChange={(date) => setFormData(d => ({ ...d, startDate: date }))}
                        />

                        <DatePickerInput
                            label="END DATE"
                            value={formData.endDate}
                            onChange={(date) => setFormData(d => ({ ...d, endDate: date }))}
                            minDate={formData.startDate || undefined}
                        />
                    </VStack>
                </SheetForm>
            </SafeAreaView>
        </View>
    );
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: '#F2F0E9',
    },
    centered: {
        flex: 1,
        justifyContent: 'center',
        alignItems: 'center',
        backgroundColor: '#F2F0E9',
    },
    header: {
        paddingHorizontal: 24,
        paddingVertical: 24,
    },
    headerTitle: {
        fontSize: 40,
        fontWeight: '400',
        color: '#1C1C1E',
        letterSpacing: -0.5,
    },
    list: {
        padding: 20,
        gap: 20,
        paddingBottom: 100,
    },
    card: {
        height: 200,
        backgroundColor: '#fff',
        borderRadius: 32,
        padding: 24,
        justifyContent: 'space-between',
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 8 },
        shadowOpacity: 0.05,
        shadowRadius: 24,
        elevation: 4,
    },
    cardContent: {
        flex: 1,
        justifyContent: 'space-between',
    },
    cardTitle: {
        fontSize: 32,
        fontWeight: '400',
        color: '#1C1C1E',
        lineHeight: 36,
    },
    cardDates: {
        fontSize: 15,
        color: '#636366',
        fontWeight: '500',
        marginTop: 4,
        textTransform: 'uppercase',
        letterSpacing: 1,
    },
    cardFooter: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
    },
    roleBadge: {
        backgroundColor: '#F2F0E9',
        paddingHorizontal: 12,
        paddingVertical: 6,
        borderRadius: 100,
    },
    roleText: {
        fontSize: 12,
        color: '#1C1C1E',
        textTransform: 'uppercase',
        fontWeight: '600',
        letterSpacing: 0.5,
    },
    empty: {
        alignItems: 'center',
        paddingTop: 80,
        gap: 8,
    },
    emptyTitle: {
        fontSize: 20,
        fontWeight: '600',
        color: '#1C1C1E',
        marginTop: 16,
    },
    emptySubtext: {
        fontSize: 15,
        color: '#636366',
    },
    fab: {
        position: 'absolute',
        right: 24,
        bottom: 110,
        width: 64,
        height: 64,
        borderRadius: 32,
        backgroundColor: '#1C1C1E',
        alignItems: 'center',
        justifyContent: 'center',
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.2,
        shadowRadius: 8,
        elevation: 6,
    },
    errorText: {
        fontSize: 16,
        color: '#666',
        marginBottom: 16,
    },
    retryButton: {
        paddingHorizontal: 24,
        paddingVertical: 12,
        backgroundColor: '#1C1C1E',
        borderRadius: 100,
    },
    retryText: {
        color: '#fff',
        fontWeight: '600',
    },
});
