import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:path/path.dart' as path;
import '../services/storage_service.dart';
import '../services/wipe_service.dart';

class FileExplorerScreen extends StatefulWidget {
  final String initialPath;

  const FileExplorerScreen({
    Key? key,
    required this.initialPath,
  }) : super(key: key);

  @override
  State<FileExplorerScreen> createState() => _FileExplorerScreenState();
}

class _FileExplorerScreenState extends State<FileExplorerScreen> {
  late String currentPath;
  List<FileSystemEntity> items = [];
  bool isLoading = false;
  bool selectMode = false;

  @override
  void initState() {
    super.initState();
    currentPath = widget.initialPath;
    _loadDirectory();
  }

  Future<void> _loadDirectory() async {
    setState(() {
      isLoading = true;
    });

    try {
      final storageService = Provider.of<StorageService>(context, listen: false);
      final entities = await storageService.listDirectory(currentPath);
      setState(() {
        items = entities;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        isLoading = false;
      });
      _showErrorDialog('Error loading directory: $e');
    }
  }

  void _navigateToDirectory(String path) {
    setState(() {
      currentPath = path;
    });
    _loadDirectory();
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _showWipeConfirmation() async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    
    if (storageService.selectedFiles.isEmpty) {
      _showErrorDialog('No files selected');
      return;
    }

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            const SizedBox(width: 8),
            const Text('Confirm Wipe'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'ARE YOU ABSOLUTELY SURE?',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'You are about to permanently delete ${storageService.selectedFiles.length} item(s).\n\n'
              'This action CANNOT be undone!',
            ),
            const SizedBox(height: 12),
            const Text(
              'Type "DELETE" to confirm:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Type DELETE here',
                border: OutlineInputBorder(),
              ),
              onChanged: (value) {
                // Enable/disable confirm button based on input
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Wipe Data'),
          ),
        ],
      ),
    );

    if (result == true) {
      _performWipe();
    }
  }

  Future<void> _performWipe() async {
    final storageService = Provider.of<StorageService>(context, listen: false);
    final wipeService = Provider.of<WipeService>(context, listen: false);
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => WillPopScope(
        onWillPop: () async => false,
        child: AlertDialog(
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              const SizedBox(height: 16),
              const Text('Wiping files...'),
              const SizedBox(height: 8),
              Consumer<WipeService>(
                builder: (context, service, child) {
                  return Column(
                    children: [
                      LinearProgressIndicator(value: service.progress),
                      const SizedBox(height: 8),
                      Text(
                        service.currentFile,
                        style: Theme.of(context).textTheme.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final result = await wipeService.wipeFiles(storageService.selectedFiles);
      Navigator.pop(context); // Close progress dialog
      
      if (result.success) {
        // Generate certificate
        final certificateFile = await wipeService.generateCertificate(result);
        
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Wipe Complete'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 64,
                ),
                const SizedBox(height: 16),
                Text('Successfully wiped ${result.successfulFiles} of ${result.totalFiles} files'),
                const SizedBox(height: 8),
                Text('Certificate saved to:\n${certificateFile.path}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  storageService.clearSelection();
                  setState(() {
                    selectMode = false;
                  });
                  _loadDirectory();
                },
                child: const Text('OK'),
              ),
            ],
          ),
        );
      } else {
        _showErrorDialog('Wipe failed: ${result.error}');
      }
    } catch (e) {
      Navigator.pop(context); // Close progress dialog
      _showErrorDialog('Error during wipe: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final storageService = Provider.of<StorageService>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(path.basename(currentPath)),
        actions: [
          if (selectMode) ...[
            IconButton(
              icon: const Icon(Icons.select_all),
              onPressed: () {
                storageService.selectAll(items.where((e) => e is File).toList());
              },
            ),
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                storageService.clearSelection();
              },
            ),
          ],
          IconButton(
            icon: Icon(selectMode ? Icons.close : Icons.check_box),
            onPressed: () {
              setState(() {
                selectMode = !selectMode;
                if (!selectMode) {
                  storageService.clearSelection();
                }
              });
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Path breadcrumb
          Container(
            padding: const EdgeInsets.all(8.0),
            color: Theme.of(context).primaryColor.withOpacity(0.1),
            child: Row(
              children: [
                const Icon(Icons.folder, size: 16),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    currentPath,
                    style: Theme.of(context).textTheme.bodySmall,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          
          // File list
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : items.isEmpty
                    ? const Center(child: Text('Empty folder'))
                    : ListView.builder(
                        itemCount: items.length,
                        itemBuilder: (context, index) {
                          final item = items[index];
                          final isDirectory = item is Directory;
                          final isSelected = storageService.selectedFiles.contains(item);
                          
                          return ListTile(
                            leading: selectMode && !isDirectory
                                ? Checkbox(
                                    value: isSelected,
                                    onChanged: (_) {
                                      storageService.toggleFileSelection(item);
                                    },
                                  )
                                : Icon(
                                    isDirectory ? Icons.folder : Icons.insert_drive_file,
                                    color: isDirectory
                                        ? Colors.amber
                                        : Theme.of(context).primaryColor,
                                  ),
                            title: Text(path.basename(item.path)),
                            subtitle: FutureBuilder<int>(
                              future: storageService.getFileSize(item),
                              builder: (context, snapshot) {
                                if (snapshot.hasData && !isDirectory) {
                                  return Text(storageService.formatBytes(snapshot.data!));
                                }
                                return Text(isDirectory ? 'Folder' : 'File');
                              },
                            ),
                            onTap: () {
                              if (selectMode && !isDirectory) {
                                storageService.toggleFileSelection(item);
                              } else if (isDirectory) {
                                _navigateToDirectory(item.path);
                              }
                            },
                            selected: isSelected,
                          );
                        },
                      ),
          ),
          
          // Bottom action bar
          if (selectMode && storageService.selectedFiles.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${storageService.selectedFiles.length} selected',
                    style: const TextStyle(color: Colors.white),
                  ),
                  ElevatedButton.icon(
                    onPressed: _showWipeConfirmation,
                    icon: const Icon(Icons.delete_forever),
                    label: const Text('Wipe Selected'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
