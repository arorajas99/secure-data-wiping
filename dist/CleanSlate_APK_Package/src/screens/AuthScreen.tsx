import React, {useState} from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  TextInput,
  Alert,
  ActivityIndicator,
  ScrollView,
} from 'react-native';
import Icon from 'react-native-vector-icons/MaterialIcons';
import {useAuth} from '../context/AuthContext';

interface AuthScreenProps {
  navigation: any;
}

const AuthScreen: React.FC<AuthScreenProps> = ({navigation}) => {
  const {login, setupPin, hasPinSetup, isLoading} = useAuth();
  const [pin, setPin] = useState('');
  const [confirmPin, setConfirmPin] = useState('');
  const [isSettingUp, setIsSettingUp] = useState(false);
  const [loading, setLoading] = useState(false);

  const handleLogin = async () => {
    if (pin.length < 4) {
      Alert.alert('Invalid PIN', 'PIN must be at least 4 digits');
      return;
    }

    setLoading(true);
    try {
      const success = await login(pin);
      if (success) {
        navigation.replace('Home');
      } else {
        Alert.alert('Authentication Failed', 'Incorrect PIN. Please try again.');
        setPin('');
      }
    } catch (error) {
      Alert.alert('Error', 'Authentication failed. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  const handleSetupPin = async () => {
    if (pin.length < 4) {
      Alert.alert('Invalid PIN', 'PIN must be at least 4 digits');
      return;
    }

    if (pin !== confirmPin) {
      Alert.alert('PIN Mismatch', 'PINs do not match. Please try again.');
      return;
    }

    setLoading(true);
    try {
      await setupPin(pin);
      Alert.alert(
        'Setup Complete',
        'Your secure PIN has been set. You can now access the application.',
        [
          {
            text: 'Continue',
            onPress: () => {
              setPin('');
              setConfirmPin('');
              setIsSettingUp(false);
              navigation.replace('Home');
            },
          },
        ]
      );
    } catch (error) {
      Alert.alert('Setup Failed', 'Failed to set up PIN. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  if (isLoading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#dc2626" />
        <Text style={styles.loadingText}>Initializing CleanSlate...</Text>
      </View>
    );
  }

  return (
    <ScrollView contentContainerStyle={styles.container}>
      <View style={styles.header}>
        <Icon name="security" size={80} color="#dc2626" />
        <Text style={styles.title}>CleanSlate</Text>
        <Text style={styles.subtitle}>Secure Data Wiping</Text>
      </View>

      <View style={styles.content}>
        {!hasPinSetup || isSettingUp ? (
          // PIN Setup Screen
          <View style={styles.setupContainer}>
            <Text style={styles.setupTitle}>Set Up Security PIN</Text>
            <Text style={styles.setupDescription}>
              Create a secure PIN to protect access to CleanSlate. This PIN will be required
              each time you use the application.
            </Text>

            <View style={styles.inputContainer}>
              <Icon name="lock" size={20} color="#6b7280" style={styles.inputIcon} />
              <TextInput
                style={styles.input}
                placeholder="Enter 4-digit PIN"
                value={pin}
                onChangeText={setPin}
                secureTextEntry
                keyboardType="numeric"
                maxLength={10}
              />
            </View>

            <View style={styles.inputContainer}>
              <Icon name="lock-outline" size={20} color="#6b7280" style={styles.inputIcon} />
              <TextInput
                style={styles.input}
                placeholder="Confirm PIN"
                value={confirmPin}
                onChangeText={setConfirmPin}
                secureTextEntry
                keyboardType="numeric"
                maxLength={10}
              />
            </View>

            <TouchableOpacity
              style={[styles.button, loading && styles.buttonDisabled]}
              onPress={handleSetupPin}
              disabled={loading}>
              {loading ? (
                <ActivityIndicator size="small" color="#fff" />
              ) : (
                <>
                  <Icon name="check" size={20} color="#fff" />
                  <Text style={styles.buttonText}>Set Up PIN</Text>
                </>
              )}
            </TouchableOpacity>
          </View>
        ) : (
          // Login Screen
          <View style={styles.loginContainer}>
            <Text style={styles.loginTitle}>Enter Security PIN</Text>
            <Text style={styles.loginDescription}>
              Enter your secure PIN to access CleanSlate data wiping features.
            </Text>

            <View style={styles.inputContainer}>
              <Icon name="lock" size={20} color="#6b7280" style={styles.inputIcon} />
              <TextInput
                style={styles.input}
                placeholder="Enter your PIN"
                value={pin}
                onChangeText={setPin}
                secureTextEntry
                keyboardType="numeric"
                maxLength={10}
                autoFocus
              />
            </View>

            <TouchableOpacity
              style={[styles.button, loading && styles.buttonDisabled]}
              onPress={handleLogin}
              disabled={loading}>
              {loading ? (
                <ActivityIndicator size="small" color="#fff" />
              ) : (
                <>
                  <Icon name="login" size={20} color="#fff" />
                  <Text style={styles.buttonText}>Login</Text>
                </>
              )}
            </TouchableOpacity>

            <TouchableOpacity
              style={styles.linkButton}
              onPress={() => setIsSettingUp(true)}>
              <Text style={styles.linkText}>Reset PIN</Text>
            </TouchableOpacity>
          </View>
        )}
      </View>

      <View style={styles.footer}>
        <View style={styles.securityNotice}>
          <Icon name="info" size={16} color="#6b7280" />
          <Text style={styles.securityText}>
            This application uses military-grade security for data wiping operations.
            Your PIN is encrypted and stored securely on your device.
          </Text>
        </View>
      </View>
    </ScrollView>
  );
};

const styles = StyleSheet.create({
  container: {
    flexGrow: 1,
    backgroundColor: '#f8f9fa',
    justifyContent: 'center',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#f8f9fa',
  },
  loadingText: {
    marginTop: 20,
    fontSize: 16,
    color: '#6b7280',
  },
  header: {
    alignItems: 'center',
    paddingVertical: 40,
  },
  title: {
    fontSize: 32,
    fontWeight: 'bold',
    color: '#dc2626',
    marginTop: 20,
  },
  subtitle: {
    fontSize: 16,
    color: '#6b7280',
    marginTop: 5,
  },
  content: {
    paddingHorizontal: 30,
  },
  setupContainer: {
    backgroundColor: '#fff',
    padding: 30,
    borderRadius: 12,
    elevation: 4,
    shadowColor: '#000',
    shadowOffset: {width: 0, height: 2},
    shadowOpacity: 0.1,
    shadowRadius: 8,
  },
  setupTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#1f2937',
    textAlign: 'center',
    marginBottom: 10,
  },
  setupDescription: {
    fontSize: 14,
    color: '#6b7280',
    textAlign: 'center',
    marginBottom: 30,
    lineHeight: 20,
  },
  loginContainer: {
    backgroundColor: '#fff',
    padding: 30,
    borderRadius: 12,
    elevation: 4,
    shadowColor: '#000',
    shadowOffset: {width: 0, height: 2},
    shadowOpacity: 0.1,
    shadowRadius: 8,
  },
  loginTitle: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#1f2937',
    textAlign: 'center',
    marginBottom: 10,
  },
  loginDescription: {
    fontSize: 14,
    color: '#6b7280',
    textAlign: 'center',
    marginBottom: 30,
    lineHeight: 20,
  },
  inputContainer: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#f3f4f6',
    borderRadius: 8,
    paddingHorizontal: 15,
    marginBottom: 20,
    borderWidth: 1,
    borderColor: '#e5e7eb',
  },
  inputIcon: {
    marginRight: 10,
  },
  input: {
    flex: 1,
    paddingVertical: 15,
    fontSize: 16,
    color: '#1f2937',
  },
  button: {
    backgroundColor: '#dc2626',
    paddingVertical: 15,
    borderRadius: 8,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    marginTop: 10,
  },
  buttonDisabled: {
    backgroundColor: '#9ca3af',
  },
  buttonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '600',
    marginLeft: 8,
  },
  linkButton: {
    marginTop: 20,
    paddingVertical: 10,
    alignItems: 'center',
  },
  linkText: {
    color: '#dc2626',
    fontSize: 14,
    fontWeight: '500',
  },
  footer: {
    paddingHorizontal: 30,
    paddingVertical: 20,
  },
  securityNotice: {
    flexDirection: 'row',
    alignItems: 'flex-start',
    backgroundColor: '#f0f9ff',
    padding: 15,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#e0f2fe',
  },
  securityText: {
    flex: 1,
    fontSize: 12,
    color: '#0369a1',
    marginLeft: 8,
    lineHeight: 16,
  },
});

export default AuthScreen;
