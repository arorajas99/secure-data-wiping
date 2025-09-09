import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class CriticalWarningWidget extends StatelessWidget {
  const CriticalWarningWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFFEF4444) : const Color(0xFFC5282F))
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(2.w),
        border: Border.all(
          color: isDark ? const Color(0xFFEF4444) : const Color(0xFFC5282F),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CustomIconWidget(
                iconName: 'warning',
                color:
                    isDark ? const Color(0xFFEF4444) : const Color(0xFFC5282F),
                size: 6.w,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Text(
                  'CRITICAL WARNING',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFC5282F),
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 3.w),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(3.w),
            decoration: BoxDecoration(
              color:
                  (isDark ? const Color(0xFFEF4444) : const Color(0xFFC5282F))
                      .withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(1.5.w),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'This will permanently delete selected data.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFC5282F),
                  ),
                ),
                SizedBox(height: 2.w),
                Text(
                  'This action cannot be undone.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: isDark
                        ? const Color(0xFFEF4444)
                        : const Color(0xFFC5282F),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 3.w),
          _buildWarningPoints(context),
        ],
      ),
    );
  }

  Widget _buildWarningPoints(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final warningPoints = [
      'Data will be overwritten multiple times using secure algorithms',
      'Recovery will be impossible even with specialized software',
      'Process cannot be stopped once started',
      'Ensure you have backups of any important data',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: warningPoints
          .map((point) => Padding(
                padding: EdgeInsets.only(bottom: 2.w),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(top: 0.5.w),
                      child: CustomIconWidget(
                        iconName: 'fiber_manual_record',
                        color: isDark
                            ? const Color(0xFFEF4444)
                            : const Color(0xFFC5282F),
                        size: 2.w,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Expanded(
                      child: Text(
                        point,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}
