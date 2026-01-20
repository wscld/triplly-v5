import React, { useState, useRef, useEffect, useCallback } from 'react';
import { View, Text, TouchableOpacity, StyleSheet, ActivityIndicator, FlatList } from 'react-native';
import { BottomSheetModal, BottomSheetView, BottomSheetBackdrop, BottomSheetFlatList, BottomSheetTextInput } from '@gorhom/bottom-sheet';
import { Ionicons } from '@expo/vector-icons';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { api } from '@/lib/api';
import type { Todo } from '@/lib/types';
import { Colors } from '@/constants/colors';

interface Props {
    isOpen: boolean;
    onClose: () => void;
    travelId: string;
}

export default function TodoList({ isOpen, onClose, travelId }: Props) {
    const queryClient = useQueryClient();
    const bottomSheetModalRef = useRef<BottomSheetModal>(null);
    const [newTodoTitle, setNewTodoTitle] = useState('');

    useEffect(() => {
        if (isOpen) {
            bottomSheetModalRef.current?.present();
        } else {
            bottomSheetModalRef.current?.dismiss();
        }
    }, [isOpen]);

    const handleSheetChanges = useCallback((index: number) => {
        if (index === -1) {
            onClose();
        }
    }, [onClose]);

    const renderBackdrop = useCallback(
        (props: any) => (
            <BottomSheetBackdrop
                {...props}
                disappearsOnIndex={-1}
                appearsOnIndex={0}
                opacity={0.5}
            />
        ),
        []
    );

    const { data: todos, isLoading } = useQuery({
        queryKey: ['todos', travelId],
        queryFn: () => api.getTodos(travelId),
        enabled: isOpen,
    });

    const createTodo = useMutation({
        mutationFn: (title: string) => api.createTodo({ travelId, title }),
        onMutate: async (newTitle) => {
            await queryClient.cancelQueries({ queryKey: ['todos', travelId] });
            const previousTodos = queryClient.getQueryData(['todos', travelId]);

            queryClient.setQueryData<Todo[]>(['todos', travelId], (old) => {
                const tempTodo: Todo = {
                    id: Math.random().toString(),
                    title: newTitle,
                    isCompleted: false,
                    travelId: travelId,
                    createdAt: new Date().toISOString(),
                    updatedAt: new Date().toISOString()
                };
                return old ? [...old, tempTodo] : [tempTodo];
            });

            return { previousTodos };
        },
        onSuccess: () => {
            setNewTodoTitle('');
        },
        onError: (err, newTodo, context) => {
            if (context?.previousTodos) {
                queryClient.setQueryData(['todos', travelId], context.previousTodos);
            }
        },
        onSettled: () => {
            queryClient.invalidateQueries({ queryKey: ['todos', travelId] });
        }
    });

    const toggleTodo = useMutation({
        mutationFn: (todo: Todo) => api.updateTodo(todo.id, { isCompleted: !todo.isCompleted }),
        onMutate: async (todoToToggle) => {
            await queryClient.cancelQueries({ queryKey: ['todos', travelId] });
            const previousTodos = queryClient.getQueryData(['todos', travelId]);

            queryClient.setQueryData<Todo[]>(['todos', travelId], (old) => {
                return old?.map(t =>
                    t.id === todoToToggle.id ? { ...t, isCompleted: !t.isCompleted } : t
                );
            });

            return { previousTodos };
        },
        onError: (err, newTodo, context) => {
            if (context?.previousTodos) {
                queryClient.setQueryData(['todos', travelId], context.previousTodos);
            }
        },
        onSettled: () => {
            queryClient.invalidateQueries({ queryKey: ['todos', travelId] });
        }
    });

    const deleteTodo = useMutation({
        mutationFn: (id: string) => api.deleteTodo(id),
        onMutate: async (idToDelete) => {
            await queryClient.cancelQueries({ queryKey: ['todos', travelId] });
            const previousTodos = queryClient.getQueryData(['todos', travelId]);

            queryClient.setQueryData<Todo[]>(['todos', travelId], (old) => {
                return old?.filter(t => t.id !== idToDelete);
            });

            return { previousTodos };
        },
        onError: (err, newTodo, context) => {
            if (context?.previousTodos) {
                queryClient.setQueryData(['todos', travelId], context.previousTodos);
            }
        },
        onSettled: () => {
            queryClient.invalidateQueries({ queryKey: ['todos', travelId] });
        }
    });

    const completedCount = todos?.filter(t => t.isCompleted).length || 0;
    const totalCount = todos?.length || 0;
    const progress = totalCount > 0 ? (completedCount / totalCount) * 100 : 0;

    const handleAdd = () => {
        if (!newTodoTitle.trim()) return;
        createTodo.mutate(newTodoTitle.trim());
    };

    const renderItem = ({ item }: { item: Todo }) => (
        <View style={styles.todoItem}>
            <TouchableOpacity
                style={styles.todoContent}
                onPress={() => toggleTodo.mutate(item)}
            >
                <View style={[
                    styles.checkbox,
                    item.isCompleted && styles.checkboxChecked
                ]}>
                    {item.isCompleted && <Ionicons name="checkmark" size={14} color={Colors.text.primary} />}
                </View>
                <Text style={[
                    styles.todoText,
                    item.isCompleted && styles.todoTextCompleted
                ]}>
                    {item.title}
                </Text>
            </TouchableOpacity>

            <TouchableOpacity onPress={() => deleteTodo.mutate(item.id)} style={styles.deleteButton}>
                <Ionicons name="trash-outline" size={18} color={Colors.error} />
            </TouchableOpacity>
        </View>
    );

    return (
        <BottomSheetModal
            ref={bottomSheetModalRef}
            onChange={handleSheetChanges}
            snapPoints={['70%']}
            enablePanDownToClose
            backdropComponent={renderBackdrop}
            handleIndicatorStyle={styles.handle}
            backgroundStyle={styles.background}
            keyboardBehavior="interactive"
            keyboardBlurBehavior="restore"
        >
            <View style={styles.container}>
                {/* Header */}
                <View style={styles.header}>
                    <Text style={styles.title}>Planejamento</Text>
                    <Text style={styles.subtitle}>Complete os itens para organizar sua viagem.</Text>
                </View>

                {/* Progress */}
                <View style={styles.progressContainer}>
                    <Text style={styles.progressText}>{Math.round(progress)}%</Text>
                    <View style={styles.progressBar}>
                        <View style={[styles.progressFill, { width: `${progress}%` }]} />
                    </View>
                </View>

                {/* List - takes remaining space */}
                <View style={styles.listWrapper}>
                    {isLoading ? (
                        <ActivityIndicator size="small" style={styles.loader} />
                    ) : (
                        <BottomSheetFlatList
                            data={todos}
                            keyExtractor={(item: Todo) => item.id}
                            renderItem={renderItem}
                            contentContainerStyle={styles.listContent}
                            ListEmptyComponent={
                                <View style={styles.empty}>
                                    <Text style={styles.emptyText}>Nenhum item adicionado ainda.</Text>
                                </View>
                            }
                        />
                    )}
                </View>

                {/* Input - stays at bottom */}
                <View style={styles.inputContainer}>
                    <BottomSheetTextInput
                        style={styles.input}
                        placeholder="Adicionar novo item..."
                        placeholderTextColor={Colors.text.secondary}
                        value={newTodoTitle}
                        onChangeText={setNewTodoTitle}
                        onSubmitEditing={handleAdd}
                    />
                    <TouchableOpacity
                        style={[styles.addButton, !newTodoTitle.trim() && styles.addButtonDisabled]}
                        onPress={handleAdd}
                        disabled={!newTodoTitle.trim() || createTodo.isPending}
                    >
                        {createTodo.isPending ? (
                            <ActivityIndicator color={Colors.text.primary} size="small" />
                        ) : (
                            <Ionicons name="arrow-up" size={20} color={Colors.text.primary} />
                        )}
                    </TouchableOpacity>
                </View>
            </View>
        </BottomSheetModal>
    );
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
        paddingHorizontal: 20,
    },
    handle: {
        backgroundColor: '#D1D1D6',
        width: 36,
    },
    background: {
        backgroundColor: Colors.background,
    },
    header: {
        marginBottom: 16,
    },
    title: {
        fontSize: 24,
        fontWeight: '700',
        color: Colors.text.primary,
    },
    subtitle: {
        fontSize: 14,
        color: Colors.text.secondary,
        marginTop: 4,
    },
    progressContainer: {
        flexDirection: 'row',
        alignItems: 'center',
        marginBottom: 16,
        gap: 12,
    },
    progressText: {
        fontSize: 16,
        fontWeight: '700',
        color: Colors.text.primary,
    },
    progressBar: {
        flex: 1,
        height: 8,
        backgroundColor: '#fff',
        borderRadius: 4,
        overflow: 'hidden',
    },
    progressFill: {
        height: '100%',
        backgroundColor: Colors.primary,
        borderRadius: 4,
    },
    listWrapper: {
        flex: 1,
    },
    listContent: {
        paddingBottom: 20,
    },
    todoItem: {
        flexDirection: 'row',
        alignItems: 'center',
        justifyContent: 'space-between',
        backgroundColor: '#fff',
        padding: 16,
        borderRadius: 16,
        marginBottom: 12,
        borderWidth: 1,
        borderColor: Colors.border.light,
    },
    todoContent: {
        flexDirection: 'row',
        alignItems: 'center',
        flex: 1,
        gap: 12,
    },
    checkbox: {
        width: 24,
        height: 24,
        borderRadius: 12,
        borderWidth: 2,
        borderColor: Colors.border.light,
        alignItems: 'center',
        justifyContent: 'center',
    },
    checkboxChecked: {
        backgroundColor: Colors.primary,
        borderColor: Colors.primary,
    },
    todoText: {
        fontSize: 16,
        color: Colors.text.primary,
        flex: 1,
    },
    todoTextCompleted: {
        color: Colors.text.secondary,
        textDecorationLine: 'line-through',
    },
    deleteButton: {
        padding: 4,
    },
    empty: {
        alignItems: 'center',
        paddingVertical: 40,
    },
    emptyText: {
        color: Colors.text.secondary,
    },
    loader: {
        marginTop: 20,
    },
    inputContainer: {
        flexDirection: 'row',
        gap: 12,
        paddingTop: 12,
        paddingBottom: 24,
        borderTopWidth: 1,
        borderTopColor: Colors.border.light,
    },
    input: {
        flex: 1,
        backgroundColor: '#fff',
        borderRadius: 24,
        paddingHorizontal: 16,
        paddingVertical: 12,
        fontSize: 16,
        borderWidth: 1,
        borderColor: Colors.border.light,
    },
    addButton: {
        width: 44,
        height: 44,
        borderRadius: 22,
        backgroundColor: Colors.primary,
        alignItems: 'center',
        justifyContent: 'center',
    },
    addButtonDisabled: {
        opacity: 0.5,
    },
});
