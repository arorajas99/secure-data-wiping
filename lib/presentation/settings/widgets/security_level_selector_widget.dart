import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class SecurityLevelSelectorWidget extends StatelessWidget {
  final String currentLevel;
  final ValueChanged<String> onChanged;

  const SecurityLevelSelectorWidget({
    super.key,
    required this.currentLevel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final List<Map<String, dynamic>> securityLevels = [
      {
        "id": "quick",
        "name": "Quick",
        "description": "Fast deletion, basic security",
        "icon": "flash_on",
        "color": isDark ? const Color(0xFFF59E0B) : const Color(0xFFE17B47),
      },
      {
        "id": "secure",
        "name": "Secure",
        "description": "Balanced security and speed",
        "icon": "security",
        "color": isDark ? const Color(0xFF4A90A4) : const Color(0xFF1B365D),
      },
      {
        "id": "military",
        "name": "Military",
        "description": "Maximum security, slower process",
        "icon": "verified_user",
        "color": isDark ? const Color(0xFF10B981) : const Color(0xFF2D7D32),
      },
    ];

    return Column(
      children: securityLevels.asMap().entries.map((entry) {
        final index = entry.key;
        final level = entry.value;
        final isSelected = currentLevel == level["id"];
        final isLast = index == securityLevels.length - 1;

        return Column(
          children: [
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => onChanged(level["id"] as String),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
                  child: Row(
                    children: [
                      Container(
                        width: 10.w,
                        height: 10.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color:
                              (level["color"] as Color).withValues(alpha: 0.1),
                        ),
                        child: Center(
                          child: CustomIconWidget(
                            iconName: level["icon"] as String,
                            color: level["color"] as Color,
                            size: 20,
                          ),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              level["name"] as String,
                              style: theme.textTheme.bodyLarge?.copyWith(
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.onSurface,
                              ),
                            ),
                            SizedBox(height: 0.5.h),
                            Text(
                              level["description"] as String,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: isDark
                                    ? const Color(0xFF9CA3AF)
                                    : const Color(0xFF6B7280),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Radio<String>(
                        value: level["id"] as String,
                        groupValue: currentLevel,
                        onChanged: (value) {
                          if (value != null) onChanged(value);
                        },
                        activeColor: theme.colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (!isLast)
              Divider(
                height: 1,
                thickness: 1,
                indent: 4.w,
                endIndent: 4.w,
                color:
                    isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
              ),
          ],
        );
      }).toList(),
    );
  }
}
