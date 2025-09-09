import 'react-native-gesture-handler/jestSetup';

jest.mock('react-native-reanimated', () => {
  const Reanimated = require('react-native-reanimated/mock');
  Reanimated.default.call = () => {};
  return Reanimated;
});

jest.mock('react-native/Libraries/Animated/src/NativeAnimatedHelper');

jest.mock('react-native-vector-icons/MaterialIcons', () => 'Icon');

jest.mock('react-native-keychain', () => ({
  setInternetCredentials: jest.fn(() => Promise.resolve()),
  getInternetCredentials: jest.fn(() => Promise.resolve({password: 'test'})),
  ACCESS_CONTROL: {
    BIOMETRY_CURRENT_SET_OR_DEVICE_PASSCODE: 'BiometryCurrentSetOrDevicePasscode',
  },
  STORAGE_TYPE: {
    AES: 'AES',
  },
}));

jest.mock('react-native-fs', () => ({
  DocumentDirectoryPath: '/mock/documents',
  CachesDirectoryPath: '/mock/cache',
  ExternalDirectoryPath: '/mock/external',
  getFSInfo: jest.fn(() => Promise.resolve({totalSpace: 1000000, freeSpace: 500000})),
  readDir: jest.fn(() => Promise.resolve([])),
  stat: jest.fn(() => Promise.resolve({isDirectory: () => false, isFile: () => true, size: 1000})),
  exists: jest.fn(() => Promise.resolve(true)),
  unlink: jest.fn(() => Promise.resolve()),
  appendFile: jest.fn(() => Promise.resolve()),
  moveFile: jest.fn(() => Promise.resolve()),
}));

jest.mock('react-native-device-info', () => ({
  getBrand: jest.fn(() => Promise.resolve('TestBrand')),
  getModel: jest.fn(() => Promise.resolve('TestModel')),
  getSystemName: jest.fn(() => Promise.resolve('Android')),
  getSystemVersion: jest.fn(() => Promise.resolve('11')),
  getUniqueId: jest.fn(() => Promise.resolve('test-device-id')),
}));

jest.mock('@react-native-async-storage/async-storage', () => ({
  setItem: jest.fn(() => Promise.resolve()),
  getItem: jest.fn(() => Promise.resolve(null)),
  removeItem: jest.fn(() => Promise.resolve()),
}));
