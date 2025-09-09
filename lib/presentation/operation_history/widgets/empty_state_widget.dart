import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Widget for displaying empty state in operation history
class EmptyStateWidget extends StatelessWidget {
  final VoidCallback? onStartFirstWipe;

  const EmptyStateWidget({
    super.key,
    this.onStartFirstWipe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 30.w,
              height: 30.w,
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(15.w),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'history',
                  color: colorScheme.primary,
                  size: 15.w,
                ),
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'No operations yet',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 2.h),
            Text(
              'Your secure deletion history will appear here once you start wiping data.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 6.h),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: onStartFirstWipe,
                icon: CustomIconWidget(
                  iconName: 'delete_sweep',
                  color: colorScheme.onPrimary,
                  size: 5.w,
                ),
                label: Text(
                  'Start First Wipe',
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: colorScheme.onPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary,
                  foregroundColor: colorScheme.onPrimary,
                  padding: EdgeInsets.symmetric(vertical: 2.h),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(3.w),
                  ),
                  elevation: 2,
                ),
              ),
            ),
            SizedBox(height: 3.h),
            TextButton.icon(
              onPressed: () => Navigator.pushNamed(context, '/file-browser'),
              icon: CustomIconWidget(
                iconName: 'folder',
                color: colorScheme.primary,
                size: 4.w,
              ),
              label: Text(
                'Browse Files',
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colorScheme.primary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
