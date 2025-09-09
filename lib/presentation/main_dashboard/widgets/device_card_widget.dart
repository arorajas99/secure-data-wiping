import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class DeviceCardWidget extends StatelessWidget {
  final Map<String, dynamic> device;
  final VoidCallback? onTap;
  final VoidCallback? onQuickScan;
  final VoidCallback? onSafeMode;
  final VoidCallback? onEject;
  final VoidCallback? onRename;
  final VoidCallback? onScanSettings;
  final VoidCallback? onRemove;

  const DeviceCardWidget({
    super.key,
    required this.device,
    this.onTap,
    this.onQuickScan,
    this.onSafeMode,
    this.onEject,
    this.onRename,
    this.onScanSettings,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final isConnected = device['isConnected'] as bool? ?? false;
    final deviceName = device['name'] as String? ?? 'Unknown Device';
    final deviceType = device['type'] as String? ?? 'storage';
    final capacity = device['capacity'] as String? ?? '0 GB';
    final usedSpace = device['usedSpace'] as String? ?? '0 GB';
    final usedPercentage = device['usedPercentage'] as double? ?? 0.0;
    final lastScan = device['lastScan'] as String? ?? 'Never';

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Slidable(
        key: ValueKey(device['id']),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => onQuickScan?.call(),
              backgroundColor: colorScheme.primary,
              foregroundColor: colorScheme.onPrimary,
              icon: Icons.search,
              label: 'Quick Scan',
              borderRadius: BorderRadius.circular(2.w),
            ),
            SlidableAction(
              onPressed: (_) => onSafeMode?.call(),
              backgroundColor:
                  isDark ? const Color(0xFFF59E0B) : const Color(0xFFE17B47),
              foregroundColor: Colors.white,
              icon: Icons.security,
              label: 'Safe Mode',
              borderRadius: BorderRadius.circular(2.w),
            ),
            SlidableAction(
              onPressed: (_) => onEject?.call(),
              backgroundColor:
                  isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              foregroundColor: Colors.white,
              icon: Icons.eject,
              label: 'Eject',
              borderRadius: BorderRadius.circular(2.w),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: onTap,
          onLongPress: () => _showContextMenu(context),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(3.w),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : Colors.black.withValues(alpha: 0.08),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDeviceHeader(
                    context, isConnected, deviceName, deviceType),
                SizedBox(height: 2.h),
                _buildStorageInfo(context, capacity, usedSpace, usedPercentage),
                SizedBox(height: 2.h),
                _buildLastScanInfo(context, lastScan),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDeviceHeader(BuildContext context, bool isConnected,
      String deviceName, String deviceType) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(2.w),
          ),
          child: CustomIconWidget(
            iconName: _getDeviceIcon(deviceType),
            color: colorScheme.primary,
            size: 6.w,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      deviceName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: 2.w),
                  Container(
                    width: 2.w,
                    height: 2.w,
                    decoration: BoxDecoration(
                      color: isConnected
                          ? (isDark
                              ? const Color(0xFF10B981)
                              : const Color(0xFF2D7D32))
                          : (isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280)),
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 0.5.h),
              Text(
                isConnected ? 'Connected' : 'Disconnected',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: isConnected
                      ? (isDark
                          ? const Color(0xFF10B981)
                          : const Color(0xFF2D7D32))
                      : (isDark
                          ? const Color(0xFF9CA3AF)
                          : const Color(0xFF6B7280)),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStorageInfo(BuildContext context, String capacity,
      String usedSpace, double usedPercentage) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Storage',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '\$usedSpace of \$capacity',
              style: theme.textTheme.bodySmall?.copyWith(
                color:
                    isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        SizedBox(height: 1.h),
        Container(
          width: double.infinity,
          height: 1.h,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
            borderRadius: BorderRadius.circular(0.5.h),
          ),
          child: FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor: usedPercentage / 100,
            child: Container(
              decoration: BoxDecoration(
                color: _getStorageColor(usedPercentage, isDark),
                borderRadius: BorderRadius.circular(0.5.h),
              ),
            ),
          ),
        ),
        SizedBox(height: 0.5.h),
        Text(
          '${usedPercentage.toStringAsFixed(1)}% used',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildLastScanInfo(BuildContext context, String lastScan) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        CustomIconWidget(
          iconName: 'schedule',
          color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          size: 4.w,
        ),
        SizedBox(width: 2.w),
        Text(
          'Last scan: \$lastScan',
          style: theme.textTheme.bodySmall?.copyWith(
            color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  String _getDeviceIcon(String deviceType) {
    switch (deviceType.toLowerCase()) {
      case 'internal':
        return 'phone_android';
      case 'sd_card':
        return 'sd_card';
      case 'usb':
        return 'usb';
      case 'external':
        return 'storage';
      default:
        return 'storage';
    }
  }

  Color _getStorageColor(double percentage, bool isDark) {
    if (percentage >= 90) {
      return isDark ? const Color(0xFFEF4444) : const Color(0xFFC5282F);
    } else if (percentage >= 70) {
      return isDark ? const Color(0xFFF59E0B) : const Color(0xFFE17B47);
    } else {
      return isDark ? const Color(0xFF10B981) : const Color(0xFF2D7D32);
    }
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(4.w)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 12.w,
                height: 1.h,
                margin: EdgeInsets.symmetric(vertical: 2.h),
                decoration: BoxDecoration(
                  color: Theme.of(context).brightness == Brightness.dark
                      ? const Color(0xFF374151)
                      : const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(0.5.h),
                ),
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'edit',
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 6.w,
                ),
                title: Text('Rename Device'),
                onTap: () {
                  Navigator.pop(context);
                  onRename?.call();
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'settings',
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 6.w,
                ),
                title: Text('Scan Settings'),
                onTap: () {
                  Navigator.pop(context);
                  onScanSettings?.call();
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'delete_outline',
                  color: Theme.of(context).colorScheme.error,
                  size: 6.w,
                ),
                title: Text(
                  'Remove from List',
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  onRemove?.call();
                },
              ),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }
}
