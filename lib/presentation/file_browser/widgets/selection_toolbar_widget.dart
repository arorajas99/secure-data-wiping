import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class SelectionToolbarWidget extends StatelessWidget {
  final int selectedCount;
  final bool isVisible;
  final VoidCallback? onSelectAll;
  final VoidCallback? onClearSelection;
  final VoidCallback? onAddToWipeList;
  final VoidCallback? onMarkAsSafe;

  const SelectionToolbarWidget({
    super.key,
    required this.selectedCount,
    required this.isVisible,
    this.onSelectAll,
    this.onClearSelection,
    this.onAddToWipeList,
    this.onMarkAsSafe,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isVisible ? 12.h : 0,
      child: isVisible
          ? Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outline.withValues(alpha: 0.3),
                    width: 1.0,
                  ),
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.08)
                        : Colors.black.withValues(alpha: 0.08),
                    offset: const Offset(0, -2),
                    blurRadius: 8,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: SafeArea(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
                  child: Column(
                    children: [
                      // Selection info and controls
                      Row(
                        children: [
                          Text(
                            '$selectedCount selected',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: colorScheme.onSurface,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const Spacer(),
                          TextButton(
                            onPressed: onSelectAll,
                            child: Text(
                              'Select All',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colorScheme.primary,
                              ),
                            ),
                          ),
                          SizedBox(width: 2.w),
                          TextButton(
                            onPressed: onClearSelection,
                            child: Text(
                              'Clear',
                              style: theme.textTheme.labelLarge?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: 1.h),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  selectedCount > 0 ? onAddToWipeList : null,
                              icon: CustomIconWidget(
                                iconName: 'delete_outline',
                                color: selectedCount > 0
                                    ? colorScheme.onError
                                    : colorScheme.onSurface
                                        .withValues(alpha: 0.38),
                                size: 5.w,
                              ),
                              label: Text(
                                'Add to Wipe List',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: selectedCount > 0
                                      ? colorScheme.onError
                                      : colorScheme.onSurface
                                          .withValues(alpha: 0.38),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: selectedCount > 0
                                    ? (isDark
                                        ? AppTheme.darkTheme.colorScheme.error
                                        : AppTheme.lightTheme.colorScheme.error)
                                    : colorScheme.surface,
                                foregroundColor: selectedCount > 0
                                    ? colorScheme.onError
                                    : colorScheme.onSurface
                                        .withValues(alpha: 0.38),
                                elevation: selectedCount > 0 ? 2.0 : 0,
                                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  side: BorderSide(
                                    color: selectedCount > 0
                                        ? Colors.transparent
                                        : colorScheme.outline
                                            .withValues(alpha: 0.3),
                                    width: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed:
                                  selectedCount > 0 ? onMarkAsSafe : null,
                              icon: CustomIconWidget(
                                iconName: 'shield_outlined',
                                color: selectedCount > 0
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurface
                                        .withValues(alpha: 0.38),
                                size: 5.w,
                              ),
                              label: Text(
                                'Mark as Safe',
                                style: theme.textTheme.labelLarge?.copyWith(
                                  color: selectedCount > 0
                                      ? colorScheme.onPrimary
                                      : colorScheme.onSurface
                                          .withValues(alpha: 0.38),
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: selectedCount > 0
                                    ? AppTheme.lightTheme.colorScheme.tertiary
                                    : colorScheme.surface,
                                foregroundColor: selectedCount > 0
                                    ? colorScheme.onPrimary
                                    : colorScheme.onSurface
                                        .withValues(alpha: 0.38),
                                elevation: selectedCount > 0 ? 2.0 : 0,
                                padding: EdgeInsets.symmetric(vertical: 1.5.h),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8.0),
                                  side: BorderSide(
                                    color: selectedCount > 0
                                        ? Colors.transparent
                                        : colorScheme.outline
                                            .withValues(alpha: 0.3),
                                    width: 1.0,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            )
          : const SizedBox.shrink(),
    );
  }
}
