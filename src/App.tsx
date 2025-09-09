import React from 'react';
import {NavigationContainer} from '@react-navigation/native';
import {createStackNavigator} from '@react-navigation/stack';
import {StatusBar, StyleSheet} from 'react-native';
import {SafeAreaProvider} from 'react-native-safe-area-context';

import HomeScreen from './screens/HomeScreen';
import DeviceScanScreen from './screens/DeviceScanScreen';
import FileSelectionScreen from './screens/FileSelectionScreen';
import WipingScreen from './screens/WipingScreen';
import AuthScreen from './screens/AuthScreen';
import {AuthProvider} from './context/AuthContext';

const Stack = createStackNavigator();

const App: React.FC = () => {
  return (
    <SafeAreaProvider>
      <AuthProvider>
        <StatusBar barStyle="dark-content" backgroundColor="#f8f9fa" />
        <NavigationContainer>
          <Stack.Navigator
            initialRouteName="Auth"
            screenOptions={{
              headerStyle: {
                backgroundColor: '#dc2626',
              },
              headerTintColor: '#fff',
              headerTitleStyle: {
                fontWeight: 'bold',
              },
            }}>
            <Stack.Screen 
              name="Auth" 
              component={AuthScreen} 
              options={{headerShown: false}}
            />
            <Stack.Screen 
              name="Home" 
              component={HomeScreen} 
              options={{title: 'CleanSlate - Secure Data Wiping'}}
            />
            <Stack.Screen 
              name="DeviceScan" 
              component={DeviceScanScreen} 
              options={{title: 'Select Storage Device'}}
            />
            <Stack.Screen 
              name="FileSelection" 
              component={FileSelectionScreen} 
              options={{title: 'Select Files to Wipe'}}
            />
            <Stack.Screen 
              name="Wiping" 
              component={WipingScreen} 
              options={{
                title: 'Data Wiping in Progress',
                headerLeft: () => null,
                gestureEnabled: false,
              }}
            />
          </Stack.Navigator>
        </NavigationContainer>
      </AuthProvider>
    </SafeAreaProvider>
  );
};

export default App;
