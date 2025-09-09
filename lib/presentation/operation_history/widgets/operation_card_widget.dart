import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

/// Widget for displaying individual operation history cards
class OperationCardWidget extends StatelessWidget {
  final Map<String, dynamic> operation;
  final VoidCallback? onTap;
  final VoidCallback? onGenerateReport;
  final VoidCallback? onShareSummary;
  final VoidCallback? onRepeatOperation;
  final VoidCallback? onExportDetails;
  final VoidCallback? onDeleteRecord;
  final VoidCallback? onAddNotes;

  const OperationCardWidget({
    super.key,
    required this.operation,
    this.onTap,
    this.onGenerateReport,
    this.onShareSummary,
    this.onRepeatOperation,
    this.onExportDetails,
    this.onDeleteRecord,
    this.onAddNotes,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Slidable(
        key: ValueKey(operation['id']),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          children: [
            SlidableAction(
              onPressed: (_) => onGenerateReport?.call(),
              backgroundColor: AppTheme.lightTheme.colorScheme.secondary,
              foregroundColor: Colors.white,
              icon: Icons.description,
              label: 'Report',
              borderRadius: BorderRadius.circular(2.w),
            ),
            SlidableAction(
              onPressed: (_) => onShareSummary?.call(),
              backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
              foregroundColor: Colors.white,
              icon: Icons.share,
              label: 'Share',
              borderRadius: BorderRadius.circular(2.w),
            ),
            SlidableAction(
              onPressed: (_) => onRepeatOperation?.call(),
              backgroundColor: colorScheme.primary,
              foregroundColor: Colors.white,
              icon: Icons.refresh,
              label: 'Repeat',
              borderRadius: BorderRadius.circular(2.w),
            ),
          ],
        ),
        child: GestureDetector(
          onTap: onTap,
          onLongPress: () => _showContextMenu(context),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.all(4.w),
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(3.w),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.05)
                      : Colors.black.withValues(alpha: 0.05),
                  offset: const Offset(0, 2),
                  blurRadius: 8,
                  spreadRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(context),
                SizedBox(height: 2.h),
                _buildSummaryStats(context),
                SizedBox(height: 2.h),
                _buildStatusIndicator(context),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(2.w),
          decoration: BoxDecoration(
            color: _getStatusColor(context).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(2.w),
          ),
          child: CustomIconWidget(
            iconName: _getStatusIcon(),
            color: _getStatusColor(context),
            size: 5.w,
          ),
        ),
        SizedBox(width: 3.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                operation['deviceName'] as String,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: colorScheme.onSurface,
                ),
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 0.5.h),
              Text(
                _formatDateTime(operation['timestamp'] as DateTime),
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: _getStatusColor(context).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4.w),
          ),
          child: Text(
            _getStatusText(),
            style: theme.textTheme.labelSmall?.copyWith(
              color: _getStatusColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryStats(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: _buildStatItem(
            context,
            'Files',
            '${operation['filesCount']}',
            Icons.description_outlined,
          ),
        ),
        Container(
          width: 1,
          height: 4.h,
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
        Expanded(
          child: _buildStatItem(
            context,
            'Size',
            operation['totalSize'] as String,
            Icons.storage_outlined,
          ),
        ),
        Container(
          width: 1,
          height: 4.h,
          color: colorScheme.outline.withValues(alpha: 0.3),
        ),
        Expanded(
          child: _buildStatItem(
            context,
            'Duration',
            operation['duration'] as String,
            Icons.timer_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildStatItem(
      BuildContext context, String label, String value, IconData icon) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      children: [
        CustomIconWidget(
          iconName: icon.codePoint.toString(),
          color: colorScheme.onSurfaceVariant,
          size: 4.w,
        ),
        SizedBox(height: 0.5.h),
        Text(
          value,
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
        ),
        Text(
          label,
          style: theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildStatusIndicator(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 3.w, vertical: 1.h),
          decoration: BoxDecoration(
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(2.w),
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CustomIconWidget(
                iconName: 'security',
                color: colorScheme.onSurfaceVariant,
                size: 3.w,
              ),
              SizedBox(width: 1.w),
              Text(
                operation['securityLevel'] as String,
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        if (operation['hasNotes'] == true)
          Container(
            padding: EdgeInsets.all(1.w),
            decoration: BoxDecoration(
              color: AppTheme.lightTheme.colorScheme.tertiary
                  .withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(1.w),
            ),
            child: CustomIconWidget(
              iconName: 'note',
              color: AppTheme.lightTheme.colorScheme.tertiary,
              size: 3.w,
            ),
          ),
      ],
    );
  }

  void _showContextMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(5.w)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 10.w,
                height: 0.5.h,
                margin: EdgeInsets.symmetric(vertical: 2.h),
                decoration: BoxDecoration(
                  color: Theme.of(context)
                      .colorScheme
                      .onSurfaceVariant
                      .withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(1.w),
                ),
              ),
              _buildContextMenuItem(
                context,
                'Export Details',
                Icons.file_download_outlined,
                onExportDetails,
              ),
              _buildContextMenuItem(
                context,
                'Delete Record',
                Icons.delete_outline,
                onDeleteRecord,
                isDestructive: true,
              ),
              _buildContextMenuItem(
                context,
                'Add Notes',
                Icons.note_add_outlined,
                onAddNotes,
              ),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContextMenuItem(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback? onTap, {
    bool isDestructive = false,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final color = isDestructive ? colorScheme.error : colorScheme.onSurface;

    return ListTile(
      leading: CustomIconWidget(
        iconName: icon.codePoint.toString(),
        color: color,
        size: 5.w,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: color,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        Navigator.pop(context);
        onTap?.call();
      },
    );
  }

  String _getStatusIcon() {
    switch (operation['status']) {
      case 'success':
        return 'check_circle';
      case 'partial':
        return 'warning';
      case 'failed':
        return 'error';
      default:
        return 'help';
    }
  }

  Color _getStatusColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    switch (operation['status']) {
      case 'success':
        return isDark ? const Color(0xFF10B981) : const Color(0xFF2D7D32);
      case 'partial':
        return isDark ? const Color(0xFFF59E0B) : const Color(0xFFE17B47);
      case 'failed':
        return isDark ? const Color(0xFFEF4444) : const Color(0xFFC5282F);
      default:
        return Theme.of(context).colorScheme.onSurfaceVariant;
    }
  }

  String _getStatusText() {
    switch (operation['status']) {
      case 'success':
        return 'Complete';
      case 'partial':
        return 'Partial';
      case 'failed':
        return 'Failed';
      default:
        return 'Unknown';
    }
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays == 0) {
      final hour = dateTime.hour;
      final minute = dateTime.minute.toString().padLeft(2, '0');
      final period = hour >= 12 ? 'PM' : 'AM';
      final displayHour = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
      return '$displayHour:$minute $period';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${dateTime.month}/${dateTime.day}/${dateTime.year}';
    }
  }
}
