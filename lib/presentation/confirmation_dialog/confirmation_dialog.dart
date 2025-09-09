import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_icon_widget.dart';
import './widgets/biometric_auth_widget.dart';
import './widgets/confirmation_input_widget.dart';
import './widgets/critical_warning_widget.dart';
import './widgets/security_level_display_widget.dart';
import './widgets/selected_items_summary_widget.dart';

class ConfirmationDialog extends StatefulWidget {
  const ConfirmationDialog({super.key});

  @override
  State<ConfirmationDialog> createState() => _ConfirmationDialogState();
}

class _ConfirmationDialogState extends State<ConfirmationDialog>
    with TickerProviderStateMixin {
  bool _isTextConfirmed = false;
  bool _isCheckboxConfirmed = false;
  bool _isBiometricAuthenticated = false;
  bool _isProcessing = false;
  late AnimationController _slideController;
  late AnimationController _fadeController;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _fadeAnimation;

  // Mock data for selected items
  final List<Map<String, dynamic>> selectedItems = [
    {
      "name": "Personal_Documents.pdf",
      "type": "document",
      "size": "2.4 MB",
      "path": "/storage/emulated/0/Documents/Personal_Documents.pdf"
    },
    {
      "name": "Family_Photos",
      "type": "folder",
      "size": "156.8 MB",
      "path": "/storage/emulated/0/Pictures/Family_Photos"
    },
    {
      "name": "Banking_App.apk",
      "type": "app",
      "size": "45.2 MB",
      "path": "/data/app/com.bank.mobile"
    },
    {
      "name": "Vacation_Video.mp4",
      "type": "video",
      "size": "234.7 MB",
      "path": "/storage/emulated/0/Movies/Vacation_Video.mp4"
    },
    {
      "name": "Work_Presentation.pptx",
      "type": "document",
      "size": "12.3 MB",
      "path": "/storage/emulated/0/Documents/Work_Presentation.pptx"
    },
    {
      "name": "Music_Collection",
      "type": "folder",
      "size": "1.2 GB",
      "path": "/storage/emulated/0/Music/Collection"
    },
    {
      "name": "Confidential_Report.docx",
      "type": "document",
      "size": "8.9 MB",
      "path": "/storage/emulated/0/Documents/Confidential_Report.docx"
    }
  ];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startEntryAnimation();
  }

  void _initializeAnimations() {
    _slideController = AnimationController(
      duration: const Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _slideController,
      curve: Curves.easeOutCubic,
    ));

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeIn,
    ));
  }

  void _startEntryAnimation() {
    _fadeController.forward();
    Future.delayed(const Duration(milliseconds: 100), () {
      _slideController.forward();
    });
  }

  @override
  void dispose() {
    _slideController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  bool get _canProceed =>
      _isTextConfirmed && _isCheckboxConfirmed && _isBiometricAuthenticated;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return WillPopScope(
      onWillPop: _handleBackPress,
      child: Scaffold(
        backgroundColor: Colors.black.withValues(alpha: 0.5),
        body: FadeTransition(
          opacity: _fadeAnimation,
          child: GestureDetector(
            onTap: _handleBackdropTap,
            child: Container(
              width: double.infinity,
              height: double.infinity,
              child: SlideTransition(
                position: _slideAnimation,
                child: DraggableScrollableSheet(
                  initialChildSize: 0.85,
                  minChildSize: 0.5,
                  maxChildSize: 0.95,
                  builder: (context, scrollController) {
                    return Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surface,
                        borderRadius: BorderRadius.only(
                          topLeft: Radius.circular(6.w),
                          topRight: Radius.circular(6.w),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 20,
                            offset: const Offset(0, -5),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          _buildHeader(context),
                          Expanded(
                            child: _buildContent(context, scrollController),
                          ),
                          _buildBottomActions(context),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: (isDark ? const Color(0xFFEF4444) : const Color(0xFFC5282F))
            .withValues(alpha: 0.1),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(6.w),
          topRight: Radius.circular(6.w),
        ),
        border: Border(
          bottom: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 12.w,
            height: 1.w,
            decoration: BoxDecoration(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(0.5.w),
            ),
          ),
          SizedBox(height: 4.w),
          Row(
            children: [
              CustomIconWidget(
                iconName: 'warning',
                color:
                    isDark ? const Color(0xFFEF4444) : const Color(0xFFC5282F),
                size: 8.w,
              ),
              SizedBox(width: 4.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Confirm Secure Deletion',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      'Final safety checkpoint',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _handleCancel,
                icon: CustomIconWidget(
                  iconName: 'close',
                  color: colorScheme.onSurfaceVariant,
                  size: 6.w,
                ),
                tooltip: 'Cancel',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildContent(
      BuildContext context, ScrollController scrollController) {
    return SingleChildScrollView(
      controller: scrollController,
      padding: EdgeInsets.all(4.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SelectedItemsSummaryWidget(
            selectedItems: selectedItems,
            totalFileCount: selectedItems.length,
            totalSize: _calculateTotalSize(),
          ),
          SizedBox(height: 4.w),
          SecurityLevelDisplayWidget(
            securityLevel: 'Military Grade',
            description:
                'Uses DoD 5220.22-M standard with 7-pass overwrite pattern for maximum security. Data recovery will be impossible.',
            passCount: 7,
          ),
          SizedBox(height: 4.w),
          const CriticalWarningWidget(),
          SizedBox(height: 4.w),
          ConfirmationInputWidget(
            onConfirmationChanged: (isConfirmed) {
              setState(() {
                _isTextConfirmed = isConfirmed;
              });
            },
            onCheckboxChanged: (isChecked) {
              setState(() {
                _isCheckboxConfirmed = isChecked;
              });
            },
          ),
          SizedBox(height: 4.w),
          BiometricAuthWidget(
            onAuthenticationResult: (isAuthenticated) {
              setState(() {
                _isBiometricAuthenticated = isAuthenticated;
              });
            },
            isEnabled: _isTextConfirmed && _isCheckboxConfirmed,
          ),
          SizedBox(height: 8.w), // Extra space for bottom actions
        ],
      ),
    );
  }

  Widget _buildBottomActions(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: colorScheme.outline.withValues(alpha: 0.2),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: OutlinedButton(
                onPressed: _isProcessing ? null : _handleCancel,
                style: OutlinedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 3.5.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2.w),
                  ),
                  side: BorderSide(
                    color: colorScheme.outline,
                    width: 1,
                  ),
                ),
                child: Text(
                  'Cancel',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            SizedBox(width: 4.w),
            Expanded(
              flex: 2,
              child: ElevatedButton(
                onPressed: (_canProceed && !_isProcessing)
                    ? _handleBeginDeletion
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark
                      ? const Color(0xFFEF4444)
                      : const Color(0xFFC5282F),
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(vertical: 3.5.w),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(2.w),
                  ),
                  elevation: _canProceed ? 2 : 0,
                ),
                child: _isProcessing
                    ? Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 4.w,
                            height: 4.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            'Starting...',
                            style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      )
                    : Text(
                        'Begin Secure Deletion',
                        style: theme.textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _calculateTotalSize() {
    double totalBytes = 0;

    for (final item in selectedItems) {
      final sizeStr = item['size'] as String? ?? '0 B';
      final parts = sizeStr.split(' ');
      if (parts.length == 2) {
        final value = double.tryParse(parts[0]) ?? 0;
        final unit = parts[1].toUpperCase();

        switch (unit) {
          case 'B':
            totalBytes += value;
            break;
          case 'KB':
            totalBytes += value * 1024;
            break;
          case 'MB':
            totalBytes += value * 1024 * 1024;
            break;
          case 'GB':
            totalBytes += value * 1024 * 1024 * 1024;
            break;
        }
      }
    }

    if (totalBytes >= 1024 * 1024 * 1024) {
      return '${(totalBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    } else if (totalBytes >= 1024 * 1024) {
      return '${(totalBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else if (totalBytes >= 1024) {
      return '${(totalBytes / 1024).toStringAsFixed(1)} KB';
    } else {
      return '${totalBytes.toInt()} B';
    }
  }

  Future<bool> _handleBackPress() async {
    if (_isProcessing) return false;
    _handleCancel();
    return false;
  }

  void _handleBackdropTap() {
    if (!_isProcessing) {
      _handleCancel();
    }
  }

  void _handleCancel() {
    if (_isProcessing) return;

    HapticFeedback.lightImpact();
    _slideController.reverse().then((_) {
      _fadeController.reverse().then((_) {
        Navigator.of(context).pop();
      });
    });
  }

  Future<void> _handleBeginDeletion() async {
    if (!_canProceed || _isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    // Provide strong haptic feedback for destructive action
    HapticFeedback.heavyImpact();

    try {
      // Simulate processing delay
      await Future.delayed(const Duration(seconds: 2));

      if (mounted) {
        // Navigate to wipe progress screen
        Navigator.of(context).pushReplacementNamed('/wipe-progress');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
                'Failed to start deletion process. Please try again.'),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
