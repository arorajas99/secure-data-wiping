import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as path;
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:external_path/external_path.dart';

class StorageService extends ChangeNotifier {
  List<StorageDevice> _storageDevices = [];
  List<FileSystemEntity> _selectedFiles = [];
  String _currentPath = '/';
  
  List<StorageDevice> get storageDevices => _storageDevices;
  List<FileSystemEntity> get selectedFiles => _selectedFiles;
  String get currentPath => _currentPath;

  StorageService() {
    _initializeStorage();
  }

  Future<void> _initializeStorage() async {
    await scanForStorageDevices();
  }

  Future<bool> requestStoragePermissions() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      final androidInfo = await deviceInfo.androidInfo;
      
      if (androidInfo.version.sdkInt >= 30) {
        final status = await Permission.manageExternalStorage.request();
        return status.isGranted;
      } else {
        final status = await Permission.storage.request();
        return status.isGranted;
      }
    } catch (e) {
      debugPrint('Error requesting permissions: $e');
      return false;
    }
  }

  Future<void> scanForStorageDevices() async {
    try {
      _storageDevices.clear();
      
      // Internal storage
      final internalStorage = StorageDevice(
        name: 'Internal Storage',
        path: '/storage/emulated/0',
        type: StorageType.internal,
        totalSpace: 0,
        freeSpace: 0,
      );
      
      // Get storage info
      final directory = Directory(internalStorage.path);
      if (await directory.exists()) {
        _storageDevices.add(internalStorage);
      }
      
      // External storage (SD Card)
      try {
        final externalPaths = await ExternalPath.getExternalStorageDirectories();
        for (String extPath in externalPaths) {
          if (!extPath.contains('emulated')) {
            final externalStorage = StorageDevice(
              name: 'SD Card',
              path: extPath,
              type: StorageType.external,
              totalSpace: 0,
              freeSpace: 0,
            );
            _storageDevices.add(externalStorage);
          }
        }
      } catch (e) {
        debugPrint('Error scanning external storage: $e');
      }
      
      // USB storage
      final usbPaths = [
        '/storage/usb0',
        '/storage/usb1',
        '/storage/UsbDriveA',
        '/storage/UsbDriveB',
      ];
      
      for (String usbPath in usbPaths) {
        final usbDir = Directory(usbPath);
        if (await usbDir.exists()) {
          final usbStorage = StorageDevice(
            name: 'USB Storage',
            path: usbPath,
            type: StorageType.usb,
            totalSpace: 0,
            freeSpace: 0,
          );
          _storageDevices.add(usbStorage);
        }
      }
      
      notifyListeners();
    } catch (e) {
      debugPrint('Error scanning storage devices: $e');
    }
  }

  Future<List<FileSystemEntity>> listDirectory(String path) async {
    try {
      final directory = Directory(path);
      if (await directory.exists()) {
        _currentPath = path;
        final entities = await directory.list().toList();
        entities.sort((a, b) {
          // Directories first, then files
          if (a is Directory && b is File) return -1;
          if (a is File && b is Directory) return 1;
          // Then sort alphabetically
          return path.basename(a.path).compareTo(path.basename(b.path));
        });
        return entities;
      }
      return [];
    } catch (e) {
      debugPrint('Error listing directory: $e');
      return [];
    }
  }

  void selectFile(FileSystemEntity file) {
    if (!_selectedFiles.contains(file)) {
      _selectedFiles.add(file);
      notifyListeners();
    }
  }

  void deselectFile(FileSystemEntity file) {
    _selectedFiles.remove(file);
    notifyListeners();
  }

  void toggleFileSelection(FileSystemEntity file) {
    if (_selectedFiles.contains(file)) {
      deselectFile(file);
    } else {
      selectFile(file);
    }
  }

  void clearSelection() {
    _selectedFiles.clear();
    notifyListeners();
  }

  void selectAll(List<FileSystemEntity> files) {
    _selectedFiles = List.from(files);
    notifyListeners();
  }

  Future<int> getFileSize(FileSystemEntity entity) async {
    try {
      if (entity is File) {
        return await entity.length();
      } else if (entity is Directory) {
        return await _getDirectorySize(entity);
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }

  Future<int> _getDirectorySize(Directory dir) async {
    int totalSize = 0;
    try {
      await for (FileSystemEntity entity in dir.list(recursive: true)) {
        if (entity is File) {
          totalSize += await entity.length();
        }
      }
    } catch (e) {
      debugPrint('Error calculating directory size: $e');
    }
    return totalSize;
  }

  String formatBytes(int bytes) {
    if (bytes <= 0) return '0 B';
    const suffixes = ['B', 'KB', 'MB', 'GB', 'TB'];
    int i = 0;
    double size = bytes.toDouble();
    while (size > 1024 && i < suffixes.length - 1) {
      size /= 1024;
      i++;
    }
    return '${size.toStringAsFixed(2)} ${suffixes[i]}';
  }

  String getFileName(String filePath) {
    return path.basename(filePath);
  }

  String getFileExtension(String filePath) {
    return path.extension(filePath);
  }

  bool isDirectory(FileSystemEntity entity) {
    return entity is Directory;
  }

  bool isFile(FileSystemEntity entity) {
    return entity is File;
  }
}

class StorageDevice {
  final String name;
  final String path;
  final StorageType type;
  final int totalSpace;
  final int freeSpace;

  StorageDevice({
    required this.name,
    required this.path,
    required this.type,
    required this.totalSpace,
    required this.freeSpace,
  });

  double get usagePercentage {
    if (totalSpace == 0) return 0;
    return ((totalSpace - freeSpace) / totalSpace) * 100;
  }
}

enum StorageType {
  internal,
  external,
  usb,
}
