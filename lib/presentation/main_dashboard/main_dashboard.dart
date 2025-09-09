import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/device_card_widget.dart';
import './widgets/empty_state_widget.dart';
import './widgets/security_indicator_widget.dart';
import './widgets/storage_overview_widget.dart';

class MainDashboard extends StatefulWidget {
  const MainDashboard({super.key});

  @override
  State<MainDashboard> createState() => _MainDashboardState();
}

class _MainDashboardState extends State<MainDashboard>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool _isDetailedView = false;
  bool _isRefreshing = false;
  bool _hasDevices = true;
  int _currentTabIndex = 0;

  // Mock data for storage overview
  final String _totalStorage = '2.4 TB';
  final String _recoverableSpace = '847 GB';

  // Mock data for connected devices
  final List<Map<String, dynamic>> _connectedDevices = [
    {
      'id': 'device_1',
      'name': 'Internal Storage',
      'type': 'internal',
      'capacity': '128 GB',
      'usedSpace': '89 GB',
      'usedPercentage': 69.5,
      'isConnected': true,
      'lastScan': '2 hours ago',
    },
    {
      'id': 'device_2',
      'name': 'SanDisk Ultra',
      'type': 'sd_card',
      'capacity': '64 GB',
      'usedSpace': '42 GB',
      'usedPercentage': 65.6,
      'isConnected': true,
      'lastScan': '1 hour ago',
    },
    {
      'id': 'device_3',
      'name': 'Kingston USB',
      'type': 'usb',
      'capacity': '32 GB',
      'usedSpace': '18 GB',
      'usedPercentage': 56.3,
      'isConnected': false,
      'lastScan': '1 day ago',
    },
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(_handleTabChange);
    _initializeApp();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      setState(() {
        _currentTabIndex = _tabController.index;
      });

      // Navigate to appropriate screens based on tab
      switch (_tabController.index) {
        case 0:
          // Dashboard - already here
          break;
        case 1:
          Navigator.pushNamed(context, '/operation-history');
          break;
        case 2:
          Navigator.pushNamed(context, '/settings');
          break;
      }
    }
  }

  Future<void> _initializeApp() async {
    await _requestPermissions();
    await _scanForDevices();
  }

  Future<void> _requestPermissions() async {
    try {
      final permissions = [
        Permission.storage,
        Permission.manageExternalStorage,
      ];

      for (final permission in permissions) {
        final status = await permission.request();
        if (!status.isGranted) {
          // Handle permission denied
          debugPrint('Permission denied: \$permission');
        }
      }
    } catch (e) {
      debugPrint('Error requesting permissions: \$e');
    }
  }

  Future<void> _scanForDevices() async {
    setState(() {
      _isRefreshing = true;
    });

    try {
      // Simulate device scanning
      await Future.delayed(const Duration(seconds: 2));

      // Trigger haptic feedback
      HapticFeedback.lightImpact();

      setState(() {
        _hasDevices = _connectedDevices.isNotEmpty;
        _isRefreshing = false;
      });
    } catch (e) {
      setState(() {
        _isRefreshing = false;
      });
      debugPrint('Error scanning devices: \$e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: _buildAppBar(context),
      body: RefreshIndicator(
        onRefresh: _scanForDevices,
        color: colorScheme.primary,
        child: _hasDevices
            ? _buildMainContent(context)
            : _buildEmptyState(context),
      ),
      floatingActionButton: _buildFloatingActionButton(context),
      bottomNavigationBar: _buildBottomNavigationBar(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBar(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      elevation: 2,
      title: Row(
        children: [
          Text(
            'SecureWipe Pro',
            style: theme.textTheme.titleLarge?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          const SecurityIndicatorWidget(
            securityLevel: 'Secure',
            isSecure: true,
          ),
        ],
      ),
      bottom: TabBar(
        controller: _tabController,
        indicatorColor: colorScheme.onPrimary,
        labelColor: colorScheme.onPrimary,
        unselectedLabelColor: colorScheme.onPrimary.withValues(alpha: 0.7),
        tabs: const [
          Tab(text: 'Dashboard'),
          Tab(text: 'History'),
          Tab(text: 'Settings'),
        ],
      ),
    );
  }

  Widget _buildMainContent(BuildContext context) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: 2.h),
          StorageOverviewWidget(
            totalStorage: _totalStorage,
            recoverableSpace: _recoverableSpace,
            isDetailedView: _isDetailedView,
            onToggleView: () {
              setState(() {
                _isDetailedView = !_isDetailedView;
              });
            },
          ),
          SizedBox(height: 2.h),
          _buildDevicesSection(context),
          SizedBox(height: 10.h), // Space for FAB
        ],
      ),
    );
  }

  Widget _buildDevicesSection(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 4.w),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Connected Devices',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
              ),
              if (_isRefreshing)
                SizedBox(
                  width: 5.w,
                  height: 5.w,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                        AlwaysStoppedAnimation<Color>(colorScheme.primary),
                  ),
                ),
            ],
          ),
        ),
        SizedBox(height: 2.h),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _connectedDevices.length,
          itemBuilder: (context, index) {
            final device = _connectedDevices[index];
            return DeviceCardWidget(
              device: device,
              onTap: () => _navigateToFileBrowser(device),
              onQuickScan: () => _performQuickScan(device),
              onSafeMode: () => _enableSafeMode(device),
              onEject: () => _ejectDevice(device),
              onRename: () => _renameDevice(device),
              onScanSettings: () => _openScanSettings(device),
              onRemove: () => _removeDevice(device),
            );
          },
        ),
      ],
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return EmptyStateWidget(
      onConnectDevice: _scanForDevices,
      onTroubleshooting: _openTroubleshootingGuide,
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return FloatingActionButton.extended(
      onPressed: _scanForDevices,
      backgroundColor: colorScheme.secondary,
      foregroundColor: colorScheme.onSecondary,
      icon: CustomIconWidget(
        iconName: 'search',
        color: colorScheme.onSecondary,
        size: 6.w,
      ),
      label: Text(
        'Scan Devices',
        style: theme.textTheme.labelLarge?.copyWith(
          color: colorScheme.onSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: BottomNavigationBar(
          currentIndex: _currentTabIndex,
          onTap: (index) {
            setState(() {
              _currentTabIndex = index;
              _tabController.animateTo(index);
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.transparent,
          selectedItemColor: colorScheme.primary,
          unselectedItemColor:
              isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          elevation: 0,
          items: [
            BottomNavigationBarItem(
              icon: CustomIconWidget(
                iconName:
                    _currentTabIndex == 0 ? 'dashboard' : 'dashboard_outlined',
                color: _currentTabIndex == 0
                    ? colorScheme.primary
                    : (isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280)),
                size: 6.w,
              ),
              label: 'Dashboard',
            ),
            BottomNavigationBarItem(
              icon: CustomIconWidget(
                iconName:
                    _currentTabIndex == 1 ? 'history' : 'history_outlined',
                color: _currentTabIndex == 1
                    ? colorScheme.primary
                    : (isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280)),
                size: 6.w,
              ),
              label: 'History',
            ),
            BottomNavigationBarItem(
              icon: CustomIconWidget(
                iconName:
                    _currentTabIndex == 2 ? 'settings' : 'settings_outlined',
                color: _currentTabIndex == 2
                    ? colorScheme.primary
                    : (isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280)),
                size: 6.w,
              ),
              label: 'Settings',
            ),
          ],
        ),
      ),
    );
  }

  // Navigation and action methods
  void _navigateToFileBrowser(Map<String, dynamic> device) {
    Navigator.pushNamed(context, '/file-browser', arguments: device);
  }

  void _performQuickScan(Map<String, dynamic> device) {
    // Implement quick scan functionality
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Quick scan started for ${device['name']}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _enableSafeMode(Map<String, dynamic> device) {
    // Implement safe mode functionality
    HapticFeedback.mediumImpact();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Safe mode enabled for ${device['name']}'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _ejectDevice(Map<String, dynamic> device) {
    // Implement device ejection
    HapticFeedback.mediumImpact();
    setState(() {
      final deviceIndex =
          _connectedDevices.indexWhere((d) => d['id'] == device['id']);
      if (deviceIndex != -1) {
        _connectedDevices[deviceIndex]['isConnected'] = false;
      }
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${device['name']} ejected safely'),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _renameDevice(Map<String, dynamic> device) {
    // Implement device renaming
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename Device'),
        content: TextFormField(
          initialValue: device['name'],
          decoration: const InputDecoration(
            labelText: 'Device Name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Device renamed successfully'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Rename'),
          ),
        ],
      ),
    );
  }

  void _openScanSettings(Map<String, dynamic> device) {
    // Navigate to scan settings
    Navigator.pushNamed(context, '/settings', arguments: {'tab': 'scan'});
  }

  void _removeDevice(Map<String, dynamic> device) {
    // Remove device from list
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remove Device'),
        content: Text(
            'Are you sure you want to remove "${device['name']}" from the list?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _connectedDevices.removeWhere((d) => d['id'] == device['id']);
                _hasDevices = _connectedDevices.isNotEmpty;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${device['name']} removed from list'),
                  duration: const Duration(seconds: 2),
                ),
              );
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }

  void _openTroubleshootingGuide() {
    // Open troubleshooting guide
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Troubleshooting Guide'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Device Not Detected?',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text('• Ensure the device is properly connected'),
              Text('• Check if the device is formatted correctly'),
              Text('• Try disconnecting and reconnecting'),
              Text('• Restart the app if needed'),
              SizedBox(height: 16),
              Text(
                'Permission Issues?',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 8),
              Text('• Grant storage permissions in Settings'),
              Text('• Enable "All files access" for Android 11+'),
              Text('• Restart the app after granting permissions'),
            ],
          ),
        ),
        actions: [
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}