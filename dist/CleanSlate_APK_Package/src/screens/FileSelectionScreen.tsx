import React, {useState, useEffect} from 'react';
import {
  View,
  Text,
  StyleSheet,
  TouchableOpacity,
  FlatList,
  ActivityIndicator,
  Alert,
  Modal,
} from 'react-native';
import Icon from 'react-native-vector-icons/MaterialIcons';
import {FileBrowserService, FileItem} from '../services/FileBrowserService';
import {StorageDevice} from '../services/DeviceScanService';
import WarningDisclaimer from '../components/WarningDisclaimer';

interface FileSelectionScreenProps {
  navigation: any;
  route: {
    params: {
      device?: StorageDevice;
      storageType: 'internal' | 'external' | 'manual';
    };
  };
}

const FileSelectionScreen: React.FC<FileSelectionScreenProps> = ({
  navigation,
  route,
}) => {
  const {device, storageType} = route.params;
  const [currentPath, setCurrentPath] = useState<string>('');
  const [files, setFiles] = useState<FileItem[]>([]);
  const [loading, setLoading] = useState(true);
  const [selectedItems, setSelectedItems] = useState<Set<string>>(new Set());
  const [showMethods, setShowMethods] = useState(false);
  const [selectedMethod, setSelectedMethod] = useState<'dod' | 'nist' | 'gutmann' | 'random' | 'zero'>('dod');
  const [showWarning, setShowWarning] = useState(false);
  const [totalSize, setTotalSize] = useState(0);
  const [estimatedTime, setEstimatedTime] = useState(0);
  
  const fileBrowserService = FileBrowserService.getInstance();

  useEffect(() => {
    initializeBrowser();
  }, []);

  useEffect(() => {
    if (selectedItems.size > 0) {
      calculateSelectionStats();
    } else {
      setTotalSize(0);
      setEstimatedTime(0);
    }
  }, [selectedItems]);

  const initializeBrowser = async () => {
    try {
      let initialPath: string;
      
      if (device) {
        initialPath = device.path;
      } else {
        // Default to safe user directories
        const safePaths = fileBrowserService.getSafePaths();
        initialPath = safePaths[0] || '/sdcard';
      }
      
      setCurrentPath(initialPath);
      await loadDirectory(initialPath);
    } catch (error) {
      Alert.alert('Error', 'Failed to initialize file browser');
      navigation.goBack();
    }
  };

  const loadDirectory = async (path: string) => {
    try {
      setLoading(true);
      const items = await fileBrowserService.browseDirectory(path);
      setFiles(items);
    } catch (error) {
      Alert.alert('Error', `Cannot access directory: ${path}`);
    } finally {
      setLoading(false);
    }
  };

  const calculateSelectionStats = async () => {
    try {
      const selectedPaths = Array.from(selectedItems);
      const size = await fileBrowserService.calculateSelectedSize(selectedPaths);
      setTotalSize(size);
      
      // Estimate time based on method and size (rough calculation)
      const baseTimePerMB = selectedMethod === 'gutmann' ? 2 : selectedMethod === 'dod' ? 0.5 : 0.2;
      const sizeInMB = size / (1024 * 1024);
      setEstimatedTime(Math.max(sizeInMB * baseTimePerMB, 10)); // Minimum 10 seconds
    } catch (error) {
      console.error('Error calculating stats:', error);
    }
  };

  const navigateToParent = () => {
    const parentPath = currentPath.substring(0, currentPath.lastIndexOf('/'));
    if (parentPath && parentPath !== currentPath) {
      setCurrentPath(parentPath);
      loadDirectory(parentPath);
    }
  };

  const navigateToDirectory = (item: FileItem) => {
    if (item.isDirectory) {
      setCurrentPath(item.path);
      loadDirectory(item.path);
    }
  };

  const toggleSelection = (item: FileItem) => {
    if (item.isProtected) {
      Alert.alert(
        'Protected File',
        'This file or directory is protected and cannot be selected for wiping.',
        [{text: 'OK'}]
      );
      return;
    }

    const newSelection = new Set(selectedItems);
    if (newSelection.has(item.path)) {
      newSelection.delete(item.path);
    } else {
      newSelection.add(item.path);
    }
    setSelectedItems(newSelection);
  };

  const selectAllFiles = () => {
    const selectableFiles = files.filter(file => !file.isProtected);
    const allPaths = new Set(selectableFiles.map(file => file.path));
    setSelectedItems(allPaths);
  };

  const clearSelection = () => {
    setSelectedItems(new Set());
  };

  const proceedWithWiping = () => {
    if (selectedItems.size === 0) {
      Alert.alert('No Selection', 'Please select files or folders to wipe.');
      return;
    }

    setShowWarning(true);
  };

  const startWiping = () => {
    setShowWarning(false);
    navigation.navigate('Wiping', {
      selectedPaths: Array.from(selectedItems),
      wipingMethod: selectedMethod,
      totalSize,
      estimatedTime,
    });
  };

  const getFileIcon = (item: FileItem): string => {
    if (item.isDirectory) return 'folder';
    if (item.isProtected) return 'lock';
    
    const fileType = fileBrowserService.getFileType(item.name);
    switch (fileType) {
      case 'image': return 'image';
      case 'video': return 'movie';
      case 'audio': return 'audiotrack';
      case 'document': return 'description';
      case 'archive': return 'archive';
      default: return 'insert-drive-file';
    }
  };

  const getFileColor = (item: FileItem): string => {
    if (item.isProtected) return '#ef4444';
    if (item.isDirectory) return '#3b82f6';
    if (selectedItems.has(item.path)) return '#059669';
    return '#6b7280';
  };

  const renderFileItem = ({item}: {item: FileItem}) => (
    <TouchableOpacity
      style={[
        styles.fileItem,
        selectedItems.has(item.path) && styles.fileItemSelected,
        item.isProtected && styles.fileItemProtected,
      ]}
      onPress={() => item.isDirectory ? navigateToDirectory(item) : toggleSelection(item)}
      onLongPress={() => !item.isDirectory && toggleSelection(item)}>
      
      <TouchableOpacity
        style={styles.fileIcon}
        onPress={() => toggleSelection(item)}
        disabled={item.isProtected}>
        <Icon
          name={getFileIcon(item)}
          size={24}
          color={getFileColor(item)}
        />
      </TouchableOpacity>
      
      <View style={styles.fileInfo}>
        <Text style={[
          styles.fileName,
          item.isProtected && styles.fileNameProtected,
        ]}>
          {item.name}
        </Text>
        
        <View style={styles.fileDetails}>
          <Text style={styles.fileSize}>
            {item.isDirectory ? 'Folder' : fileBrowserService.formatFileSize(item.size)}
          </Text>
          
          {item.isProtected && (
            <View style={styles.protectedBadge}>
              <Icon name="lock" size={12} color="#ef4444" />
              <Text style={styles.protectedText}>Protected</Text>
            </View>
          )}
        </View>
      </View>
      
      {selectedItems.has(item.path) && (
        <Icon name="check-circle" size={20} color="#059669" />
      )}
      
      {item.isDirectory && (
        <Icon name="chevron-right" size={20} color="#9ca3af" />
      )}
    </TouchableOpacity>
  );

  const wipingMethods = [
    {id: 'dod', name: 'DoD 5220.22-M', description: '3-pass military standard', passes: 3},
    {id: 'nist', name: 'NIST 800-88', description: 'Single secure random pass', passes: 1},
    {id: 'gutmann', name: 'Gutmann Method', description: '35-pass maximum security', passes: 35},
    {id: 'random', name: 'Random Overwrite', description: '7-pass random data', passes: 7},
    {id: 'zero', name: 'Zero Fill', description: 'Single pass with zeros', passes: 1},
  ];

  return (
    <View style={styles.container}>
      {/* Header */}
      <View style={styles.header}>
        <View style={styles.breadcrumb}>
          <TouchableOpacity onPress={navigateToParent} disabled={!currentPath.includes('/')}>
            <Icon name="arrow-back" size={24} color="#6b7280" />
          </TouchableOpacity>
          <Text style={styles.currentPath} numberOfLines={1}>
            {currentPath}
          </Text>
        </View>
        
        <Text style={styles.selectionCount}>
          {selectedItems.size} selected ({fileBrowserService.formatFileSize(totalSize)})
        </Text>
      </View>

      {/* File List */}
      {loading ? (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#dc2626" />
          <Text style={styles.loadingText}>Loading files...</Text>
        </View>
      ) : (
        <FlatList
          data={files}
          keyExtractor={(item) => item.path}
          renderItem={renderFileItem}
          contentContainerStyle={styles.fileList}
        />
      )}

      {/* Selection Actions */}
      <View style={styles.selectionActions}>
        <TouchableOpacity style={styles.actionButton} onPress={selectAllFiles}>
          <Icon name="select-all" size={16} color="#6b7280" />
          <Text style={styles.actionButtonText}>Select All</Text>
        </TouchableOpacity>
        
        <TouchableOpacity style={styles.actionButton} onPress={clearSelection}>
          <Icon name="clear" size={16} color="#6b7280" />
          <Text style={styles.actionButtonText}>Clear</Text>
        </TouchableOpacity>
        
        <TouchableOpacity 
          style={[styles.actionButton, styles.methodButton]} 
          onPress={() => setShowMethods(true)}>
          <Icon name="settings" size={16} color="#3b82f6" />
          <Text style={[styles.actionButtonText, {color: '#3b82f6'}]}>
            {selectedMethod.toUpperCase()}
          </Text>
        </TouchableOpacity>
      </View>

      {/* Footer */}
      <View style={styles.footer}>
        <TouchableOpacity
          style={[
            styles.wipeButton,
            selectedItems.size === 0 && styles.wipeButtonDisabled,
          ]}
          onPress={proceedWithWiping}
          disabled={selectedItems.size === 0}>
          <Icon name="delete-forever" size={20} color="#fff" />
          <Text style={styles.wipeButtonText}>
            ALL DATA CLEAR ({selectedItems.size} items)
          </Text>
        </TouchableOpacity>
      </View>

      {/* Method Selection Modal */}
      <Modal visible={showMethods} animationType="slide" transparent>
        <View style={styles.modalOverlay}>
          <View style={styles.modalContent}>
            <Text style={styles.modalTitle}>Select Wiping Method</Text>
            
            {wipingMethods.map((method) => (
              <TouchableOpacity
                key={method.id}
                style={[
                  styles.methodItem,
                  selectedMethod === method.id && styles.methodItemSelected,
                ]}
                onPress={() => {
                  setSelectedMethod(method.id as any);
                  setShowMethods(false);
                }}>
                <View style={styles.methodInfo}>
                  <Text style={styles.methodName}>{method.name}</Text>
                  <Text style={styles.methodDescription}>{method.description}</Text>
                  <Text style={styles.methodPasses}>{method.passes} passes</Text>
                </View>
                {selectedMethod === method.id && (
                  <Icon name="check" size={24} color="#059669" />
                )}
              </TouchableOpacity>
            ))}
            
            <TouchableOpacity
              style={styles.modalCloseButton}
              onPress={() => setShowMethods(false)}>
              <Text style={styles.modalCloseText}>Close</Text>
            </TouchableOpacity>
          </View>
        </View>
      </Modal>

      {/* Warning Disclaimer */}
      <WarningDisclaimer
        visible={showWarning}
        onAccept={startWiping}
        onCancel={() => setShowWarning(false)}
        wipingMethod={selectedMethod}
        selectedItemsCount={selectedItems.size}
        estimatedTime={estimatedTime}
        totalSize={fileBrowserService.formatFileSize(totalSize)}
      />
    </View>
  );
};

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f8f9fa',
  },
  header: {
    backgroundColor: '#fff',
    padding: 15,
    borderBottomWidth: 1,
    borderBottomColor: '#e5e7eb',
  },
  breadcrumb: {
    flexDirection: 'row',
    alignItems: 'center',
    marginBottom: 8,
  },
  currentPath: {
    fontSize: 14,
    color: '#1f2937',
    marginLeft: 10,
    flex: 1,
    fontFamily: 'monospace',
  },
  selectionCount: {
    fontSize: 12,
    color: '#059669',
    fontWeight: '500',
  },
  loadingContainer: {
    flex: 1,
    justifyContent: 'center',
    alignItems: 'center',
  },
  loadingText: {
    marginTop: 10,
    fontSize: 14,
    color: '#6b7280',
  },
  fileList: {
    padding: 10,
  },
  fileItem: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#fff',
    padding: 12,
    marginBottom: 1,
    borderRadius: 8,
  },
  fileItemSelected: {
    backgroundColor: '#f0fdf4',
    borderWidth: 1,
    borderColor: '#059669',
  },
  fileItemProtected: {
    backgroundColor: '#fef2f2',
    opacity: 0.7,
  },
  fileIcon: {
    marginRight: 12,
    padding: 4,
  },
  fileInfo: {
    flex: 1,
  },
  fileName: {
    fontSize: 16,
    color: '#1f2937',
    fontWeight: '500',
  },
  fileNameProtected: {
    color: '#6b7280',
  },
  fileDetails: {
    flexDirection: 'row',
    alignItems: 'center',
    marginTop: 2,
  },
  fileSize: {
    fontSize: 12,
    color: '#6b7280',
  },
  protectedBadge: {
    flexDirection: 'row',
    alignItems: 'center',
    marginLeft: 8,
    backgroundColor: '#fee2e2',
    paddingHorizontal: 6,
    paddingVertical: 2,
    borderRadius: 4,
  },
  protectedText: {
    fontSize: 10,
    color: '#ef4444',
    marginLeft: 2,
    fontWeight: '500',
  },
  selectionActions: {
    flexDirection: 'row',
    backgroundColor: '#fff',
    padding: 10,
    borderTopWidth: 1,
    borderTopColor: '#e5e7eb',
  },
  actionButton: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#f3f4f6',
    paddingHorizontal: 12,
    paddingVertical: 8,
    borderRadius: 6,
    marginRight: 8,
  },
  methodButton: {
    backgroundColor: '#eff6ff',
  },
  actionButtonText: {
    fontSize: 12,
    color: '#6b7280',
    marginLeft: 4,
    fontWeight: '500',
  },
  footer: {
    backgroundColor: '#fff',
    padding: 15,
    borderTopWidth: 1,
    borderTopColor: '#e5e7eb',
  },
  wipeButton: {
    backgroundColor: '#dc2626',
    padding: 15,
    borderRadius: 8,
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'center',
  },
  wipeButtonDisabled: {
    backgroundColor: '#9ca3af',
  },
  wipeButtonText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: 'bold',
    marginLeft: 8,
  },
  modalOverlay: {
    flex: 1,
    backgroundColor: 'rgba(0,0,0,0.5)',
    justifyContent: 'center',
    padding: 20,
  },
  modalContent: {
    backgroundColor: '#fff',
    borderRadius: 12,
    padding: 20,
  },
  modalTitle: {
    fontSize: 18,
    fontWeight: 'bold',
    color: '#1f2937',
    marginBottom: 15,
    textAlign: 'center',
  },
  methodItem: {
    flexDirection: 'row',
    alignItems: 'center',
    padding: 15,
    borderWidth: 1,
    borderColor: '#e5e7eb',
    borderRadius: 8,
    marginBottom: 10,
  },
  methodItemSelected: {
    borderColor: '#059669',
    backgroundColor: '#f0fdf4',
  },
  methodInfo: {
    flex: 1,
  },
  methodName: {
    fontSize: 16,
    fontWeight: '600',
    color: '#1f2937',
  },
  methodDescription: {
    fontSize: 14,
    color: '#6b7280',
    marginTop: 2,
  },
  methodPasses: {
    fontSize: 12,
    color: '#059669',
    marginTop: 4,
    fontWeight: '500',
  },
  modalCloseButton: {
    backgroundColor: '#6b7280',
    padding: 12,
    borderRadius: 8,
    alignItems: 'center',
    marginTop: 10,
  },
  modalCloseText: {
    color: '#fff',
    fontSize: 16,
    fontWeight: '500',
  },
});

export default FileSelectionScreen;
