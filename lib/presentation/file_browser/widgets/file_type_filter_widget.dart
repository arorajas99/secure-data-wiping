import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class FileTypeFilterWidget extends StatelessWidget {
  final String selectedFilter;
  final ValueChanged<String> onFilterChanged;
  final bool isVisible;

  const FileTypeFilterWidget({
    super.key,
    required this.selectedFilter,
    required this.onFilterChanged,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final filters = [
      {'key': 'all', 'label': 'All Files', 'icon': 'folder_open'},
      {'key': 'documents', 'label': 'Documents', 'icon': 'description'},
      {'key': 'images', 'label': 'Images', 'icon': 'image'},
      {'key': 'videos', 'label': 'Videos', 'icon': 'video_file'},
      {'key': 'audio', 'label': 'Audio', 'icon': 'audio_file'},
      {'key': 'apps', 'label': 'Apps', 'icon': 'android'},
    ];

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      height: isVisible ? 8.h : 0,
      child: isVisible
          ? Container(
              padding: EdgeInsets.symmetric(vertical: 1.h),
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 4.w),
                itemCount: filters.length,
                separatorBuilder: (context, index) => SizedBox(width: 2.w),
                itemBuilder: (context, index) {
                  final filter = filters[index];
                  final isSelected = selectedFilter == filter['key'];

                  return _buildFilterChip(
                    context,
                    filter['key']!,
                    filter['label']!,
                    filter['icon']!,
                    isSelected,
                    colorScheme,
                    theme,
                  );
                },
              ),
            )
          : const SizedBox.shrink(),
    );
  }

  Widget _buildFilterChip(
    BuildContext context,
    String key,
    String label,
    String iconName,
    bool isSelected,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onFilterChanged(key),
        borderRadius: BorderRadius.circular(20.0),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: isSelected ? colorScheme.primary : colorScheme.surface,
            borderRadius: BorderRadius.circular(20.0),
            border: Border.all(
              color: isSelected
                  ? colorScheme.primary
                  : colorScheme.outline.withValues(alpha: 0.3),
              width: 1.0,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: colorScheme.primary.withValues(alpha: 0.3),
                      offset: const Offset(0, 2),
                      blurRadius: 8,
                      spreadRadius: 0,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomIconWidget(
                iconName: iconName,
                color: isSelected
                    ? colorScheme.onPrimary
                    : colorScheme.onSurfaceVariant,
                size: 4.w,
              ),
              SizedBox(width: 2.w),
              Text(
                label,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isSelected
                      ? colorScheme.onPrimary
                      : colorScheme.onSurfaceVariant,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
