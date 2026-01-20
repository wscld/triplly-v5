import { useState } from 'react';
import {
    View,
    Text,
    TextInput,
    TouchableOpacity,
    StyleSheet,
    KeyboardAvoidingView,
    Platform,
    Alert,
    ActivityIndicator,
} from 'react-native';
import { Link, router } from 'expo-router';
import { useAuth } from '@/lib/auth';
import { Colors } from '@/constants/colors';

export default function RegisterScreen() {
    const { register } = useAuth();
    const [name, setName] = useState('');
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [loading, setLoading] = useState(false);

    const handleRegister = async () => {
        if (!name || !email || !password) {
            Alert.alert('Error', 'Please fill in all fields');
            return;
        }

        if (password.length < 6) {
            Alert.alert('Error', 'Password must be at least 6 characters');
            return;
        }

        setLoading(true);
        try {
            await register(email, password, name);
            router.replace('/(app)/(tabs)');
        } catch (error) {
            Alert.alert('Error', error instanceof Error ? error.message : 'Registration failed');
        } finally {
            setLoading(false);
        }
    };

    return (
        <View style={styles.container}>
            <KeyboardAvoidingView
                behavior={Platform.OS === 'ios' ? 'padding' : 'height'}
                style={styles.keyboardView}
            >
                <View style={styles.content}>
                    <View style={styles.header}>
                        <Text style={styles.title}>Create Account</Text>
                        <Text style={styles.subtitle}>Start planning your next adventure</Text>
                    </View>

                    <View style={styles.formCard}>
                        <View style={styles.form}>
                            <TextInput
                                style={styles.input}
                                placeholder="Name"
                                placeholderTextColor="#999"
                                value={name}
                                onChangeText={setName}
                                autoCapitalize="words"
                            />
                            <TextInput
                                style={styles.input}
                                placeholder="Email"
                                placeholderTextColor="#999"
                                value={email}
                                onChangeText={setEmail}
                                keyboardType="email-address"
                                autoCapitalize="none"
                                autoCorrect={false}
                            />
                            <TextInput
                                style={styles.input}
                                placeholder="Password"
                                placeholderTextColor="#999"
                                value={password}
                                onChangeText={setPassword}
                                secureTextEntry
                            />

                            <TouchableOpacity
                                style={[styles.button, loading && styles.buttonDisabled]}
                                onPress={handleRegister}
                                disabled={loading}
                            >
                                {loading ? (
                                    <ActivityIndicator color="#fff" />
                                ) : (
                                    <Text style={styles.buttonText}>Create Account</Text>
                                )}
                            </TouchableOpacity>
                        </View>
                    </View>

                    <View style={styles.footer}>
                        <Text style={styles.footerText}>Already have an account? </Text>
                        <Link href="/(auth)/login" asChild>
                            <TouchableOpacity>
                                <Text style={styles.link}>Sign In</Text>
                            </TouchableOpacity>
                        </Link>
                    </View>
                </View>
            </KeyboardAvoidingView>
        </View>
    );
}

const styles = StyleSheet.create({
    container: {
        flex: 1,
        backgroundColor: Colors.background,
    },
    keyboardView: {
        flex: 1,
    },
    content: {
        flex: 1,
        justifyContent: 'center',
        paddingHorizontal: 24,
    },
    header: {
        alignItems: 'center',
        marginBottom: 48,
    },
    title: {
        fontSize: 32,
        fontWeight: '400',
        fontFamily: 'Serif',
        color: Colors.text.primary,
        marginBottom: 8,
        letterSpacing: -0.5,
    },
    subtitle: {
        fontSize: 17,
        color: '#636366',
        fontWeight: '500',
    },
    formCard: {
        borderRadius: 32,
        padding: 32,
        backgroundColor: '#fff',
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 8 },
        shadowOpacity: 0.05,
        shadowRadius: 24,
        elevation: 8,
    },
    form: {
        gap: 16,
    },
    input: {
        height: 56,
        borderWidth: 0,
        borderRadius: 16,
        paddingHorizontal: 20,
        fontSize: 17,
        backgroundColor: Colors.background,
        color: Colors.text.primary,
    },
    button: {
        height: 56,
        backgroundColor: Colors.primary,
        borderRadius: 100, // Pill
        alignItems: 'center',
        justifyContent: 'center',
        marginTop: 16,
        shadowColor: '#000', // Subtle shadow
        shadowOffset: { width: 0, height: 4 },
        shadowOpacity: 0.2,
        shadowRadius: 8,
        elevation: 4,
    },
    buttonDisabled: {
        opacity: 0.7,
    },
    buttonText: {
        color: Colors.text.primary,
        fontSize: 17,
        fontWeight: '600',
    },
    footer: {
        flexDirection: 'row',
        justifyContent: 'center',
        marginTop: 32,
    },
    footerText: {
        color: '#666',
        fontSize: 15,
    },
    link: {
        color: Colors.text.primary,
        fontSize: 15,
        fontWeight: '600',
        textDecorationLine: 'underline',
    },
});
