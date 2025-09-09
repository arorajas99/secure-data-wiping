import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class BreadcrumbWidget extends StatelessWidget {
  final List<String> pathSegments;
  final ValueChanged<int> onSegmentTapped;

  const BreadcrumbWidget({
    super.key,
    required this.pathSegments,
    required this.onSegmentTapped,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (pathSegments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      height: 6.h,
      padding: EdgeInsets.symmetric(horizontal: 4.w),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: pathSegments.length,
        separatorBuilder: (context, index) => _buildSeparator(colorScheme),
        itemBuilder: (context, index) {
          final segment = pathSegments[index];
          final isLast = index == pathSegments.length - 1;

          return _buildBreadcrumbItem(
            context,
            segment,
            index,
            isLast,
            colorScheme,
            theme,
          );
        },
      ),
    );
  }

  Widget _buildBreadcrumbItem(
    BuildContext context,
    String segment,
    int index,
    bool isLast,
    ColorScheme colorScheme,
    ThemeData theme,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: isLast ? null : () => onSegmentTapped(index),
        borderRadius: BorderRadius.circular(6.0),
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: isLast
                ? colorScheme.primary.withValues(alpha: 0.1)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6.0),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (index == 0) ...[
                CustomIconWidget(
                  iconName: segment == 'Internal Storage'
                      ? 'phone_android'
                      : 'sd_card',
                  color: isLast
                      ? colorScheme.primary
                      : colorScheme.onSurfaceVariant,
                  size: 4.w,
                ),
                SizedBox(width: 2.w),
              ],
              ConstrainedBox(
                constraints: BoxConstraints(maxWidth: 25.w),
                child: Text(
                  segment,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isLast
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                    fontWeight: isLast ? FontWeight.w500 : FontWeight.w400,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSeparator(ColorScheme colorScheme) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 2.w),
      child: CustomIconWidget(
        iconName: 'chevron_right',
        color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
        size: 4.w,
      ),
    );
  }
}
