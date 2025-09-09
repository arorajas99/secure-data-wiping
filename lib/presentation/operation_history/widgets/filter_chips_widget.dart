import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Widget for displaying filter chips in operation history
class FilterChipsWidget extends StatelessWidget {
  final List<String> selectedFilters;
  final ValueChanged<String> onFilterToggle;

  const FilterChipsWidget({
    super.key,
    required this.selectedFilters,
    required this.onFilterToggle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filters = [
      {'key': 'last7days', 'label': 'Last 7 Days', 'icon': 'calendar_today'},
      {'key': 'successful', 'label': 'Successful Only', 'icon': 'check_circle'},
      {'key': 'failed', 'label': 'Failed Operations', 'icon': 'error'},
      {'key': 'partial', 'label': 'Partial', 'icon': 'warning'},
    ];

    return Container(
      height: 6.h,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: filters.length,
        separatorBuilder: (context, index) => SizedBox(width: 2.w),
        itemBuilder: (context, index) {
          final filter = filters[index];
          final isSelected = selectedFilters.contains(filter['key']);

          return FilterChip(
            selected: isSelected,
            label: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CustomIconWidget(
                  iconName: filter['icon']!,
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                  size: 3.5.w,
                ),
                SizedBox(width: 1.w),
                Text(
                  filter['label']!,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? colorScheme.onPrimary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
            onSelected: (selected) => onFilterToggle(filter['key']!),
            backgroundColor: colorScheme.surface,
            selectedColor: colorScheme.primary,
            checkmarkColor: colorScheme.onPrimary,
            side: BorderSide(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.3),
              width: 1,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5.w),
            ),
            padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          );
        },
      ),
    );
  }
}
