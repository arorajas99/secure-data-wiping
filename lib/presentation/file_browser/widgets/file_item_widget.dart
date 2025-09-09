import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';

class FileItemWidget extends StatelessWidget {
  final Map<String, dynamic> fileData;
  final bool isSelected;
  final bool isMultiSelectMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final VoidCallback? onToggleSelect;
  final VoidCallback? onAddToSafe;
  final VoidCallback? onProperties;
  final VoidCallback? onShare;
  final VoidCallback? onDeletePreview;

  const FileItemWidget({
    super.key,
    required this.fileData,
    required this.isSelected,
    required this.isMultiSelectMode,
    required this.onTap,
    required this.onLongPress,
    this.onToggleSelect,
    this.onAddToSafe,
    this.onProperties,
    this.onShare,
    this.onDeletePreview,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    final isFolder = fileData['type'] == 'folder';
    final fileName = fileData['name'] as String;
    final fileSize = fileData['size'] as String? ?? '';
    final lastModified = fileData['lastModified'] as String? ?? '';
    final itemCount = fileData['itemCount'] as int? ?? 0;
    final thumbnailUrl = fileData['thumbnailUrl'] as String?;

    return Slidable(
      key: ValueKey(fileName),
      startActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onAddToSafe?.call(),
            backgroundColor: AppTheme.lightTheme.colorScheme.tertiary,
            foregroundColor: Colors.white,
            icon: Icons.shield_outlined,
            label: 'Safe List',
            borderRadius: BorderRadius.circular(8.0),
          ),
          SlidableAction(
            onPressed: (_) => onProperties?.call(),
            backgroundColor: colorScheme.secondary,
            foregroundColor: Colors.white,
            icon: Icons.info_outline,
            label: 'Properties',
            borderRadius: BorderRadius.circular(8.0),
          ),
          if (!isFolder)
            SlidableAction(
              onPressed: (_) => onShare?.call(),
              backgroundColor: AppTheme.lightTheme.colorScheme.primary,
              foregroundColor: Colors.white,
              icon: Icons.share_outlined,
              label: 'Share',
              borderRadius: BorderRadius.circular(8.0),
            ),
        ],
      ),
      endActionPane: ActionPane(
        motion: const ScrollMotion(),
        children: [
          SlidableAction(
            onPressed: (_) => onDeletePreview?.call(),
            backgroundColor: isDark
                ? AppTheme.darkTheme.colorScheme.error
                : AppTheme.lightTheme.colorScheme.error,
            foregroundColor: Colors.white,
            icon: Icons.delete_outline,
            label: 'Delete Preview',
            borderRadius: BorderRadius.circular(8.0),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          onLongPress: onLongPress,
          borderRadius: BorderRadius.circular(8.0),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 4.w, vertical: 2.h),
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(8.0),
              border: isSelected
                  ? Border.all(color: colorScheme.primary, width: 1.0)
                  : null,
            ),
            child: Row(
              children: [
                // Selection checkbox (appears in multi-select mode)
                if (isMultiSelectMode) ...[
                  SizedBox(
                    width: 6.w,
                    height: 6.w,
                    child: Checkbox(
                      value: isSelected,
                      onChanged: (_) => onToggleSelect?.call(),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4.0),
                      ),
                    ),
                  ),
                  SizedBox(width: 3.w),
                ],

                // File/Folder icon or thumbnail
                _buildFileIcon(context, isFolder, fileName, thumbnailUrl),
                SizedBox(width: 3.w),

                // File information
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        fileName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: colorScheme.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 0.5.h),
                      Row(
                        children: [
                          if (isFolder) ...[
                            Text(
                              '$itemCount items',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ] else ...[
                            Text(
                              fileSize,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                            if (fileSize.isNotEmpty &&
                                lastModified.isNotEmpty) ...[
                              Text(
                                ' • ',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                            Expanded(
                              child: Text(
                                lastModified,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Item count badge for folders
                if (isFolder && itemCount > 0)
                  Container(
                    padding:
                        EdgeInsets.symmetric(horizontal: 2.w, vertical: 0.5.h),
                    decoration: BoxDecoration(
                      color: colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                    child: Text(
                      itemCount.toString(),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFileIcon(BuildContext context, bool isFolder, String fileName,
      String? thumbnailUrl) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (isFolder) {
      return Container(
        width: 12.w,
        height: 12.w,
        decoration: BoxDecoration(
          color: colorScheme.primary.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8.0),
        ),
        child: CustomIconWidget(
          iconName: 'folder',
          color: colorScheme.primary,
          size: 6.w,
        ),
      );
    }

    // Show thumbnail if available
    if (thumbnailUrl != null && thumbnailUrl.isNotEmpty) {
      return Container(
        width: 12.w,
        height: 12.w,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8.0),
          border: Border.all(
            color: colorScheme.outline.withValues(alpha: 0.3),
            width: 1.0,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(7.0),
          child: CustomImageWidget(
            imageUrl: thumbnailUrl,
            width: 12.w,
            height: 12.w,
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    // File type specific icons
    final extension = fileName.split('.').last.toLowerCase();
    String iconName;
    Color iconColor;

    switch (extension) {
      case 'pdf':
        iconName = 'picture_as_pdf';
        iconColor = const Color(0xFFE53E3E);
        break;
      case 'doc':
      case 'docx':
        iconName = 'description';
        iconColor = const Color(0xFF2B6CB0);
        break;
      case 'xls':
      case 'xlsx':
        iconName = 'table_chart';
        iconColor = const Color(0xFF38A169);
        break;
      case 'ppt':
      case 'pptx':
        iconName = 'slideshow';
        iconColor = const Color(0xFFD69E2E);
        break;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
      case 'bmp':
        iconName = 'image';
        iconColor = const Color(0xFF805AD5);
        break;
      case 'mp4':
      case 'avi':
      case 'mov':
      case 'mkv':
        iconName = 'video_file';
        iconColor = const Color(0xFFE53E3E);
        break;
      case 'mp3':
      case 'wav':
      case 'flac':
      case 'aac':
        iconName = 'audio_file';
        iconColor = const Color(0xFF38A169);
        break;
      case 'zip':
      case 'rar':
      case '7z':
        iconName = 'archive';
        iconColor = const Color(0xFF718096);
        break;
      case 'txt':
        iconName = 'text_snippet';
        iconColor = colorScheme.onSurfaceVariant;
        break;
      case 'apk':
        iconName = 'android';
        iconColor = const Color(0xFF38A169);
        break;
      default:
        iconName = 'insert_drive_file';
        iconColor = colorScheme.onSurfaceVariant;
    }

    return Container(
      width: 12.w,
      height: 12.w,
      decoration: BoxDecoration(
        color: iconColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8.0),
      ),
      child: CustomIconWidget(
        iconName: iconName,
        color: iconColor,
        size: 6.w,
      ),
    );
  }
}
