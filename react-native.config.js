module.exports = {
  project: {
    ios: {},
    android: {
      sourceDir: './android',
      appName: 'app',
      packageName: 'com.cleanslate',
    },
  },
  dependencies: {
    // Explicitly configure native dependencies if needed
    '@react-native-async-storage/async-storage': {
      platforms: {
        android: {
          sourceDir: '../node_modules/@react-native-async-storage/async-storage/android',
          packageImportPath: 'import com.reactnativecommunity.asyncstorage.AsyncStoragePackage;',
        },
      },
    },
    'react-native-device-info': {
      platforms: {
        android: {
          sourceDir: '../node_modules/react-native-device-info/android',
          packageImportPath: 'import com.learnium.RNDeviceInfo.RNDeviceInfo;',
        },
      },
    },
    'react-native-fs': {
      platforms: {
        android: {
          sourceDir: '../node_modules/react-native-fs/android',
          packageImportPath: 'import com.rnfs.RNFSPackage;',
        },
      },
    },
    'react-native-gesture-handler': {
      platforms: {
        android: {
          sourceDir: '../node_modules/react-native-gesture-handler/android',
          packageImportPath: 'import com.swmansion.gesturehandler.RNGestureHandlerPackage;',
        },
      },
    },
    'react-native-keychain': {
      platforms: {
        android: {
          sourceDir: '../node_modules/react-native-keychain/android',
          packageImportPath: 'import com.oblador.keychain.KeychainPackage;',
        },
      },
    },
    'react-native-permissions': {
      platforms: {
        android: {
          sourceDir: '../node_modules/react-native-permissions/android',
          packageImportPath: 'import com.zoontek.rnpermissions.RNPermissionsPackage;',
        },
      },
    },
    'react-native-reanimated': {
      platforms: {
        android: {
          sourceDir: '../node_modules/react-native-reanimated/android',
          packageImportPath: 'import com.swmansion.reanimated.ReanimatedPackage;',
        },
      },
    },
    'react-native-safe-area-context': {
      platforms: {
        android: {
          sourceDir: '../node_modules/react-native-safe-area-context/android',
          packageImportPath: 'import com.th3rdwave.safeareacontext.SafeAreaContextPackage;',
        },
      },
    },
    'react-native-screens': {
      platforms: {
        android: {
          sourceDir: '../node_modules/react-native-screens/android',
          packageImportPath: 'import com.swmansion.rnscreens.RNScreensPackage;',
        },
      },
    },
    'react-native-vector-icons': {
      platforms: {
        android: {
          sourceDir: '../node_modules/react-native-vector-icons/android',
          packageImportPath: 'import com.oblador.vectoricons.VectorIconsPackage;',
        },
      },
    },
  },
};
