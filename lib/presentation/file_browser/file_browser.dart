import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/breadcrumb_widget.dart';
import './widgets/file_item_widget.dart';
import './widgets/file_type_filter_widget.dart';
import './widgets/search_bar_widget.dart';
import './widgets/selection_toolbar_widget.dart';

class FileBrowser extends StatefulWidget {
  const FileBrowser({super.key});

  @override
  State<FileBrowser> createState() => _FileBrowserState();
}

class _FileBrowserState extends State<FileBrowser> {
  final ScrollController _scrollController = ScrollController();

  // State variables
  String _searchQuery = '';
  String _selectedFilter = 'all';
  bool _isSearchCollapsed = false;
  bool _isMultiSelectMode = false;
  Set<String> _selectedItems = {};
  List<String> _currentPath = ['Internal Storage'];
  String _currentDevice = 'Samsung Galaxy S23';

  // Mock data
  List<Map<String, dynamic>> _allFiles = [];
  List<Map<String, dynamic>> _filteredFiles = [];

  @override
  void initState() {
    super.initState();
    _initializeMockData();
    _setupScrollListener();
    _applyFilters();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _initializeMockData() {
    _allFiles = [
      {
        'name': 'Documents',
        'type': 'folder',
        'itemCount': 24,
        'lastModified': 'Today',
        'path': '/storage/emulated/0/Documents',
      },
      {
        'name': 'Pictures',
        'type': 'folder',
        'itemCount': 156,
        'lastModified': 'Yesterday',
        'path': '/storage/emulated/0/Pictures',
      },
      {
        'name': 'Downloads',
        'type': 'folder',
        'itemCount': 43,
        'lastModified': '2 days ago',
        'path': '/storage/emulated/0/Downloads',
      },
      {
        'name': 'DCIM',
        'type': 'folder',
        'itemCount': 89,
        'lastModified': '3 days ago',
        'path': '/storage/emulated/0/DCIM',
      },
      {
        'name': 'Music',
        'type': 'folder',
        'itemCount': 67,
        'lastModified': '1 week ago',
        'path': '/storage/emulated/0/Music',
      },
      {
        'name': 'Videos',
        'type': 'folder',
        'itemCount': 12,
        'lastModified': '2 weeks ago',
        'path': '/storage/emulated/0/Videos',
      },
      {
        'name': 'WhatsApp',
        'type': 'folder',
        'itemCount': 234,
        'lastModified': 'Today',
        'path': '/storage/emulated/0/WhatsApp',
      },
      {
        'name': 'Android',
        'type': 'folder',
        'itemCount': 78,
        'lastModified': '1 month ago',
        'path': '/storage/emulated/0/Android',
      },
      {
        'name': 'presentation.pdf',
        'type': 'file',
        'size': '2.4 MB',
        'lastModified': 'Today 3:45 PM',
        'path': '/storage/emulated/0/presentation.pdf',
        'thumbnailUrl':
            'https://images.unsplash.com/photo-1568667256549-094345857637?w=400&h=400&fit=crop',
      },
      {
        'name': 'vacation_photo.jpg',
        'type': 'file',
        'size': '1.8 MB',
        'lastModified': 'Yesterday 2:30 PM',
        'path': '/storage/emulated/0/vacation_photo.jpg',
        'thumbnailUrl':
            'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&h=400&fit=crop',
      },
      {
        'name': 'budget_2024.xlsx',
        'type': 'file',
        'size': '456 KB',
        'lastModified': '2 days ago',
        'path': '/storage/emulated/0/budget_2024.xlsx',
      },
      {
        'name': 'meeting_recording.mp3',
        'type': 'file',
        'size': '12.3 MB',
        'lastModified': '3 days ago',
        'path': '/storage/emulated/0/meeting_recording.mp3',
      },
      {
        'name': 'app_backup.apk',
        'type': 'file',
        'size': '45.2 MB',
        'lastModified': '1 week ago',
        'path': '/storage/emulated/0/app_backup.apk',
      },
      {
        'name': 'family_video.mp4',
        'type': 'file',
        'size': '128.7 MB',
        'lastModified': '2 weeks ago',
        'path': '/storage/emulated/0/family_video.mp4',
        'thumbnailUrl':
            'https://images.unsplash.com/photo-1511895426328-dc8714191300?w=400&h=400&fit=crop',
      },
      {
        'name': 'notes.txt',
        'type': 'file',
        'size': '2.1 KB',
        'lastModified': '1 month ago',
        'path': '/storage/emulated/0/notes.txt',
      },
    ];
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.offset > 100 && !_isSearchCollapsed) {
        setState(() => _isSearchCollapsed = true);
      } else if (_scrollController.offset <= 100 && _isSearchCollapsed) {
        setState(() => _isSearchCollapsed = false);
      }
    });
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_allFiles);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((item) {
        final name = (item['name'] as String).toLowerCase();
        return name.contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Apply file type filter
    if (_selectedFilter != 'all') {
      filtered = filtered.where((item) {
        if (item['type'] == 'folder') return true;

        final fileName = item['name'] as String;
        final extension = fileName.split('.').last.toLowerCase();

        switch (_selectedFilter) {
          case 'documents':
            return ['pdf', 'doc', 'docx', 'txt', 'xls', 'xlsx', 'ppt', 'pptx']
                .contains(extension);
          case 'images':
            return ['jpg', 'jpeg', 'png', 'gif', 'bmp', 'webp']
                .contains(extension);
          case 'videos':
            return ['mp4', 'avi', 'mov', 'mkv', 'wmv', '3gp']
                .contains(extension);
          case 'audio':
            return ['mp3', 'wav', 'flac', 'aac', 'm4a', 'ogg']
                .contains(extension);
          case 'apps':
            return ['apk'].contains(extension);
          default:
            return true;
        }
      }).toList();
    }

    // Sort: folders first, then files
    filtered.sort((a, b) {
      if (a['type'] == 'folder' && b['type'] == 'file') return -1;
      if (a['type'] == 'file' && b['type'] == 'folder') return 1;
      return (a['name'] as String)
          .toLowerCase()
          .compareTo((b['name'] as String).toLowerCase());
    });

    setState(() => _filteredFiles = filtered);
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    _applyFilters();
  }

  void _onFilterChanged(String filter) {
    setState(() => _selectedFilter = filter);
    _applyFilters();
  }

  void _onItemTap(Map<String, dynamic> item) {
    if (_isMultiSelectMode) {
      _toggleItemSelection(item);
      return;
    }

    if (item['type'] == 'folder') {
      _navigateToFolder(item);
    } else {
      _previewFile(item);
    }
  }

  void _onItemLongPress(Map<String, dynamic> item) {
    HapticFeedback.mediumImpact();
    if (!_isMultiSelectMode) {
      setState(() {
        _isMultiSelectMode = true;
        _selectedItems.add(item['path'] as String);
      });
    } else {
      _toggleItemSelection(item);
    }
  }

  void _toggleItemSelection(Map<String, dynamic> item) {
    final path = item['path'] as String;
    setState(() {
      if (_selectedItems.contains(path)) {
        _selectedItems.remove(path);
        if (_selectedItems.isEmpty) {
          _isMultiSelectMode = false;
        }
      } else {
        _selectedItems.add(path);
      }
    });
  }

  void _navigateToFolder(Map<String, dynamic> folder) {
    setState(() {
      _currentPath.add(folder['name'] as String);
    });

    // Simulate loading folder contents
    _showToast('Loading ${folder['name']}...');

    // In a real app, you would load the actual folder contents here
    Future.delayed(const Duration(milliseconds: 500), () {
      // Mock different content for different folders
      _loadFolderContents(folder['name'] as String);
    });
  }

  void _loadFolderContents(String folderName) {
    List<Map<String, dynamic>> folderContents = [];

    switch (folderName) {
      case 'Documents':
        folderContents = [
          {
            'name': 'Work',
            'type': 'folder',
            'itemCount': 15,
            'lastModified': 'Today',
            'path': '/storage/emulated/0/Documents/Work',
          },
          {
            'name': 'Personal',
            'type': 'folder',
            'itemCount': 9,
            'lastModified': 'Yesterday',
            'path': '/storage/emulated/0/Documents/Personal',
          },
          {
            'name': 'resume.pdf',
            'type': 'file',
            'size': '1.2 MB',
            'lastModified': 'Today 10:30 AM',
            'path': '/storage/emulated/0/Documents/resume.pdf',
          },
          {
            'name': 'contract.docx',
            'type': 'file',
            'size': '890 KB',
            'lastModified': 'Yesterday 4:15 PM',
            'path': '/storage/emulated/0/Documents/contract.docx',
          },
        ];
        break;
      case 'Pictures':
        folderContents = [
          {
            'name': 'Camera',
            'type': 'folder',
            'itemCount': 89,
            'lastModified': 'Today',
            'path': '/storage/emulated/0/Pictures/Camera',
          },
          {
            'name': 'Screenshots',
            'type': 'folder',
            'itemCount': 67,
            'lastModified': 'Yesterday',
            'path': '/storage/emulated/0/Pictures/Screenshots',
          },
          {
            'name': 'sunset.jpg',
            'type': 'file',
            'size': '3.2 MB',
            'lastModified': 'Today 6:45 PM',
            'path': '/storage/emulated/0/Pictures/sunset.jpg',
            'thumbnailUrl':
                'https://images.unsplash.com/photo-1506905925346-21bda4d32df4?w=400&h=400&fit=crop',
          },
        ];
        break;
      default:
        folderContents = [
          {
            'name': 'Empty folder',
            'type': 'folder',
            'itemCount': 0,
            'lastModified': 'Never',
            'path': '/storage/emulated/0/$folderName/empty',
          },
        ];
    }

    setState(() {
      _allFiles = folderContents;
      _filteredFiles = folderContents;
    });
  }

  void _previewFile(Map<String, dynamic> file) {
    _showToast('Opening ${file['name']}...');
    // In a real app, you would open the file with appropriate viewer
  }

  void _onBreadcrumbTap(int index) {
    if (index < _currentPath.length - 1) {
      setState(() {
        _currentPath = _currentPath.sublist(0, index + 1);
      });

      if (index == 0) {
        // Back to root
        _initializeMockData();
        _applyFilters();
      } else {
        // Navigate to specific path level
        _loadFolderContents(_currentPath[index]);
      }
    }
  }

  void _onSelectAll() {
    setState(() {
      _selectedItems =
          _filteredFiles.map((item) => item['path'] as String).toSet();
    });
    HapticFeedback.lightImpact();
  }

  void _onClearSelection() {
    setState(() {
      _selectedItems.clear();
      _isMultiSelectMode = false;
    });
    HapticFeedback.lightImpact();
  }

  void _onAddToWipeList() {
    final count = _selectedItems.length;
    _showToast('Added $count items to wipe list');
    _onClearSelection();
    HapticFeedback.mediumImpact();
  }

  void _onMarkAsSafe() {
    final count = _selectedItems.length;
    _showToast('Marked $count items as safe');
    _onClearSelection();
    HapticFeedback.lightImpact();
  }

  void _onAddToSafe(Map<String, dynamic> item) {
    _showToast('${item['name']} added to safe list');
    HapticFeedback.lightImpact();
  }

  void _onProperties(Map<String, dynamic> item) {
    _showItemProperties(item);
  }

  void _onShare(Map<String, dynamic> item) {
    _showToast('Sharing ${item['name']}...');
    HapticFeedback.lightImpact();
  }

  void _onDeletePreview(Map<String, dynamic> item) {
    _showDeletePreview(item);
  }

  void _showItemProperties(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Properties'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Name: ${item['name']}'),
            SizedBox(height: 1.h),
            Text('Type: ${item['type'] == 'folder' ? 'Folder' : 'File'}'),
            SizedBox(height: 1.h),
            if (item['size'] != null) ...[
              Text('Size: ${item['size']}'),
              SizedBox(height: 1.h),
            ],
            if (item['itemCount'] != null) ...[
              Text('Items: ${item['itemCount']}'),
              SizedBox(height: 1.h),
            ],
            Text('Modified: ${item['lastModified']}'),
            SizedBox(height: 1.h),
            Text('Path: ${item['path']}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDeletePreview(Map<String, dynamic> item) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Preview'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('This will permanently delete:'),
            SizedBox(height: 1.h),
            Text('• ${item['name']}'),
            if (item['type'] == 'folder') ...[
              SizedBox(height: 0.5.h),
              Text('• All ${item['itemCount']} items inside'),
            ],
            SizedBox(height: 2.h),
            Container(
              padding: EdgeInsets.all(2.w),
              decoration: BoxDecoration(
                color:
                    Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8.0),
              ),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: 'warning',
                    color: Theme.of(context).colorScheme.error,
                    size: 5.w,
                  ),
                  SizedBox(width: 2.w),
                  Expanded(
                    child: Text(
                      'This action cannot be undone!',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, '/confirmation-dialog');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: Text('Continue to Wipe'),
          ),
        ],
      ),
    );
  }

  Future<void> _onRefresh() async {
    _showToast('Rescanning directory...');

    // Simulate refresh delay
    await Future.delayed(const Duration(milliseconds: 1000));

    // Reload current directory
    if (_currentPath.length == 1) {
      _initializeMockData();
    } else {
      _loadFolderContents(_currentPath.last);
    }

    _applyFilters();
    _showToast('Directory refreshed');
  }

  void _showToast(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      backgroundColor: Colors.black87,
      textColor: Colors.white,
      fontSize: 14.0,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'File Browser',
              style: theme.textTheme.titleLarge?.copyWith(
                color: colorScheme.onPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
            Text(
              _currentDevice,
              style: theme.textTheme.bodySmall?.copyWith(
                color: colorScheme.onPrimary.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 2.0,
        leading: IconButton(
          onPressed: () {
            if (_currentPath.length > 1) {
              _onBreadcrumbTap(_currentPath.length - 2);
            } else {
              Navigator.pop(context);
            }
          },
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: colorScheme.onPrimary,
            size: 6.w,
          ),
          tooltip: _currentPath.length > 1 ? 'Back' : 'Close',
        ),
        actions: [
          if (_isMultiSelectMode) ...[
            IconButton(
              onPressed: _onClearSelection,
              icon: CustomIconWidget(
                iconName: 'close',
                color: colorScheme.onPrimary,
                size: 6.w,
              ),
              tooltip: 'Exit selection mode',
            ),
          ] else ...[
            IconButton(
              onPressed: () {
                setState(() => _isSearchCollapsed = !_isSearchCollapsed);
              },
              icon: CustomIconWidget(
                iconName: _isSearchCollapsed ? 'search' : 'search_off',
                color: colorScheme.onPrimary,
                size: 6.w,
              ),
              tooltip: _isSearchCollapsed ? 'Show search' : 'Hide search',
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                switch (value) {
                  case 'refresh':
                    _onRefresh();
                    break;
                  case 'show_hidden':
                    _showToast('Toggle hidden files');
                    break;
                  case 'sort':
                    _showToast('Sort options');
                    break;
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'refresh',
                        color: colorScheme.onSurface,
                        size: 5.w,
                      ),
                      SizedBox(width: 3.w),
                      Text('Refresh'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'show_hidden',
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'visibility',
                        color: colorScheme.onSurface,
                        size: 5.w,
                      ),
                      SizedBox(width: 3.w),
                      Text('Show hidden files'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'sort',
                  child: Row(
                    children: [
                      CustomIconWidget(
                        iconName: 'sort',
                        color: colorScheme.onSurface,
                        size: 5.w,
                      ),
                      SizedBox(width: 3.w),
                      Text('Sort by'),
                    ],
                  ),
                ),
              ],
              icon: CustomIconWidget(
                iconName: 'more_vert',
                color: colorScheme.onPrimary,
                size: 6.w,
              ),
            ),
          ],
        ],
      ),
      body: Column(
        children: [
          // Breadcrumb navigation
          BreadcrumbWidget(
            pathSegments: _currentPath,
            onSegmentTapped: _onBreadcrumbTap,
          ),

          // Search bar
          SearchBarWidget(
            searchQuery: _searchQuery,
            onSearchChanged: _onSearchChanged,
            onSearchSubmitted: () {
              FocusScope.of(context).unfocus();
            },
            isCollapsed: _isSearchCollapsed,
          ),

          // File type filters
          FileTypeFilterWidget(
            selectedFilter: _selectedFilter,
            onFilterChanged: _onFilterChanged,
            isVisible: !_isSearchCollapsed,
          ),

          // File list
          Expanded(
            child: RefreshIndicator(
              onRefresh: _onRefresh,
              child: _filteredFiles.isEmpty
                  ? _buildEmptyState()
                  : ListView.separated(
                      controller: _scrollController,
                      padding:
                          EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.h),
                      itemCount: _filteredFiles.length,
                      separatorBuilder: (context, index) =>
                          SizedBox(height: 0.5.h),
                      itemBuilder: (context, index) {
                        final item = _filteredFiles[index];
                        final isSelected =
                            _selectedItems.contains(item['path']);

                        return FileItemWidget(
                          fileData: item,
                          isSelected: isSelected,
                          isMultiSelectMode: _isMultiSelectMode,
                          onTap: () => _onItemTap(item),
                          onLongPress: () => _onItemLongPress(item),
                          onToggleSelect: () => _toggleItemSelection(item),
                          onAddToSafe: () => _onAddToSafe(item),
                          onProperties: () => _onProperties(item),
                          onShare: () => _onShare(item),
                          onDeletePreview: () => _onDeletePreview(item),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
      bottomSheet: SelectionToolbarWidget(
        selectedCount: _selectedItems.length,
        isVisible: _isMultiSelectMode,
        onSelectAll: _onSelectAll,
        onClearSelection: _onClearSelection,
        onAddToWipeList: _onAddToWipeList,
        onMarkAsSafe: _onMarkAsSafe,
      ),
    );
  }

  Widget _buildEmptyState() {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CustomIconWidget(
            iconName: _searchQuery.isNotEmpty ? 'search_off' : 'folder_open',
            color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
            size: 15.w,
          ),
          SizedBox(height: 2.h),
          Text(
            _searchQuery.isNotEmpty ? 'No files found' : 'This folder is empty',
            style: theme.textTheme.titleMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
          SizedBox(height: 1.h),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search or filter'
                : 'Files and folders will appear here',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          if (_searchQuery.isNotEmpty) ...[
            SizedBox(height: 3.h),
            TextButton(
              onPressed: () {
                setState(() {
                  _searchQuery = '';
                  _selectedFilter = 'all';
                });
                _applyFilters();
              },
              child: Text('Clear filters'),
            ),
          ],
        ],
      ),
    );
  }
}