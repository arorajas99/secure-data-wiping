import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/date_range_picker_widget.dart';
import './widgets/empty_state_widget.dart';
import './widgets/filter_chips_widget.dart';
import './widgets/operation_card_widget.dart';
import './widgets/search_bar_widget.dart';

/// Operation History Screen for SecureWipe Pro
/// Displays chronological list of all deletion operations with detailed reporting
class OperationHistory extends StatefulWidget {
  const OperationHistory({super.key});

  @override
  State<OperationHistory> createState() => _OperationHistoryState();
}

class _OperationHistoryState extends State<OperationHistory>
    with TickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  List<String> _selectedFilters = [];
  DateTimeRange? _selectedDateRange;
  bool _isLoading = false;

  // Mock operation history data
  final List<Map<String, dynamic>> _allOperations = [
    {
      "id": 1,
      "deviceName": "Samsung Galaxy S23",
      "timestamp": DateTime.now().subtract(const Duration(hours: 2)),
      "filesCount": 1247,
      "totalSize": "2.4 GB",
      "duration": "12m 34s",
      "status": "success",
      "securityLevel": "Military Grade",
      "hasNotes": true,
      "operationType": "Full Device Wipe",
      "completionPercentage": 100,
    },
    {
      "id": 2,
      "deviceName": "iPhone 14 Pro",
      "timestamp": DateTime.now().subtract(const Duration(days: 1)),
      "filesCount": 892,
      "totalSize": "1.8 GB",
      "duration": "8m 45s",
      "status": "partial",
      "securityLevel": "Standard",
      "hasNotes": false,
      "operationType": "Selected Files",
      "completionPercentage": 87,
    },
    {
      "id": 3,
      "deviceName": "External SSD Drive",
      "timestamp": DateTime.now().subtract(const Duration(days: 3)),
      "filesCount": 2156,
      "totalSize": "4.7 GB",
      "duration": "25m 12s",
      "status": "failed",
      "securityLevel": "Secure",
      "hasNotes": true,
      "operationType": "External Storage",
      "completionPercentage": 23,
    },
    {
      "id": 4,
      "deviceName": "OnePlus 11",
      "timestamp": DateTime.now().subtract(const Duration(days: 5)),
      "filesCount": 567,
      "totalSize": "890 MB",
      "duration": "4m 18s",
      "status": "success",
      "securityLevel": "Quick",
      "hasNotes": false,
      "operationType": "Cache & Temp Files",
      "completionPercentage": 100,
    },
    {
      "id": 5,
      "deviceName": "MacBook Pro SSD",
      "timestamp": DateTime.now().subtract(const Duration(days: 7)),
      "filesCount": 3421,
      "totalSize": "8.2 GB",
      "duration": "45m 07s",
      "status": "success",
      "securityLevel": "DoD 5220.22-M",
      "hasNotes": true,
      "operationType": "Full Drive Wipe",
      "completionPercentage": 100,
    },
  ];

  List<Map<String, dynamic>> _filteredOperations = [];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _filteredOperations = List.from(_allOperations);
    _applyFilters();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: _buildAppBar(context),
      body: Column(
        children: [
          _buildTabBar(context),
          SearchBarWidget(
            searchQuery: _searchQuery,
            onSearchChanged: _onSearchChanged,
            onDateRangePressed: _showDateRangePicker,
          ),
          FilterChipsWidget(
            selectedFilters: _selectedFilters,
            onFilterToggle: _onFilterToggle,
          ),
          Expanded(
            child: _buildBody(context),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(context),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AppBar(
      title: Text(
        'Operation History',
        style: theme.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
          color: colorScheme.onSurface,
        ),
      ),
      backgroundColor: colorScheme.surface,
      foregroundColor: colorScheme.onSurface,
      elevation: 1,
      leading: IconButton(
        onPressed: () => Navigator.pushNamed(context, '/main-dashboard'),
        icon: CustomIconWidget(
          iconName: 'arrow_back',
          color: colorScheme.onSurface,
          size: 6.w,
        ),
        tooltip: 'Back to Dashboard',
      ),
      actions: [
        IconButton(
          onPressed: _showFilterOptions,
          icon: CustomIconWidget(
            iconName: 'filter_list',
            color: colorScheme.onSurface,
            size: 6.w,
          ),
          tooltip: 'Filter Options',
        ),
        IconButton(
          onPressed: _showExportOptions,
          icon: CustomIconWidget(
            iconName: 'file_download',
            color: colorScheme.onSurface,
            size: 6.w,
          ),
          tooltip: 'Export History',
        ),
      ],
    );
  }

  Widget _buildTabBar(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      color: colorScheme.surface,
      child: TabBar(
        controller: _tabController,
        onTap: _onTabChanged,
        tabs: const [
          Tab(text: 'All'),
          Tab(text: 'Completed'),
          Tab(text: 'Failed'),
          Tab(text: 'In Progress'),
        ],
        labelColor: colorScheme.primary,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        indicatorColor: colorScheme.primary,
        labelStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: theme.textTheme.labelLarge?.copyWith(
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_filteredOperations.isEmpty) {
      return _searchQuery.isNotEmpty || _selectedFilters.isNotEmpty
          ? _buildNoResultsFound(context)
          : EmptyStateWidget(
              onStartFirstWipe: () =>
                  Navigator.pushNamed(context, '/file-browser'),
            );
    }

    return RefreshIndicator(
      onRefresh: _refreshHistory,
      child: ListView.builder(
        padding: EdgeInsets.only(
          top: 1.h,
          bottom: 10.h, // Space for FAB
        ),
        itemCount: _filteredOperations.length,
        itemBuilder: (context, index) {
          final operation = _filteredOperations[index];
          return OperationCardWidget(
            operation: operation,
            onTap: () => _showOperationDetails(operation),
            onGenerateReport: () => _generateReport(operation),
            onShareSummary: () => _shareSummary(operation),
            onRepeatOperation: () => _repeatOperation(operation),
            onExportDetails: () => _exportDetails(operation),
            onDeleteRecord: () => _deleteRecord(operation),
            onAddNotes: () => _addNotes(operation),
          );
        },
      ),
    );
  }

  Widget _buildNoResultsFound(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(8.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 25.w,
              height: 25.w,
              decoration: BoxDecoration(
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12.5.w),
              ),
              child: Center(
                child: CustomIconWidget(
                  iconName: 'search_off',
                  color: colorScheme.onSurfaceVariant,
                  size: 12.w,
                ),
              ),
            ),
            SizedBox(height: 3.h),
            Text(
              'No results found',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: colorScheme.onSurface,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 1.h),
            Text(
              'Try adjusting your search or filters',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            SizedBox(height: 4.h),
            OutlinedButton(
              onPressed: _clearAllFilters,
              child: const Text('Clear Filters'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFloatingActionButton(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FloatingActionButton.extended(
      onPressed: () => Navigator.pushNamed(context, '/file-browser'),
      icon: CustomIconWidget(
        iconName: 'add',
        color: colorScheme.onPrimary,
        size: 5.w,
      ),
      label: Text(
        'New Operation',
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: colorScheme.onPrimary,
              fontWeight: FontWeight.w600,
            ),
      ),
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
    );
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _applyFilters();
  }

  void _onFilterToggle(String filter) {
    setState(() {
      if (_selectedFilters.contains(filter)) {
        _selectedFilters.remove(filter);
      } else {
        _selectedFilters.add(filter);
      }
    });
    _applyFilters();
  }

  void _onTabChanged(int index) {
    // Handle tab changes for status filtering
    _applyFilters();
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_allOperations);

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((operation) {
        final deviceName = (operation['deviceName'] as String).toLowerCase();
        final status = (operation['status'] as String).toLowerCase();
        final securityLevel =
            (operation['securityLevel'] as String).toLowerCase();
        final query = _searchQuery.toLowerCase();

        return deviceName.contains(query) ||
            status.contains(query) ||
            securityLevel.contains(query);
      }).toList();
    }

    // Apply chip filters
    for (String filter in _selectedFilters) {
      switch (filter) {
        case 'last7days':
          final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
          filtered = filtered.where((operation) {
            return (operation['timestamp'] as DateTime).isAfter(sevenDaysAgo);
          }).toList();
          break;
        case 'successful':
          filtered = filtered.where((operation) {
            return operation['status'] == 'success';
          }).toList();
          break;
        case 'failed':
          filtered = filtered.where((operation) {
            return operation['status'] == 'failed';
          }).toList();
          break;
        case 'partial':
          filtered = filtered.where((operation) {
            return operation['status'] == 'partial';
          }).toList();
          break;
      }
    }

    // Apply date range filter
    if (_selectedDateRange != null) {
      filtered = filtered.where((operation) {
        final timestamp = operation['timestamp'] as DateTime;
        return timestamp.isAfter(_selectedDateRange!.start) &&
            timestamp
                .isBefore(_selectedDateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    // Apply tab filter
    switch (_tabController.index) {
      case 1: // Completed
        filtered = filtered
            .where((operation) => operation['status'] == 'success')
            .toList();
        break;
      case 2: // Failed
        filtered = filtered
            .where((operation) => operation['status'] == 'failed')
            .toList();
        break;
      case 3: // In Progress (none in mock data)
        filtered = filtered
            .where((operation) => operation['status'] == 'in_progress')
            .toList();
        break;
    }

    setState(() {
      _filteredOperations = filtered;
    });
  }

  void _clearAllFilters() {
    setState(() {
      _searchQuery = '';
      _selectedFilters.clear();
      _selectedDateRange = null;
      _tabController.index = 0;
    });
    _applyFilters();
  }

  Future<void> _refreshHistory() async {
    setState(() {
      _isLoading = true;
    });

    // Simulate network delay
    await Future.delayed(const Duration(seconds: 1));

    // Provide haptic feedback
    HapticFeedback.lightImpact();

    setState(() {
      _isLoading = false;
    });

    _applyFilters();
  }

  void _showDateRangePicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => DateRangePickerWidget(
        selectedRange: _selectedDateRange,
        onRangeChanged: (range) {
          setState(() {
            _selectedDateRange = range;
          });
          _applyFilters();
        },
      ),
    );
  }

  void _showFilterOptions() {
    // Implementation for additional filter options
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Filter options coming soon')),
    );
  }

  void _showExportOptions() {
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
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'description',
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 6.w,
                ),
                title: const Text('Export as CSV'),
                onTap: () {
                  Navigator.pop(context);
                  _exportAsCSV();
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'picture_as_pdf',
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 6.w,
                ),
                title: const Text('Export as PDF'),
                onTap: () {
                  Navigator.pop(context);
                  _exportAsPDF();
                },
              ),
              ListTile(
                leading: CustomIconWidget(
                  iconName: 'code',
                  color: Theme.of(context).colorScheme.onSurface,
                  size: 6.w,
                ),
                title: const Text('Export as JSON'),
                onTap: () {
                  Navigator.pop(context);
                  _exportAsJSON();
                },
              ),
              SizedBox(height: 2.h),
            ],
          ),
        ),
      ),
    );
  }

  void _showOperationDetails(Map<String, dynamic> operation) {
    Navigator.pushNamed(
      context,
      '/operation-details',
      arguments: operation,
    );
  }

  void _generateReport(Map<String, dynamic> operation) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating report for ${operation['deviceName']}...'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {},
        ),
      ),
    );
  }

  void _shareSummary(Map<String, dynamic> operation) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing summary for ${operation['deviceName']}...'),
      ),
    );
  }

  void _repeatOperation(Map<String, dynamic> operation) {
    Navigator.pushNamed(context, '/confirmation-dialog', arguments: {
      'operation': operation,
      'type': 'repeat',
    });
  }

  void _exportDetails(Map<String, dynamic> operation) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Exporting details for ${operation['deviceName']}...'),
      ),
    );
  }

  void _deleteRecord(Map<String, dynamic> operation) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record'),
        content: Text(
            'Are you sure you want to delete the operation record for ${operation['deviceName']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _allOperations.removeWhere((op) => op['id'] == operation['id']);
              });
              _applyFilters();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Operation record deleted')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _addNotes(Map<String, dynamic> operation) {
    final TextEditingController notesController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Notes'),
        content: TextField(
          controller: notesController,
          decoration: const InputDecoration(
            hintText: 'Enter your notes...',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                operation['hasNotes'] = true;
                operation['notes'] = notesController.text;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Notes added successfully')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _exportAsCSV() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting history as CSV...')),
    );
  }

  void _exportAsPDF() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting history as PDF...')),
    );
  }

  void _exportAsJSON() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Exporting history as JSON...')),
    );
  }
}
