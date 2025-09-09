import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class SecurityIndicatorWidget extends StatelessWidget {
  final String securityLevel;
  final bool isSecure;

  const SecurityIndicatorWidget({
    super.key,
    required this.securityLevel,
    required this.isSecure,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final indicatorColor = _getSecurityColor(isDark);
    final indicatorIcon = _getSecurityIcon();

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
      decoration: BoxDecoration(
        color: indicatorColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(2.w),
        border: Border.all(
          color: indicatorColor.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CustomIconWidget(
            iconName: indicatorIcon,
            color: indicatorColor,
            size: 4.w,
          ),
          SizedBox(width: 2.w),
          Text(
            securityLevel,
            style: theme.textTheme.bodySmall?.copyWith(
              color: indicatorColor,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Color _getSecurityColor(bool isDark) {
    if (isSecure) {
      return isDark ? const Color(0xFF10B981) : const Color(0xFF2D7D32);
    } else {
      return isDark ? const Color(0xFFEF4444) : const Color(0xFFC5282F);
    }
  }

  String _getSecurityIcon() {
    return isSecure ? 'security' : 'warning';
  }
}
