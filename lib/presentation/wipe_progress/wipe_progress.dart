import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:sizer/sizer.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_app_bar.dart';
import './widgets/detailed_progress_widget.dart';
import './widgets/emergency_stop_widget.dart';
import './widgets/live_statistics_widget.dart';
import './widgets/operation_status_widget.dart';
import './widgets/progress_indicator_widget.dart';
import './widgets/technical_details_widget.dart';

class WipeProgress extends StatefulWidget {
  const WipeProgress({Key? key}) : super(key: key);

  @override
  State<WipeProgress> createState() => _WipeProgressState();
}

class _WipeProgressState extends State<WipeProgress>
    with TickerProviderStateMixin {
  late AnimationController _progressAnimationController;
  late AnimationController _shieldAnimationController;
  late Animation<double> _progressAnimation;
  late Animation<double> _shieldAnimation;

  // Progress tracking
  double _overallProgress = 0.0;
  String _currentPhase = 'Analyzing Files';
  String _currentFile = '';
  int _filesCompleted = 0;
  int _totalFiles = 0;
  String _estimatedTimeRemaining = '';
  String _dataWiped = '0 MB';
  int _passesCompleted = 0;
  String _currentWriteSpeed = '0 MB/s';
  bool _isOperationActive = false;
  bool _showTechnicalDetails = false;
  String _securityAlgorithm = 'DoD 5220.22-M (3-pass)';
  String _verificationStatus = 'Pending';
  List<String> _operationLog = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _startWipeOperation();
    _preventSystemBack();
  }

  void _initializeAnimations() {
    _progressAnimationController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    _shieldAnimationController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _progressAnimationController,
      curve: Curves.easeInOut,
    ));

    _shieldAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shieldAnimationController,
      curve: Curves.easeInOut,
    ));
  }

  void _preventSystemBack() {
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
    ));
  }

  Future<void> _startWipeOperation() async {
    setState(() {
      _isOperationActive = true;
      _totalFiles = 1250;
    });

    _addToLog('Secure deletion operation initiated');
    await _simulateWipeProcess();
  }

  Future<void> _simulateWipeProcess() async {
    // Phase 1: Analyzing Files
    await _runPhase('Analyzing Files', 0.0, 0.15, () async {
      for (int i = 0; i <= 15; i++) {
        if (!_isOperationActive) break;

        await Future.delayed(const Duration(milliseconds: 200));
        setState(() {
          _overallProgress = i / 100.0;
          _currentFile = 'system_cache_${i * 10}.tmp';
          _estimatedTimeRemaining = '${45 - (i * 2)} min remaining';
        });

        if (kIsWeb) {
          // Web-specific haptic feedback simulation
          _triggerWebHaptic();
        } else {
          // Mobile haptic feedback at 25% intervals
          if (i % 4 == 0) {
            HapticFeedback.lightImpact();
          }
        }
      }
    });

    // Phase 2: Wiping Data
    await _runPhase('Wiping Data', 0.15, 0.85, () async {
      for (int i = 16; i <= 85; i++) {
        if (!_isOperationActive) break;

        await Future.delayed(const Duration(milliseconds: 300));
        setState(() {
          _overallProgress = i / 100.0;
          _filesCompleted = ((i - 15) * _totalFiles / 70).round();
          _currentFile = 'document_${_filesCompleted}_secure.pdf';
          _dataWiped = '${(_filesCompleted * 2.5).toStringAsFixed(1)} MB';
          _passesCompleted = ((i - 15) / 23).round();
          _currentWriteSpeed = '${15 + (i % 10)} MB/s';
          _estimatedTimeRemaining = '${35 - ((i - 15) ~/ 2)} min remaining';
        });

        if (i % 25 == 0 && !kIsWeb) {
          HapticFeedback.mediumImpact();
        }
      }
    });

    // Phase 3: Verifying Deletion
    await _runPhase('Verifying Deletion', 0.85, 1.0, () async {
      setState(() {
        _verificationStatus = 'In Progress';
      });

      for (int i = 86; i <= 100; i++) {
        if (!_isOperationActive) break;

        await Future.delayed(const Duration(milliseconds: 400));
        setState(() {
          _overallProgress = i / 100.0;
          _currentFile = 'verification_block_${i - 85}.dat';
          _estimatedTimeRemaining =
              i == 100 ? 'Completing...' : '${100 - i} sec remaining';
        });
      }

      setState(() {
        _verificationStatus = 'Completed Successfully';
      });
    });

    if (_isOperationActive) {
      await _completeOperation();
    }
  }

  Future<void> _runPhase(String phase, double startProgress, double endProgress,
      Future<void> Function() phaseOperation) async {
    setState(() {
      _currentPhase = phase;
    });

    _addToLog('Phase started: $phase');
    await phaseOperation();

    if (_isOperationActive) {
      _addToLog('Phase completed: $phase');
    }
  }

  void _triggerWebHaptic() {
    // Web haptic feedback simulation (visual feedback)
    if (kIsWeb) {
      // Could implement web-specific feedback mechanisms
    }
  }

  Future<void> _completeOperation() async {
    setState(() {
      _isOperationActive = false;
      _currentPhase = 'Operation Complete';
    });

    _addToLog('Secure deletion completed successfully');

    // Celebration haptic feedback
    if (!kIsWeb) {
      await HapticFeedback.heavyImpact();
      await Future.delayed(const Duration(milliseconds: 100));
      await HapticFeedback.heavyImpact();
    }

    // Show completion animation
    await _progressAnimationController.forward();

    // Navigate to results screen after delay
    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.mainDashboard);
    }
  }

  void _addToLog(String message) {
    setState(() {
      _operationLog.add(
          '${DateTime.now().toIso8601String().substring(11, 19)}: $message');
    });
  }

  Future<void> _showEmergencyStopDialog() async {
    final bool? shouldStop = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(
            'Emergency Stop',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          content: Text(
            'Are you sure you want to stop the secure deletion operation?\n\nWarning: Stopping mid-process may leave recoverable data fragments.',
            style: GoogleFonts.inter(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Continue Operation',
                style: GoogleFonts.inter(color: Colors.blue),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text(
                'Stop Operation',
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        );
      },
    );

    if (shouldStop == true) {
      await _emergencyStop();
    }
  }

  Future<void> _emergencyStop() async {
    setState(() {
      _isOperationActive = false;
      _currentPhase = 'Operation Stopped';
    });

    _addToLog('Emergency stop initiated by user');

    if (!kIsWeb) {
      HapticFeedback.heavyImpact();
    }

    // Navigate back after brief delay
    await Future.delayed(const Duration(seconds: 1));
    if (mounted) {
      Navigator.pop(context);
    }
  }

  @override
  void dispose() {
    _progressAnimationController.dispose();
    _shieldAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isOperationActive) {
          await _showEmergencyStopDialog();
          return false;
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: CustomAppBar(
          title: 'Secure Wipe Progress',
          centerTitle: true,
          backgroundColor: Colors.black,
          actions: [
            RotationTransition(
              turns: _shieldAnimation,
              child: CustomIconWidget(
                iconName: 'shield',
                size: 24.sp,
                color: Colors.green,
              ),
            ),
            SizedBox(width: 4.w),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(4.w),
                  child: Column(
                    children: [
                      // Operation Status Header
                      OperationStatusWidget(
                        currentPhase: _currentPhase,
                        isActive: _isOperationActive,
                      ),

                      SizedBox(height: 4.h),

                      // Main Progress Indicator
                      ProgressIndicatorWidget(
                        progress: _overallProgress,
                        animation: _progressAnimation,
                      ),

                      SizedBox(height: 4.h),

                      // Detailed Progress Information
                      DetailedProgressWidget(
                        currentFile: _currentFile,
                        filesCompleted: _filesCompleted,
                        totalFiles: _totalFiles,
                        estimatedTimeRemaining: _estimatedTimeRemaining,
                      ),

                      SizedBox(height: 3.h),

                      // Live Statistics
                      LiveStatisticsWidget(
                        dataWiped: _dataWiped,
                        passesCompleted: _passesCompleted,
                        currentWriteSpeed: _currentWriteSpeed,
                      ),

                      SizedBox(height: 3.h),

                      // Technical Details (Expandable)
                      TechnicalDetailsWidget(
                        isExpanded: _showTechnicalDetails,
                        onToggle: () => setState(() =>
                            _showTechnicalDetails = !_showTechnicalDetails),
                        securityAlgorithm: _securityAlgorithm,
                        verificationStatus: _verificationStatus,
                        operationLog: _operationLog,
                      ),

                      SizedBox(height: 6.h),
                    ],
                  ),
                ),
              ),

              // Emergency Stop Button (Always Visible)
              if (_isOperationActive)
                Padding(
                  padding: EdgeInsets.all(4.w),
                  child: EmergencyStopWidget(
                    onPressed: _showEmergencyStopDialog,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}