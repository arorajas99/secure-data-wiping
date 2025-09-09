import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';


class AccountInfoWidget extends StatelessWidget {
  final Map<String, dynamic> userInfo;

  const AccountInfoWidget({
    super.key,
    required this.userInfo,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(4.w),
      child: Row(
        children: [
          Container(
            width: 15.w,
            height: 15.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.primary.withValues(alpha: 0.1),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.2),
                width: 2,
              ),
            ),
            child: Center(
              child: Text(
                (userInfo["name"] as String).substring(0, 1).toUpperCase(),
                style: theme.textTheme.titleLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
          SizedBox(width: 4.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  userInfo["name"] as String,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                SizedBox(height: 0.5.h),
                Text(
                  userInfo["email"] as String,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark
                        ? const Color(0xFF9CA3AF)
                        : const Color(0xFF6B7280),
                  ),
                ),
                SizedBox(height: 0.5.h),
                Container(
                  padding:
                      EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                  decoration: BoxDecoration(
                    color: userInfo["isPremium"] == true
                        ? (isDark
                                ? const Color(0xFFA78BFA)
                                : const Color(0xFF8B5CF6))
                            .withValues(alpha: 0.1)
                        : (isDark
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF6B7280))
                            .withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    userInfo["isPremium"] == true ? "Premium" : "Free",
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: userInfo["isPremium"] == true
                          ? (isDark
                              ? const Color(0xFFA78BFA)
                              : const Color(0xFF8B5CF6))
                          : (isDark
                              ? const Color(0xFF9CA3AF)
                              : const Color(0xFF6B7280)),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
