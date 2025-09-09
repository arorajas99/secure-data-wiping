import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class OperationStatusWidget extends StatelessWidget {
  final String currentPhase;
  final bool isActive;

  const OperationStatusWidget({
    Key? key,
    required this.currentPhase,
    required this.isActive,
  }) : super(key: key);

  Color _getPhaseColor() {
    switch (currentPhase) {
      case 'Analyzing Files':
        return Colors.orange;
      case 'Wiping Data':
        return Colors.blue;
      case 'Verifying Deletion':
        return Colors.purple;
      case 'Operation Complete':
        return Colors.green;
      case 'Operation Stopped':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getPhaseIcon() {
    switch (currentPhase) {
      case 'Analyzing Files':
        return Icons.search;
      case 'Wiping Data':
        return Icons.delete_forever;
      case 'Verifying Deletion':
        return Icons.verified;
      case 'Operation Complete':
        return Icons.check_circle;
      case 'Operation Stopped':
        return Icons.cancel;
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: _getPhaseColor().withAlpha(26),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _getPhaseColor().withAlpha(77),
          width: 2,
        ),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(2.w),
                decoration: BoxDecoration(
                  color: _getPhaseColor().withAlpha(51),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _getPhaseIcon(),
                  color: _getPhaseColor(),
                  size: 24.sp,
                ),
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Current Phase',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    Text(
                      currentPhase,
                      style: GoogleFonts.inter(
                        fontSize: 18.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 1.h),

          // Status Indicator
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8.sp,
                height: 8.sp,
                decoration: BoxDecoration(
                  color: isActive ? Colors.green : Colors.red,
                  shape: BoxShape.circle,
                ),
              ),
              SizedBox(width: 2.w),
              Text(
                isActive ? 'Active' : 'Inactive',
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
