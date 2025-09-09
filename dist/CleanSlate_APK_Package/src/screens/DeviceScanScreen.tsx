import React, {useState, useEffect} from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  FlatList,
  ActivityIndicator,
  Alert,
  RefreshControl,
} from 'react-native';
import Icon from 'react-native-vector-icons/MaterialIcons';
import {DeviceScanService, StorageDevice} from '../services/DeviceScanService';

interface DeviceScanScreenProps {
  navigation: any;
}

const DeviceScanScreen: React.FC<DeviceScanScreenProps> = ({navigation}) => {
  const [devices, setDevices] = useState<StorageDevice[]>([]);
  const [loading, setLoading] = useState(true);
  const [refreshing, setRefreshing] = useState(false);
  const deviceScanService = DeviceScanService.getInstance();

  useEffect(() => {
    scanDevices();
  }, []);

  const scanDevices = async () => {
    try {
      setLoading(true);
      const discoveredDevices = await deviceScanService.scanForStorageDevices();
      setDevices(discoveredDevices);
    } catch (error) {
      Alert.alert(
        'Scan Failed',
        error.message || 'Unable to scan for storage devices. Please check permissions.',
        [
          {text: 'Retry', onPress: scanDevices},
          {text: 'Cancel', onPress: () => navigation.goBack()},
        ]
      );
    } finally {
      setLoading(false);
    }
  };

  const handleRefresh = async () => {
    setRefreshing(true);
    await scanDevices();
    setRefreshing(false);
  };

  const selectDevice = (device: StorageDevice) => {
    if (!device.isAccessible) {
      Alert.alert(
        'Device Not Accessible',
        'This storage device is not accessible or may have limited permissions.',
        [{text: 'OK'}]
      );
      return;
    }

    Alert.alert(
      'Select Storage Device',
      `Do you want to proceed with wiping data from ${device.name}?\n\nPath: ${device.path}\nSize: ${deviceScanService.formatBytes(device.totalSpace)}`,
      [
        {text: 'Cancel', style: 'cancel'},
        {
          text: 'Select',
          onPress: () => {
            navigation.navigate('FileSelection', {
              device,
              storageType: 'external',
            });
          },
        },
      ]
    );
  };

  const getDeviceIcon = (device: StorageDevice): string => {
    switch (device.type) {
      case 'sdcard':
        return 'sd-card';
      case 'external':
        return 'usb';
      case 'internal':
        return 'smartphone';
      default:
        return 'storage';
    }
  };

  const getDeviceColor = (device: StorageDevice): string => {
    if (!device.isAccessible) return '#9ca3af';
    switch (device.type) {
      case 'sdcard':
        return '#dc2626';
      case 'external':
        return '#059669';
      case 'internal':
        return '#3b82f6';
      default:
        return '#6b7280';
    }
  };

  const renderDeviceItem = ({item}: {item: StorageDevice}) => (
    <TouchableOpacity
      style={[
        styles.deviceCard,
        !item.isAccessible && styles.deviceCardDisabled,
      ]}
      onPress={() => selectDevice(item)}
      disabled={!item.isAccessible}>
      <View style={styles.deviceIcon}>
        <Icon
          name={getDeviceIcon(item)}
          size={40}
          color={getDeviceColor(item)}
        />
      </View>
      
      <View style={styles.deviceInfo}>
        <Text style={styles.deviceName}>{item.name}</Text>
        <Text style={styles.devicePath}>{item.path}</Text>
        
        <View style={styles.deviceStats}>
          <View style={styles.statItem}>
            <Icon name="storage" size={16} color="#6b7280" />
            <Text style={styles.statText}>
              {deviceScanService.formatBytes(item.totalSpace)}
            </Text>
          </View>
          
          <View style={styles.statItem}>
            <Icon name="available" size={16} color="#6b7280" />
            <Text style={styles.statText}>
              {deviceScanService.formatBytes(item.freeSpace)} free
            </Text>
          </View>
          
          {item.isRemovable && (
            <View style={styles.statItem}>
              <Icon name="eject" size={16} color="#f59e0b" />
              <Text style={styles.statText}>Removable</Text>
            </View>
          )}
        </View>
        
        {!item.isAccessible && (
          <View style={styles.accessibilityWarning}>
            <Icon name="warning" size={16} color="#ef4444" />
            <Text style={styles.warningText}>Limited Access</Text>
          </View>
        )}
      </View>
      
      <Icon
        name="chevron-right"
        size={24}
        color={item.isAccessible ? '#9ca3af' : '#d1d5db'}
      />
    </TouchableOpacity>
  );

  if (loading) {
    return (
      <View style={styles.loadingContainer}>
        <ActivityIndicator size="large" color="#dc2626" />
        <Text style={styles.loadingText}>Scanning for storage devices...</Text>
        <Text style={styles.loadingSubtext}>
          This may take a few moments
        </Text>
      </View>
    );
  }

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.title}>Storage Devices</Text>
        <Text style={styles.subtitle}>
          Select an external storage device to wipe
        </Text>
      </View>

      <View style={styles.scanInfo}>
        <Icon name="info" size={20} color="#3b82f6" />
        <Text style={styles.scanInfoText}>
          Found {devices.length} storage device{devices.length !== 1 ? 's' : ''}
        </Text>
      </View>

      <FlatList
        data={devices}
        keyExtractor={(item) => item.id}
        renderItem={renderDeviceItem}
        contentContainerStyle={styles.deviceList}
        refreshControl={
          <RefreshControl refreshing={refreshing} onRefresh={handleRefresh} />
        }
        ListEmptyComponent={
          <View style={styles.emptyState}>
            <Icon name="storage" size={64} color="#d1d5db" />
            <Text style={styles.emptyTitle}>No Devices Found</Text>
            <Text style={styles.emptyDescription}>
              No external storage devices were detected. Try:
              {'\n'}• Connecting a USB drive
              {'\n'}• Inserting an SD card
              {'\n'}• Checking device permissions
            </Text>
            <TouchableOpacity style={styles.refreshButton} onPress={handleRefresh}>
              <Icon name="refresh" size={20} color="#fff" />
              <Text style={styles.refreshButtonText}>Scan Again</Text>
            </TouchableOpacity>
          </View>
        }
      />

      <View style={styles.footer}>
        <TouchableOpacity
          style={styles.manualButton}
          onPress={() =>
            navigation.navigate('FileSelection', {
              device: null,
              storageType: 'manual',
            })
          }>
          <Icon name="folder" size={20} color="#6b7280" />
          <Text style={styles.manualButtonText}>Browse Manually</Text>
        </TouchableOpacity>
      </View>
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f8f9fa',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
    backgroundColor: '#f8f9fa',
  },
  loadingText: {
    marginTop: 20,
    fontSize: 18,
    fontWeight: '600',
    color: '#1f2937',
  },
  loadingSubtext: {
    marginTop: 8,
    fontSize: 14,
    color: '#6b7280',
  },
  header: {
    backgroundColor: '#fff',
    padding: 20,
    borderBottomWidth: 1,
    borderBottomColor: '#e5e7eb',
  },
  title: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#1f2937',
  },
  subtitle: {
    fontSize: 14,
    color: '#6b7280',
    marginTop: 4,
  },
  scanInfo: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#eff6ff',
    padding: 15,
    marginHorizontal: 20,
    marginTop: 15,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#bfdbfe',
  },
  scanInfoText: {
    fontSize: 14,
    color: '#1e40af',
    marginLeft: 8,
    fontWeight: '500',
  },
  deviceList: {
    padding: 20,
  },
  deviceCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#fff',
    padding: 20,
    borderRadius: 12,
    marginBottom: 15,
    elevation: 2,
    shadowColor: '#000',
    shadowOffset: {width: 0, height: 1},
    shadowOpacity: 0.1,
    shadowRadius: 3,
  },
  deviceCardDisabled: {
    backgroundColor: '#f9fafb',
    opacity: 0.7,
  },
  deviceIcon: {
    marginRight: 15,
  },
  deviceInfo: {
    flex: 1,
  },
  deviceName: {
    fontSize: 18,
    fontWeight: '600',
    color: '#1f2937',
    marginBottom: 4,
  },
  devicePath: {
    fontSize: 12,
    color: '#6b7280',
    marginBottom: 8,
    fontFamily: 'monospace',
  },
  deviceStats: {
    flexDirection: 'row',
    flexWrap: 'wrap',
    marginBottom: 8,
  },
  statItem: {
    flexDirection: 'row',
    alignItems: 'center',
    marginRight: 15,
    marginBottom: 4,
  },
  statText: {
    fontSize: 12,
    color: '#6b7280',
    marginLeft: 4,
  },
  accessibilityWarning: {
    flexDirection: 'row',
    alignItems: 'center',
  },
  warningText: {
    fontSize: 12,
    color: '#ef4444',
    marginLeft: 4,
    fontWeight: '500',
  },
  emptyState: {
    alignItems: 'center',
    padding: 40,
    backgroundColor: '#fff',
    borderRadius: 12,
    margin: 20,
  },
  emptyTitle: {
    fontSize: 20,
    fontWeight: 'bold',
    color: '#1f2937',
    marginTop: 20,
  },
  emptyDescription: {
    fontSize: 14,
    color: '#6b7280',
    textAlign: 'center',
    marginTop: 10,
    lineHeight: 20,
  },
  refreshButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#dc2626',
    paddingHorizontal: 20,
    paddingVertical: 10,
    borderRadius: 8,
    marginTop: 20,
  },
  refreshButtonText: {
    color: '#fff',
    fontSize: 14,
    fontWeight: '600',
    marginLeft: 8,
  },
  footer: {
    backgroundColor: '#fff',
    padding: 20,
    borderTopWidth: 1,
    borderTopColor: '#e5e7eb',
  },
  manualButton: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
    backgroundColor: '#f3f4f6',
    padding: 15,
    borderRadius: 8,
    borderWidth: 1,
    borderColor: '#d1d5db',
  },
  manualButtonText: {
    fontSize: 16,
    fontWeight: '500',
    color: '#6b7280',
    marginLeft: 8,
  },
});

export default DeviceScanScreen;
