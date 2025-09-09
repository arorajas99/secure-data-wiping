import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

class SelectedItemsSummaryWidget extends StatelessWidget {
  final List<Map<String, dynamic>> selectedItems;
  final int totalFileCount;
  final String totalSize;

  const SelectedItemsSummaryWidget({
    super.key,
    required this.selectedItems,
    required this.totalFileCount,
    required this.totalSize,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(2.w),
        border: Border.all(
          color: colorScheme.outline.withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Selected Items Summary',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          SizedBox(height: 3.w),
          _buildItemsList(context),
          SizedBox(height: 3.w),
          _buildSummaryStats(context),
        ],
      ),
    );
  }

  Widget _buildItemsList(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final displayItems = selectedItems.take(5).toList();
    final remainingCount = selectedItems.length - displayItems.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ...displayItems.map((item) => Padding(
              padding: EdgeInsets.only(bottom: 2.w),
              child: Row(
                children: [
                  CustomIconWidget(
                    iconName: _getFileIcon(item['type'] as String? ?? 'file'),
                    color: colorScheme.primary,
                    size: 4.w,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['name'] as String? ?? 'Unknown File',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (item['size'] != null) ...[
                          SizedBox(height: 0.5.w),
                          Text(
                            item['size'] as String,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            )),
        remainingCount > 0
            ? Padding(
                padding: EdgeInsets.only(top: 1.w),
                child: Text(
                  'and $remainingCount more items...',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ],
    );
  }

  Widget _buildSummaryStats(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(3.w),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(1.5.w),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildStatItem(
            context,
            'Total Files',
            totalFileCount.toString(),
            'description',
          ),
          Container(
            width: 1,
            height: 8.w,
            color: colorScheme.outline.withValues(alpha: 0.3),
          ),
          _buildStatItem(
            context,
            'Total Size',
            totalSize,
            'storage',
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
      BuildContext context, String label, String value, String iconName) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Expanded(
      child: Column(
        children: [
          CustomIconWidget(
            iconName: iconName,
            color: colorScheme.primary,
            size: 5.w,
          ),
          SizedBox(height: 1.w),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: colorScheme.onSurface,
            ),
          ),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  String _getFileIcon(String fileType) {
    switch (fileType.toLowerCase()) {
      case 'document':
        return 'description';
      case 'image':
        return 'image';
      case 'video':
        return 'videocam';
      case 'audio':
        return 'audiotrack';
      case 'folder':
        return 'folder';
      case 'app':
        return 'apps';
      default:
        return 'insert_drive_file';
    }
  }
}
