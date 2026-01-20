import React, { useState } from 'react';
import Animated, { useSharedValue, useAnimatedStyle, useAnimatedScrollHandler, interpolate, Extrapolation } from 'react-native-reanimated';
import {
    Actionsheet,
    ActionsheetBackdrop,
    ActionsheetContent,
    ActionsheetDragIndicator,
    ActionsheetDragIndicatorWrapper,
    VStack,
    Text,
    HStack,
    Box,
    Progress,
    ProgressFilledTrack,
    Input,
    InputField,
    Pressable,
} from '@gluestack-ui/themed';
import { KeyboardAvoidingView, Platform, FlatList, TouchableOpacity, ActivityIndicator, TouchableWithoutFeedback, Keyboard, FlatListProps } from 'react-native';
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

const AnimatedFlatList = Animated.createAnimatedComponent<FlatListProps<Todo>>(FlatList);

export default function TodoList({ isOpen, onClose, travelId }: Props) {
    const queryClient = useQueryClient();
    const [newTodoTitle, setNewTodoTitle] = useState('');

    // Animation constants
    const HEADER_HEIGHT = 140;

    // Animation state
    const scrollY = useSharedValue(0);
    const scrollHandler = useAnimatedScrollHandler({
        onScroll: (event) => {
            scrollY.value = event.contentOffset.y;
        },
    });

    const headerStyle = useAnimatedStyle(() => {
        const translateY = interpolate(
            scrollY.value,
            [0, HEADER_HEIGHT],
            [0, -HEADER_HEIGHT],
            Extrapolation.CLAMP
        );

        const opacity = interpolate(
            scrollY.value,
            [0, HEADER_HEIGHT / 2],
            [1, 0],
            Extrapolation.CLAMP
        );

        return {
            transform: [{ translateY }],
            opacity,
            position: 'absolute',
            top: 0,
            left: 20, // Padding from parent container
            right: 20,
            zIndex: 1,
        };
    });

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
        <HStack
            alignItems="center"
            justifyContent="space-between"
            p="$4"
            bg="$white"
            borderRadius="$xl"
            mb="$3"
            borderWidth={1}
            borderColor="$borderLight200"
        >
            <TouchableOpacity
                style={{ flexDirection: 'row', alignItems: 'center', flex: 1, gap: 12 }}
                onPress={() => toggleTodo.mutate(item)}
            >
                <Box
                    w="$6"
                    h="$6"
                    borderRadius="$full"
                    borderWidth={2}
                    borderColor={item.isCompleted ? Colors.primary : Colors.border.light}
                    bg={item.isCompleted ? Colors.primary : 'transparent'}
                    alignItems="center"
                    justifyContent="center"
                >
                    {item.isCompleted && <Ionicons name="checkmark" size={14} color={Colors.text.primary} />}
                </Box>
                <Text
                    fontSize="$md"
                    color={item.isCompleted ? '$textLight400' : '$textLight900'}
                    textDecorationLine={item.isCompleted ? 'line-through' : 'none'}
                    flex={1}
                >
                    {item.title}
                </Text>
            </TouchableOpacity>

            <TouchableOpacity onPress={() => deleteTodo.mutate(item.id)} style={{ padding: 4 }}>
                <Ionicons name="trash-outline" size={18} color={Colors.text.error} />
            </TouchableOpacity>
        </HStack>
    );

    return (
        <Actionsheet isOpen={isOpen} onClose={onClose} zIndex={999}>
            <ActionsheetBackdrop />
            <ActionsheetContent zIndex={999} bg={Colors.background}>
                <ActionsheetDragIndicatorWrapper>
                    <ActionsheetDragIndicator />
                </ActionsheetDragIndicatorWrapper>

                <KeyboardAvoidingView
                    behavior={Platform.OS === "ios" ? "padding" : "height"}
                    style={{ width: '100%', height: 600 }}
                    keyboardVerticalOffset={Platform.OS === "ios" ? 180 : 0}
                >
                    <TouchableWithoutFeedback onPress={Keyboard.dismiss}>
                        <VStack space="md" w="$full" h="$full" p="$5" pb="$10" flex={1} overflow="hidden">

                            <Animated.View style={headerStyle}>
                                <VStack space="xs" mb="$4">
                                    <Text size="2xl" bold color="$textLight900">Planejamento</Text>
                                    <Text size="sm" color="$textLight500">
                                        Complete os itens para organizar sua viagem.
                                    </Text>
                                </VStack>

                                <HStack alignItems="center" space="sm" mb="$4">
                                    <Text bold size="lg">{Math.round(progress)}%</Text>
                                    <Box flex={1}>
                                        <Progress value={progress} size="md" h="$2" bg="white">
                                            <ProgressFilledTrack bg={Colors.primary} />
                                        </Progress>
                                    </Box>
                                </HStack>
                            </Animated.View>

                            <Box flex={1}>
                                {isLoading ? (
                                    <ActivityIndicator size="small" />
                                ) : (
                                    <AnimatedFlatList
                                        data={todos}
                                        keyExtractor={(item: any) => item.id}
                                        renderItem={renderItem}
                                        contentContainerStyle={{ paddingBottom: 20, paddingTop: HEADER_HEIGHT }}
                                        showsVerticalScrollIndicator={false}
                                        onScroll={scrollHandler}
                                        scrollEventThrottle={16}
                                        ListEmptyComponent={
                                            <Box py="$10" alignItems="center">
                                                <Text color="$textLight400">Nenhum item adicionado ainda.</Text>
                                            </Box>
                                        }
                                    />
                                )}
                            </Box>

                            <Box
                                mt="auto"
                                pt="$2"
                                pb="$5"
                            >
                                <HStack space="sm">
                                    <Input
                                        flex={1}
                                        variant="outline"
                                        size="md"
                                        bg="$white"
                                        borderRadius="$full"
                                        borderColor="$borderLight200"
                                    >
                                        <InputField
                                            placeholder="Adicionar novo item..."
                                            placeholderTextColor={Colors.text.secondary}
                                            value={newTodoTitle}
                                            onChangeText={setNewTodoTitle}
                                            onSubmitEditing={handleAdd}
                                        />
                                    </Input>
                                    <Pressable
                                        w="$10"
                                        h="$10"
                                        bg={Colors.primary}
                                        borderRadius="$full"
                                        alignItems="center"
                                        justifyContent="center"
                                        onPress={handleAdd}
                                        opacity={!newTodoTitle.trim() ? 0.5 : 1}
                                        disabled={!newTodoTitle.trim() || createTodo.isPending}
                                    >
                                        {createTodo.isPending ? (
                                            <ActivityIndicator color={Colors.text.primary} size="small" />
                                        ) : (
                                            <Ionicons name="arrow-up" size={20} color={Colors.text.primary} />
                                        )}
                                    </Pressable>
                                </HStack>
                            </Box>
                        </VStack>
                    </TouchableWithoutFeedback>
                </KeyboardAvoidingView>
            </ActionsheetContent>
        </Actionsheet>
    );
}
