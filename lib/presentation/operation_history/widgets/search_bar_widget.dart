import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Widget for search functionality in operation history
class SearchBarWidget extends StatefulWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback? onDateRangePressed;

  const SearchBarWidget({
    super.key,
    required this.searchQuery,
    required this.onSearchChanged,
    this.onDateRangePressed,
  });

  @override
  State<SearchBarWidget> createState() => _SearchBarWidgetState();
}

class _SearchBarWidgetState extends State<SearchBarWidget> {
  late TextEditingController _searchController;
  bool _isSearchActive = false;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(text: widget.searchQuery);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w, vertical: 1.h),
      child: Row(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: colorScheme.surface,
                borderRadius: BorderRadius.circular(3.w),
                border: Border.all(
                  color: _isSearchActive
                      ? colorScheme.primary
                      : (isDark
                          ? const Color(0xFF374151)
                          : const Color(0xFFE5E7EB)),
                  width: _isSearchActive ? 2 : 1,
                ),
                boxShadow: _isSearchActive
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.1),
                          offset: const Offset(0, 2),
                          blurRadius: 8,
                          spreadRadius: 0,
                        ),
                      ]
                    : null,
              ),
              child: TextField(
                controller: _searchController,
                onChanged: widget.onSearchChanged,
                onTap: () => setState(() => _isSearchActive = true),
                onEditingComplete: () =>
                    setState(() => _isSearchActive = false),
                decoration: InputDecoration(
                  hintText: 'Search by device, date, or status...',
                  hintStyle: theme.textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant.withValues(alpha: 0.6),
                  ),
                  prefixIcon: Padding(
                    padding: EdgeInsets.all(3.w),
                    child: CustomIconWidget(
                      iconName: 'search',
                      color: _isSearchActive
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
                      size: 5.w,
                    ),
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            _searchController.clear();
                            widget.onSearchChanged('');
                            setState(() => _isSearchActive = false);
                          },
                          icon: CustomIconWidget(
                            iconName: 'clear',
                            color: colorScheme.onSurfaceVariant,
                            size: 5.w,
                          ),
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: 4.w,
                    vertical: 2.h,
                  ),
                ),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ),
          SizedBox(width: 3.w),
          Container(
            decoration: BoxDecoration(
              color: colorScheme.surface,
              borderRadius: BorderRadius.circular(3.w),
              border: Border.all(
                color:
                    isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
                width: 1,
              ),
            ),
            child: IconButton(
              onPressed: widget.onDateRangePressed,
              icon: CustomIconWidget(
                iconName: 'date_range',
                color: colorScheme.onSurfaceVariant,
                size: 5.w,
              ),
              tooltip: 'Filter by date range',
            ),
          ),
        ],
      ),
    );
  }
}
