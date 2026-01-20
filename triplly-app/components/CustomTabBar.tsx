import { View, Text, TouchableOpacity, StyleSheet } from 'react-native';
import { useSafeAreaInsets } from 'react-native-safe-area-context';
import { BottomTabBarProps } from '@react-navigation/bottom-tabs';
import { Colors } from '@/constants/colors';

export default function CustomTabBar({ state, descriptors, navigation }: BottomTabBarProps) {
    const insets = useSafeAreaInsets();

    return (
        <View style={[styles.container, { paddingBottom: insets.bottom }]}>
            <View style={styles.tabBar}>
                {state.routes.map((route, index) => {
                    const { options } = descriptors[route.key];
                    const label =
                        options.tabBarLabel !== undefined
                            ? options.tabBarLabel
                            : options.title !== undefined
                                ? options.title
                                : route.name;

                    const isFocused = state.index === index;

                    const onPress = () => {
                        const event = navigation.emit({
                            type: 'tabPress',
                            target: route.key,
                            canPreventDefault: true,
                        });

                        if (!isFocused && !event.defaultPrevented) {
                            // Simple layout animation for the indicator switch if desired, 
                            // though simple state switch is often cleaner for this style.
                            navigation.navigate(route.name);
                        }
                    };

                    const onLongPress = () => {
                        navigation.emit({
                            type: 'tabLongPress',
                            target: route.key,
                        });
                    };

                    return (
                        <TouchableOpacity
                            key={route.key}
                            accessibilityRole="button"
                            accessibilityState={isFocused ? { selected: true } : {}}
                            accessibilityLabel={options.tabBarAccessibilityLabel}
                            testID={(options as any).tabBarTestID}
                            onPress={onPress}
                            onLongPress={onLongPress}
                            style={styles.tabItem}
                        >
                            <View style={styles.labelContainer}>
                                <Text style={[
                                    styles.label,
                                    isFocused ? styles.labelFocused : styles.labelInactive
                                ]}>
                                    {label as string}
                                </Text>
                                {/* Active Indicator */}
                                {isFocused && <View style={styles.indicator} />}
                            </View>
                        </TouchableOpacity>
                    );
                })}
            </View>
        </View>
    );
}

const styles = StyleSheet.create({
    container: {
        backgroundColor: Colors.background, // Match app background or use white '#FFFFFF'
        borderTopWidth: 0,
        // elevation: 0, // Flat
    },
    tabBar: {
        flexDirection: 'row',
        height: 60,
        alignItems: 'center',
        justifyContent: 'center', // Center tabs or space-around
        gap: 40, // Spacing between tabs
    },
    tabItem: {
        alignItems: 'center',
        justifyContent: 'center',
        height: '100%',
        paddingHorizontal: 12, // Hit slop area
    },
    labelContainer: {
        alignItems: 'center',
        justifyContent: 'center',
        gap: 4,
    },
    label: {
        fontSize: 16,
        fontWeight: '500',
        letterSpacing: -0.3,
    },
    labelFocused: {
        color: Colors.text.primary, // Soft Black
        fontWeight: '600',
    },
    labelInactive: {
        color: Colors.text.secondary, // Warm Grey
    },
    indicator: {
        width: '100%',
        height: 2,
        backgroundColor: Colors.black,
        borderRadius: 1,
        marginTop: 2,
        position: 'absolute',
        bottom: -6, // Place below text
    },
});
