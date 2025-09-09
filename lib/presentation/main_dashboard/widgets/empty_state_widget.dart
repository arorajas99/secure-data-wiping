import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class EmptyStateWidget extends StatelessWidget {
  final VoidCallback? onConnectDevice;
  final VoidCallback? onTroubleshooting;

  const EmptyStateWidget({
    super.key,
    this.onConnectDevice,
    this.onTroubleshooting,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 4.h),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildIllustration(context),
            SizedBox(height: 4.h),
            _buildTitle(context),
            SizedBox(height: 2.h),
            _buildDescription(context),
            SizedBox(height: 4.h),
            _buildConnectButton(context),
            SizedBox(height: 2.h),
            _buildTroubleshootingLink(context),
          ],
        ),
      ),
    );
  }

  Widget _buildIllustration(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 40.w,
      height: 40.w,
      decoration: BoxDecoration(
        color: colorScheme.primary.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomIconWidget(
            iconName: 'storage',
            color: colorScheme.primary.withValues(alpha: 0.3),
            size: 20.w,
          ),
          Positioned(
            bottom: 8.w,
            right: 8.w,
            child: Container(
              padding: EdgeInsets.all(1.w),
              decoration: BoxDecoration(
                color:
                    isDark ? const Color(0xFFF59E0B) : const Color(0xFFE17B47),
                shape: BoxShape.circle,
              ),
              child: CustomIconWidget(
                iconName: 'add',
                color: Colors.white,
                size: 4.w,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Text(
      'No Storage Devices Found',
      style: theme.textTheme.headlineSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildDescription(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Text(
      'Connect an external storage device like an SD card or USB drive to get started with secure data wiping.',
      style: theme.textTheme.bodyMedium?.copyWith(
        color: isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
        height: 1.5,
      ),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildConnectButton(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onConnectDevice,
        icon: CustomIconWidget(
          iconName: 'add_circle_outline',
          color: colorScheme.onPrimary,
          size: 5.w,
        ),
        label: Text(
          'Connect Storage Device',
          style: theme.textTheme.labelLarge?.copyWith(
            color: colorScheme.onPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: colorScheme.primary,
          foregroundColor: colorScheme.onPrimary,
          padding: EdgeInsets.symmetric(vertical: 3.h),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(3.w),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildTroubleshootingLink(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return TextButton.icon(
      onPressed: onTroubleshooting,
      icon: CustomIconWidget(
        iconName: 'help_outline',
        color: colorScheme.primary,
        size: 4.w,
      ),
      label: Text(
        'Troubleshooting Guide',
        style: theme.textTheme.bodyMedium?.copyWith(
          color: colorScheme.primary,
          fontWeight: FontWeight.w500,
          decoration: TextDecoration.underline,
        ),
      ),
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
      ),
    );
  }
}
