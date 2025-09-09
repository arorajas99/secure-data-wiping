import RNFS from 'react-native-fs';
import DeviceInfo from 'react-native-device-info';
import {PermissionsAndroid, Platform} from 'react-native';

export interface StorageDevice {
  id: string;
  name: string;
  path: string;
  type: 'internal' | 'external' | 'sdcard';
  totalSpace: number;
  freeSpace: number;
  isRemovable: boolean;
  isAccessible: boolean;
}

export class DeviceScanService {
  private static instance: DeviceScanService;

  static getInstance(): DeviceScanService {
    if (!DeviceScanService.instance) {
      DeviceScanService.instance = new DeviceScanService();
    }
    return DeviceScanService.instance;
  }

  async requestStoragePermissions(): Promise<boolean> {
    if (Platform.OS === 'android') {
      try {
        const granted = await PermissionsAndroid.requestMultiple([
          PermissionsAndroid.PERMISSIONS.READ_EXTERNAL_STORAGE,
          PermissionsAndroid.PERMISSIONS.WRITE_EXTERNAL_STORAGE,
          PermissionsAndroid.PERMISSIONS.MANAGE_EXTERNAL_STORAGE,
        ]);

        return Object.values(granted).every(
          permission => permission === PermissionsAndroid.RESULTS.GRANTED,
        );
      } catch (err) {
        console.error('Permission request failed:', err);
        return false;
      }
    }
    return true; // iOS handles permissions differently
  }

  async scanForStorageDevices(): Promise<StorageDevice[]> {
    const devices: StorageDevice[] = [];

    try {
      // Check permissions first
      const hasPermissions = await this.requestStoragePermissions();
      if (!hasPermissions) {
        throw new Error('Storage permissions not granted');
      }

      // Internal storage
      const internalStats = await RNFS.getFSInfo();
      devices.push({
        id: 'internal',
        name: 'Internal Storage',
        path: RNFS.DocumentDirectoryPath,
        type: 'internal',
        totalSpace: internalStats.totalSpace,
        freeSpace: internalStats.freeSpace,
        isRemovable: false,
        isAccessible: true,
      });

      // External storage (Android)
      if (Platform.OS === 'android') {
        try {
          const externalPath = RNFS.ExternalDirectoryPath;
          if (externalPath) {
            const externalStats = await RNFS.getFSInfo();
            devices.push({
              id: 'external',
              name: 'External Storage',
              path: externalPath,
              type: 'external',
              totalSpace: externalStats.totalSpace,
              freeSpace: externalStats.freeSpace,
              isRemovable: false,
              isAccessible: true,
            });
          }
        } catch (error) {
          console.log('External storage not available:', error);
        }

        // SD Card detection
        await this.detectSDCard(devices);
      }

      return devices;
    } catch (error) {
      console.error('Error scanning storage devices:', error);
      throw error;
    }
  }

  private async detectSDCard(devices: StorageDevice[]): Promise<void> {
    const possibleSDPaths = [
      '/storage/sdcard1',
      '/storage/extSdCard',
      '/storage/external_SD',
      '/mnt/external_sd',
      '/mnt/sdcard/external_sd',
    ];

    for (const path of possibleSDPaths) {
      try {
        const exists = await RNFS.exists(path);
        if (exists) {
          const stat = await RNFS.stat(path);
          if (stat.isDirectory()) {
            try {
              const contents = await RNFS.readDir(path);
              devices.push({
                id: `sdcard_${path.replace(/[^a-zA-Z0-9]/g, '_')}`,
                name: 'SD Card',
                path,
                type: 'sdcard',
                totalSpace: 0, // Will be updated if accessible
                freeSpace: 0,
                isRemovable: true,
                isAccessible: true,
              });
            } catch (error) {
              // SD card exists but not accessible
              devices.push({
                id: `sdcard_${path.replace(/[^a-zA-Z0-9]/g, '_')}`,
                name: 'SD Card (Limited Access)',
                path,
                type: 'sdcard',
                totalSpace: 0,
                freeSpace: 0,
                isRemovable: true,
                isAccessible: false,
              });
            }
          }
        }
      } catch (error) {
        // Path doesn't exist or is not accessible
        continue;
      }
    }
  }

  async getDeviceInfo(): Promise<{
    brand: string;
    model: string;
    systemName: string;
    systemVersion: string;
    deviceId: string;
  }> {
    const [brand, model, systemName, systemVersion, deviceId] = await Promise.all([
      DeviceInfo.getBrand(),
      DeviceInfo.getModel(),
      DeviceInfo.getSystemName(),
      DeviceInfo.getSystemVersion(),
      DeviceInfo.getUniqueId(),
    ]);

    return {
      brand,
      model,
      systemName,
      systemVersion,
      deviceId,
    };
  }

  formatBytes(bytes: number): string {
    if (bytes === 0) return '0 Bytes';

    const k = 1024;
    const sizes = ['Bytes', 'KB', 'MB', 'GB', 'TB'];
    const i = Math.floor(Math.log(bytes) / Math.log(k));

    return parseFloat((bytes / Math.pow(k, i)).toFixed(2)) + ' ' + sizes[i];
  }
}
