import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';


class SettingsToggleWidget extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final Widget? leading;
  final bool showDivider;

  const SettingsToggleWidget({
    super.key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
    this.leading,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
          child: Row(
            children: [
              if (leading != null) ...[
                leading!,
                SizedBox(width: 3.w),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurface,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (subtitle != null) ...[
                      SizedBox(height: 0.5.h),
                      Text(
                        subtitle!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(width: 2.w),
              Switch(
                value: value,
                onChanged: (newValue) {
                  HapticFeedback.lightImpact();
                  onChanged(newValue);
                },
                activeColor: theme.colorScheme.primary,
                inactiveThumbColor:
                    isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280),
                inactiveTrackColor:
                    (isDark ? const Color(0xFF9CA3AF) : const Color(0xFF6B7280))
                        .withValues(alpha: 0.3),
              ),
            ],
          ),
        ),
        if (showDivider)
          Divider(
            height: 1,
            thickness: 1,
            indent: 4.w,
            endIndent: 4.w,
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          ),
      ],
    );
  }
}
