import React, {createContext, useContext, useState, useEffect, ReactNode} from 'react';
import AsyncStorage from '@react-native-async-storage/async-storage';
import * as Keychain from 'react-native-keychain';
import CryptoJS from 'react-native-crypto-js';

interface AuthContextType {
  isAuthenticated: boolean;
  login: (pin: string) => Promise<boolean>;
  logout: () => Promise<void>;
  setupPin: (pin: string) => Promise<void>;
  hasPinSetup: boolean;
  isLoading: boolean;
  verifyIdentity: () => Promise<boolean>;
}

const AuthContext = createContext<AuthContextType | undefined>(undefined);

interface AuthProviderProps {
  children: ReactNode;
}

const PIN_STORAGE_KEY = 'secure_pin_hash';
const SESSION_STORAGE_KEY = 'auth_session';
const SETUP_COMPLETE_KEY = 'pin_setup_complete';

export const AuthProvider: React.FC<AuthProviderProps> = ({children}) => {
  const [isAuthenticated, setIsAuthenticated] = useState(false);
  const [hasPinSetup, setHasPinSetup] = useState(false);
  const [isLoading, setIsLoading] = useState(true);

  useEffect(() => {
    initializeAuth();
  }, []);

  const initializeAuth = async () => {
    try {
      // Check if PIN is set up
      const setupComplete = await AsyncStorage.getItem(SETUP_COMPLETE_KEY);
      setHasPinSetup(!!setupComplete);

      // Check for existing session
      if (setupComplete) {
        const session = await AsyncStorage.getItem(SESSION_STORAGE_KEY);
        if (session) {
          const sessionData = JSON.parse(session);
          const now = Date.now();
          // Session expires after 30 minutes
          if (now - sessionData.timestamp < 30 * 60 * 1000) {
            setIsAuthenticated(true);
          } else {
            await AsyncStorage.removeItem(SESSION_STORAGE_KEY);
          }
        }
      }
    } catch (error) {
      console.error('Error initializing auth:', error);
    } finally {
      setIsLoading(false);
    }
  };

  const hashPin = (pin: string): string => {
    // Use multiple rounds of hashing for security
    let hashed = pin;
    for (let i = 0; i < 1000; i++) {
      hashed = CryptoJS.SHA256(hashed + 'CleanSlate_Salt_2024').toString();
    }
    return hashed;
  };

  const setupPin = async (pin: string): Promise<void> => {
    try {
      if (pin.length < 4) {
        throw new Error('PIN must be at least 4 digits');
      }

      const hashedPin = hashPin(pin);
      
      // Store hashed PIN securely using Keychain
      await Keychain.setInternetCredentials(
        PIN_STORAGE_KEY,
        'user',
        hashedPin,
        {
          accessControl: Keychain.ACCESS_CONTROL.BIOMETRY_CURRENT_SET_OR_DEVICE_PASSCODE,
          authenticatePrompt: 'Authenticate to access CleanSlate',
          service: 'CleanSlate_Auth',
          storage: Keychain.STORAGE_TYPE.AES,
        }
      );

      await AsyncStorage.setItem(SETUP_COMPLETE_KEY, 'true');
      setHasPinSetup(true);
    } catch (error) {
      console.error('Error setting up PIN:', error);
      throw error;
    }
  };

  const login = async (pin: string): Promise<boolean> => {
    try {
      if (!hasPinSetup) {
        throw new Error('PIN not set up');
      }

      // Retrieve stored PIN hash
      const credentials = await Keychain.getInternetCredentials(PIN_STORAGE_KEY);
      if (!credentials || credentials === false) {
        throw new Error('Stored credentials not found');
      }

      const storedHash = credentials.password;
      const enteredHash = hashPin(pin);

      if (storedHash === enteredHash) {
        // Create session
        const session = {
          timestamp: Date.now(),
          authenticated: true,
        };
        await AsyncStorage.setItem(SESSION_STORAGE_KEY, JSON.stringify(session));
        setIsAuthenticated(true);
        return true;
      } else {
        return false;
      }
    } catch (error) {
      console.error('Error logging in:', error);
      return false;
    }
  };

  const logout = async (): Promise<void> => {
    try {
      await AsyncStorage.removeItem(SESSION_STORAGE_KEY);
      setIsAuthenticated(false);
    } catch (error) {
      console.error('Error logging out:', error);
    }
  };

  const verifyIdentity = async (): Promise<boolean> => {
    try {
      if (!hasPinSetup) {
        return false;
      }

      // Use biometric authentication if available
      const credentials = await Keychain.getInternetCredentials(PIN_STORAGE_KEY);
      return credentials !== false;
    } catch (error) {
      console.error('Error verifying identity:', error);
      return false;
    }
  };

  const value: AuthContextType = {
    isAuthenticated,
    login,
    logout,
    setupPin,
    hasPinSetup,
    isLoading,
    verifyIdentity,
  };

  return <AuthContext.Provider value={value}>{children}</AuthContext.Provider>;
};

export const useAuth = (): AuthContextType => {
  const context = useContext(AuthContext);
  if (context === undefined) {
    throw new Error('useAuth must be used within an AuthProvider');
  }
  return context;
};
