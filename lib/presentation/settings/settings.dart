import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/account_info_widget.dart';
import './widgets/security_level_selector_widget.dart';
import './widgets/settings_item_widget.dart';
import './widgets/settings_section_widget.dart';
import './widgets/settings_toggle_widget.dart';

class Settings extends StatefulWidget {
  const Settings({super.key});

  @override
  State<Settings> createState() => _SettingsState();
}

class _SettingsState extends State<Settings> with TickerProviderStateMixin {
  late TabController _tabController;
  int _currentTabIndex = 0;
  bool _isRefreshing = false;

  // Settings state variables
  bool _biometricAuth = true;
  bool _screenshotBlocking = false;
  bool _autoDeviceDetection = true;
  bool _showHiddenFiles = false;
  bool _completionNotifications = true;
  bool _verificationRequired = true;
  bool _operationLogging = true;
  bool _autoCleanup = false;
  bool _developerOptions = false;
  String _autoLockTimeout = "5 minutes";
  String _securityLevel = "secure";
  String _theme = "system";
  String _language = "English";
  String _loggingLevel = "Standard";

  // Mock user data
  final Map<String, dynamic> _userInfo = {
    "name": "Sarah Johnson",
    "email": "sarah.johnson@example.com",
    "isPremium": true,
    "accountCreated": "March 2024",
    "lastSync": "2 hours ago",
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(() {
      if (_tabController.indexIsChanging) {
        setState(() {
          _currentTabIndex = _tabController.index;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshSettings() async {
    setState(() {
      _isRefreshing = true;
    });

    // Simulate checking for app updates and syncing cloud preferences
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isRefreshing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Settings synced successfully'),
          backgroundColor: Theme.of(context).colorScheme.primary,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showConfirmationDialog({
    required String title,
    required String message,
    required VoidCallback onConfirm,
    bool isDestructive = false,
  }) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                onConfirm();
              },
              style: isDestructive
                  ? ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    )
                  : null,
              child: Text(isDestructive ? 'Delete' : 'Confirm'),
            ),
          ],
        );
      },
    );
  }

  void _showSecurityLevelDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Default Security Level'),
          content: SizedBox(
            width: double.maxFinite,
            child: SecurityLevelSelectorWidget(
              currentLevel: _securityLevel,
              onChanged: (level) {
                setState(() {
                  _securityLevel = level;
                });
                Navigator.of(context).pop();
                HapticFeedback.lightImpact();
              },
            ),
          ),
        );
      },
    );
  }

  void _showAutoLockDialog() {
    final List<String> timeouts = [
      "Immediately",
      "30 seconds",
      "1 minute",
      "5 minutes",
      "15 minutes",
      "Never"
    ];

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Auto-Lock Timeout'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: timeouts.map((timeout) {
              return RadioListTile<String>(
                title: Text(timeout),
                value: timeout,
                groupValue: _autoLockTimeout,
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _autoLockTimeout = value;
                    });
                    Navigator.of(context).pop();
                    HapticFeedback.lightImpact();
                  }
                },
              );
            }).toList(),
          ),
        );
      },
    );
  }

  void _exportData() {
    _showConfirmationDialog(
      title: 'Export Data',
      message:
          'This will create a backup of your settings and operation history. Continue?',
      onConfirm: () {
        // Simulate data export
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Data export started. You will be notified when complete.'),
            duration: Duration(seconds: 3),
          ),
        );
      },
    );
  }

  void _deleteAccount() {
    _showConfirmationDialog(
      title: 'Delete Account',
      message:
          'This action cannot be undone. All your data will be permanently deleted.',
      onConfirm: () {
        // Show second confirmation
        _showConfirmationDialog(
          title: 'Are you absolutely sure?',
          message: 'Type "DELETE" to confirm account deletion.',
          onConfirm: () {
            // Navigate to confirmation dialog
            Navigator.pushNamed(context, '/confirmation-dialog');
          },
          isDestructive: true,
        );
      },
      isDestructive: true,
    );
  }

  void _resetToDefaults() {
    _showConfirmationDialog(
      title: 'Reset to Defaults',
      message:
          'This will reset all settings to their default values. Continue?',
      onConfirm: () {
        setState(() {
          _biometricAuth = true;
          _screenshotBlocking = false;
          _autoDeviceDetection = true;
          _showHiddenFiles = false;
          _completionNotifications = true;
          _verificationRequired = true;
          _operationLogging = true;
          _autoCleanup = false;
          _developerOptions = false;
          _autoLockTimeout = "5 minutes";
          _securityLevel = "secure";
          _theme = "system";
          _language = "English";
          _loggingLevel = "Standard";
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Settings reset to defaults'),
            duration: Duration(seconds: 2),
          ),
        );
      },
    );
  }

  Widget _buildGeneralTab() {
    return RefreshIndicator(
      onRefresh: _refreshSettings,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            SizedBox(height: 2.h),

            // Account Section
            SettingsSectionWidget(
              title: "Account",
              children: [
                AccountInfoWidget(userInfo: _userInfo),
                SettingsItemWidget(
                  title: "Manage Subscription",
                  subtitle: _userInfo["isPremium"] == true
                      ? "Premium active until Dec 2024"
                      : "Upgrade to Premium",
                  leading: CustomIconWidget(
                    iconName: 'card_membership',
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  onTap: () {
                    // Navigate to subscription management
                  },
                ),
                SettingsItemWidget(
                  title: "Sync Settings",
                  subtitle: "Last synced: ${_userInfo["lastSync"]}",
                  leading: CustomIconWidget(
                    iconName: 'sync',
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  onTap: _refreshSettings,
                  showDivider: false,
                ),
              ],
            ),

            // Appearance Section
            SettingsSectionWidget(
              title: "Appearance",
              children: [
                SettingsItemWidget(
                  title: "Theme",
                  value: _theme,
                  leading: CustomIconWidget(
                    iconName: 'palette',
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  onTap: () {
                    // Show theme selector
                  },
                ),
                SettingsItemWidget(
                  title: "Language",
                  value: _language,
                  leading: CustomIconWidget(
                    iconName: 'language',
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  onTap: () {
                    // Show language selector
                  },
                ),
                SettingsItemWidget(
                  title: "Accessibility",
                  leading: CustomIconWidget(
                    iconName: 'accessibility',
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  onTap: () {
                    // Navigate to accessibility settings
                  },
                  showDivider: false,
                ),
              ],
            ),

            // Notifications Section
            SettingsSectionWidget(
              title: "Notifications",
              children: [
                SettingsToggleWidget(
                  title: "Completion Notifications",
                  subtitle: "Get notified when operations complete",
                  value: _completionNotifications,
                  onChanged: (value) {
                    setState(() {
                      _completionNotifications = value;
                    });
                  },
                  leading: CustomIconWidget(
                    iconName: 'notifications',
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  showDivider: false,
                ),
              ],
            ),

            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }

  Widget _buildSecurityTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 2.h),

          // Authentication Section
          SettingsSectionWidget(
            title: "Authentication",
            children: [
              SettingsToggleWidget(
                title: "Biometric Authentication",
                subtitle: "Use fingerprint or face unlock",
                value: _biometricAuth,
                onChanged: (value) {
                  setState(() {
                    _biometricAuth = value;
                  });
                },
                leading: CustomIconWidget(
                  iconName: 'fingerprint',
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              SettingsItemWidget(
                title: "Auto-Lock Timeout",
                value: _autoLockTimeout,
                leading: CustomIconWidget(
                  iconName: 'lock_clock',
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                onTap: _showAutoLockDialog,
                showDivider: false,
              ),
            ],
          ),

          // Privacy Section
          SettingsSectionWidget(
            title: "Privacy",
            children: [
              SettingsToggleWidget(
                title: "Screenshot Blocking",
                subtitle: "Prevent screenshots in sensitive areas",
                value: _screenshotBlocking,
                onChanged: (value) {
                  setState(() {
                    _screenshotBlocking = value;
                  });
                },
                leading: CustomIconWidget(
                  iconName: 'screenshot_monitor',
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              SettingsItemWidget(
                title: "Privacy Policy",
                leading: CustomIconWidget(
                  iconName: 'privacy_tip',
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                onTap: () {
                  // Open privacy policy
                },
                showDivider: false,
              ),
            ],
          ),

          // Default Operations Section
          SettingsSectionWidget(
            title: "Default Operations",
            children: [
              SettingsItemWidget(
                title: "Security Level",
                value: _securityLevel.toUpperCase(),
                leading: CustomIconWidget(
                  iconName: 'security',
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                onTap: _showSecurityLevelDialog,
              ),
              SettingsToggleWidget(
                title: "Verification Required",
                subtitle: "Require confirmation before wiping",
                value: _verificationRequired,
                onChanged: (value) {
                  setState(() {
                    _verificationRequired = value;
                  });
                },
                leading: CustomIconWidget(
                  iconName: 'verified',
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                showDivider: false,
              ),
            ],
          ),

          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildPrivacyTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 2.h),

          // Storage Privacy Section
          SettingsSectionWidget(
            title: "Storage Privacy",
            children: [
              SettingsToggleWidget(
                title: "Auto Device Detection",
                subtitle: "Automatically detect connected storage",
                value: _autoDeviceDetection,
                onChanged: (value) {
                  setState(() {
                    _autoDeviceDetection = value;
                  });
                },
                leading: CustomIconWidget(
                  iconName: 'storage',
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              SettingsToggleWidget(
                title: "Show Hidden Files",
                subtitle: "Display hidden and system files",
                value: _showHiddenFiles,
                onChanged: (value) {
                  setState(() {
                    _showHiddenFiles = value;
                  });
                },
                leading: CustomIconWidget(
                  iconName: 'visibility',
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                showDivider: false,
              ),
            ],
          ),

          // Data Management Section
          SettingsSectionWidget(
            title: "Data Management",
            children: [
              SettingsItemWidget(
                title: "Export Data",
                subtitle: "Download your settings and history",
                leading: CustomIconWidget(
                  iconName: 'file_download',
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                onTap: _exportData,
              ),
              SettingsItemWidget(
                title: "Clear Operation History",
                subtitle: "Remove all operation logs",
                leading: CustomIconWidget(
                  iconName: 'history',
                  color: Theme.of(context).colorScheme.error,
                  size: 24,
                ),
                onTap: () {
                  _showConfirmationDialog(
                    title: 'Clear History',
                    message:
                        'This will permanently delete all operation history. Continue?',
                    onConfirm: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Operation history cleared'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    isDestructive: true,
                  );
                },
              ),
              SettingsItemWidget(
                title: "Delete Account",
                subtitle: "Permanently delete your account",
                leading: CustomIconWidget(
                  iconName: 'delete_forever',
                  color: Theme.of(context).colorScheme.error,
                  size: 24,
                ),
                onTap: _deleteAccount,
                isDestructive: true,
                showDivider: false,
              ),
            ],
          ),

          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  Widget _buildAdvancedTab() {
    return SingleChildScrollView(
      child: Column(
        children: [
          SizedBox(height: 2.h),

          // Logging Section
          SettingsSectionWidget(
            title: "Logging",
            children: [
              SettingsToggleWidget(
                title: "Operation Logging",
                subtitle: "Keep detailed logs of all operations",
                value: _operationLogging,
                onChanged: (value) {
                  setState(() {
                    _operationLogging = value;
                  });
                },
                leading: CustomIconWidget(
                  iconName: 'article',
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              SettingsItemWidget(
                title: "Logging Level",
                value: _loggingLevel,
                leading: CustomIconWidget(
                  iconName: 'tune',
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                onTap: () {
                  // Show logging level selector
                },
                showDivider: false,
              ),
            ],
          ),

          // Maintenance Section
          SettingsSectionWidget(
            title: "Maintenance",
            children: [
              SettingsToggleWidget(
                title: "Auto Cleanup",
                subtitle: "Automatically clean temporary files",
                value: _autoCleanup,
                onChanged: (value) {
                  setState(() {
                    _autoCleanup = value;
                  });
                },
                leading: CustomIconWidget(
                  iconName: 'cleaning_services',
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              SettingsItemWidget(
                title: "Clear Cache",
                subtitle: "Free up storage space",
                leading: CustomIconWidget(
                  iconName: 'clear_all',
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                onTap: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Cache cleared successfully'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                showDivider: false,
              ),
            ],
          ),

          // Developer Section
          SettingsSectionWidget(
            title: "Developer",
            children: [
              SettingsToggleWidget(
                title: "Developer Options",
                subtitle: "Enable advanced debugging features",
                value: _developerOptions,
                onChanged: (value) {
                  setState(() {
                    _developerOptions = value;
                  });
                },
                leading: CustomIconWidget(
                  iconName: 'code',
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
              ),
              if (_developerOptions) ...[
                SettingsItemWidget(
                  title: "Debug Logs",
                  subtitle: "View detailed debug information",
                  leading: CustomIconWidget(
                    iconName: 'bug_report',
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  onTap: () {
                    // Navigate to debug logs
                  },
                ),
                SettingsItemWidget(
                  title: "Performance Monitor",
                  subtitle: "Monitor app performance metrics",
                  leading: CustomIconWidget(
                    iconName: 'speed',
                    color: Theme.of(context).colorScheme.primary,
                    size: 24,
                  ),
                  onTap: () {
                    // Navigate to performance monitor
                  },
                ),
              ],
            ],
          ),

          // Reset Section
          SettingsSectionWidget(
            title: "Reset",
            children: [
              SettingsItemWidget(
                title: "Reset to Defaults",
                subtitle: "Restore all settings to default values",
                leading: CustomIconWidget(
                  iconName: 'restore',
                  color: Theme.of(context).colorScheme.error,
                  size: 24,
                ),
                onTap: _resetToDefaults,
                isDestructive: true,
                showDivider: false,
              ),
            ],
          ),

          SizedBox(height: 2.h),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Settings'),
        leading: IconButton(
          icon: CustomIconWidget(
            iconName: 'arrow_back',
            color: theme.appBarTheme.foregroundColor ??
                theme.colorScheme.onPrimary,
            size: 24,
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'General'),
            Tab(text: 'Security'),
            Tab(text: 'Privacy'),
            Tab(text: 'Advanced'),
          ],
        ),
      ),
      body: SafeArea(
        child: _isRefreshing
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    SizedBox(height: 2.h),
                    Text(
                      'Syncing settings...',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.brightness == Brightness.dark
                            ? const Color(0xFF9CA3AF)
                            : const Color(0xFF6B7280),
                      ),
                    ),
                  ],
                ),
              )
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildGeneralTab(),
                  _buildSecurityTab(),
                  _buildPrivacyTab(),
                  _buildAdvancedTab(),
                ],
              ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: 3, // Settings tab is active
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.pushNamed(context, '/main-dashboard');
              break;
            case 1:
              Navigator.pushNamed(context, '/file-browser');
              break;
            case 2:
              Navigator.pushNamed(context, '/operation-history');
              break;
            case 3:
              // Already on settings
              break;
          }
        },
        items: [
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'dashboard',
              color: theme.bottomNavigationBarTheme.unselectedItemColor ??
                  Colors.grey,
              size: 24,
            ),
            activeIcon: CustomIconWidget(
              iconName: 'dashboard',
              color: theme.bottomNavigationBarTheme.selectedItemColor ??
                  theme.colorScheme.primary,
              size: 24,
            ),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'folder',
              color: theme.bottomNavigationBarTheme.unselectedItemColor ??
                  Colors.grey,
              size: 24,
            ),
            activeIcon: CustomIconWidget(
              iconName: 'folder',
              color: theme.bottomNavigationBarTheme.selectedItemColor ??
                  theme.colorScheme.primary,
              size: 24,
            ),
            label: 'Files',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'history',
              color: theme.bottomNavigationBarTheme.unselectedItemColor ??
                  Colors.grey,
              size: 24,
            ),
            activeIcon: CustomIconWidget(
              iconName: 'history',
              color: theme.bottomNavigationBarTheme.selectedItemColor ??
                  theme.colorScheme.primary,
              size: 24,
            ),
            label: 'History',
          ),
          BottomNavigationBarItem(
            icon: CustomIconWidget(
              iconName: 'settings',
              color: theme.bottomNavigationBarTheme.selectedItemColor ??
                  theme.colorScheme.primary,
              size: 24,
            ),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
