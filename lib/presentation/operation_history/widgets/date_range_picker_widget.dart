import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';

import '../../../core/app_export.dart';
import '../../../widgets/custom_icon_widget.dart';

/// Widget for date range selection in operation history
class DateRangePickerWidget extends StatelessWidget {
  final DateTimeRange? selectedRange;
  final ValueChanged<DateTimeRange?> onRangeChanged;

  const DateRangePickerWidget({
    super.key,
    this.selectedRange,
    required this.onRangeChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
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
            Padding(
              padding: EdgeInsets.all(4.w),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Filter by Date Range',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                  ),
                  SizedBox(height: 3.h),
                  _buildQuickFilters(context),
                  SizedBox(height: 3.h),
                  _buildCustomRange(context),
                  SizedBox(height: 4.h),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            onRangeChanged(null);
                            Navigator.pop(context);
                          },
                          child: const Text('Clear Filter'),
                        ),
                      ),
                      SizedBox(width: 3.w),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Apply'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickFilters(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final quickFilters = [
      {'label': 'Today', 'days': 0},
      {'label': 'Last 7 Days', 'days': 7},
      {'label': 'Last 30 Days', 'days': 30},
      {'label': 'Last 90 Days', 'days': 90},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Filters',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 2.h),
        Wrap(
          spacing: 2.w,
          runSpacing: 1.h,
          children: quickFilters.map((filter) {
            final isSelected = _isQuickFilterSelected(filter['days'] as int);

            return FilterChip(
              selected: isSelected,
              label: Text(filter['label'] as String),
              onSelected: (selected) {
                if (selected) {
                  final days = filter['days'] as int;
                  final end = DateTime.now();
                  final start = days == 0
                      ? DateTime(end.year, end.month, end.day)
                      : end.subtract(Duration(days: days));
                  onRangeChanged(DateTimeRange(start: start, end: end));
                }
              },
              backgroundColor: colorScheme.surface,
              selectedColor: colorScheme.primary,
              checkmarkColor: colorScheme.onPrimary,
              labelStyle: theme.textTheme.labelMedium?.copyWith(
                color:
                    isSelected ? colorScheme.onPrimary : colorScheme.onSurface,
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildCustomRange(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Custom Range',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 2.h),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(4.w),
          decoration: BoxDecoration(
            border: Border.all(
              color: colorScheme.outline.withValues(alpha: 0.3),
            ),
            borderRadius: BorderRadius.circular(2.w),
          ),
          child: InkWell(
            onTap: () => _showDateRangePicker(context),
            child: Row(
              children: [
                CustomIconWidget(
                  iconName: 'calendar_today',
                  color: colorScheme.onSurfaceVariant,
                  size: 5.w,
                ),
                SizedBox(width: 3.w),
                Expanded(
                  child: Text(
                    selectedRange != null
                        ? '${_formatDate(selectedRange!.start)} - ${_formatDate(selectedRange!.end)}'
                        : 'Select date range',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: selectedRange != null
                          ? colorScheme.onSurface
                          : colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                CustomIconWidget(
                  iconName: 'arrow_drop_down',
                  color: colorScheme.onSurfaceVariant,
                  size: 5.w,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool _isQuickFilterSelected(int days) {
    if (selectedRange == null) return false;

    final now = DateTime.now();
    final expectedStart = days == 0
        ? DateTime(now.year, now.month, now.day)
        : now.subtract(Duration(days: days));

    return selectedRange!.start.isAtSameMomentAs(expectedStart) ||
        (selectedRange!.start.difference(expectedStart).inDays.abs() <= 1);
  }

  Future<void> _showDateRangePicker(BuildContext context) async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now(),
      initialDateRange: selectedRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: Theme.of(context).colorScheme.primary,
                ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      onRangeChanged(picked);
    }
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}
