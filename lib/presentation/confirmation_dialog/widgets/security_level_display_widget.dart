import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class SecurityLevelDisplayWidget extends StatelessWidget {
  final String securityLevel;
  final String description;
  final int passCount;

  const SecurityLevelDisplayWidget({
    super.key,
    required this.securityLevel,
    required this.description,
    required this.passCount,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: _getSecurityLevelColor(colorScheme).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(2.w),
        border: Border.all(
          color: _getSecurityLevelColor(colorScheme).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'security',
                color: _getSecurityLevelColor(colorScheme),
                size: 5.w,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Security Level',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      securityLevel,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _getSecurityLevelColor(colorScheme),
                      ),
                    ),
                  ],
                ),
              ),
              _buildSecurityBadge(context),
            ],
          ),
          SizedBox(height: 3.w),
          Text(
            description,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 2.w),
          _buildPassCountInfo(context),
        ],
      ),
    );
  }

  Widget _buildSecurityBadge(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 2.w, vertical: 1.w),
      decoration: BoxDecoration(
        color: _getSecurityLevelColor(colorScheme),
        borderRadius: BorderRadius.circular(1.w),
      ),
      child: Text(
        _getSecurityRating(),
        style: theme.textTheme.bodySmall?.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildPassCountInfo(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(2.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(1.w),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          CustomIconWidget(
            iconName: 'loop',
            color: colorScheme.onSurfaceVariant,
            size: 4.w,
          ),
          SizedBox(width: 2.w),
          Text(
            'Overwrite Passes: $passCount',
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSecurityLevelColor(ColorScheme colorScheme) {
    switch (securityLevel.toLowerCase()) {
      case 'quick':
        return const Color(0xFF10B981); // Green
      case 'standard':
        return const Color(0xFF3B82F6); // Blue
      case 'secure':
        return const Color(0xFFF59E0B); // Orange
      case 'military':
        return const Color(0xFFEF4444); // Red
      default:
        return colorScheme.primary;
    }
  }

  String _getSecurityRating() {
    switch (securityLevel.toLowerCase()) {
      case 'quick':
        return 'BASIC';
      case 'standard':
        return 'GOOD';
      case 'secure':
        return 'HIGH';
      case 'military':
        return 'MAX';
      default:
        return 'UNKNOWN';
    }
  }
}
