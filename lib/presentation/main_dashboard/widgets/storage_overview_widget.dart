import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class StorageOverviewWidget extends StatelessWidget {
  final String totalStorage;
  final String recoverableSpace;
  final bool isDetailedView;
  final VoidCallback? onToggleView;

  const StorageOverviewWidget({
    super.key,
    required this.totalStorage,
    required this.recoverableSpace,
    required this.isDetailedView,
    this.onToggleView,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(3.w),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
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
          _buildHeader(context),
          SizedBox(height: 3.h),
          isDetailedView
              ? _buildDetailedView(context)
              : _buildSimplifiedView(context),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Storage Overview',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
        ),
        GestureDetector(
          onTap: onToggleView,
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            decoration: BoxDecoration(
              color: colorScheme.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2.w),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName: isDetailedView ? 'visibility_off' : 'visibility',
                  color: colorScheme.primary,
                  size: 4.w,
                ),
                SizedBox(width: 1.w),
                Text(
                  isDetailedView ? 'Simple' : 'Detailed',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSimplifiedView(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            context,
            'Total Analyzed',
            totalStorage,
            CustomIconWidget(
              iconName: 'analytics',
              color: colorScheme.primary,
              size: 6.w,
            ),
            colorScheme.primary.withValues(alpha: 0.1),
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: _buildStatCard(
            context,
            'Recoverable',
            recoverableSpace,
            CustomIconWidget(
              iconName: 'cleaning_services',
              color: isDark ? const Color(0xFF10B981) : const Color(0xFF2D7D32),
              size: 6.w,
            ),
            (isDark ? const Color(0xFF10B981) : const Color(0xFF2D7D32))
                .withValues(alpha: 0.1),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedView(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Total Analyzed',
                totalStorage,
                CustomIconWidget(
                  iconName: 'analytics',
                  color: colorScheme.primary,
                  size: 6.w,
                ),
                colorScheme.primary.withValues(alpha: 0.1),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildStatCard(
                context,
                'Recoverable',
                recoverableSpace,
                CustomIconWidget(
                  iconName: 'cleaning_services',
                  color: isDark
                      ? const Color(0xFF10B981)
                      : const Color(0xFF2D7D32),
                  size: 6.w,
                ),
                (isDark ? const Color(0xFF10B981) : const Color(0xFF2D7D32))
                    .withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
        SizedBox(height: 2.h),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                'Secure Files',
                '1,247',
                CustomIconWidget(
                  iconName: 'security',
                  color: isDark
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFFE17B47),
                  size: 6.w,
                ),
                (isDark ? const Color(0xFFF59E0B) : const Color(0xFFE17B47))
                    .withValues(alpha: 0.1),
              ),
            ),
            SizedBox(width: 3.w),
            Expanded(
              child: _buildStatCard(
                context,
                'Last Scan',
                '2 hours ago',
                CustomIconWidget(
                  iconName: 'schedule',
                  color: isDark
                      ? const Color(0xFF9CA3AF)
                      : const Color(0xFF6B7280),
                  size: 6.w,
                ),
                (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280))
                    .withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(BuildContext context, String label, String value,
      Widget icon, Color backgroundColor) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(2.w),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  label,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withValues(alpha: 0.7),
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              icon,
            ],
          ),
          SizedBox(height: 1.h),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
