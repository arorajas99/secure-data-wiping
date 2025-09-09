import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class ProgressIndicatorWidget extends StatelessWidget {
  final double progress;
  final Animation<double> animation;

  const ProgressIndicatorWidget({
    Key? key,
    required this.progress,
    required this.animation,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 60.w,
      height: 60.w,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background Circle
          Container(
            width: 60.w,
            height: 60.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.grey.shade800,
                width: 3,
              ),
            ),
          ),

          // Progress Circle
          AnimatedBuilder(
            animation: animation,
            builder: (context, child) {
              return SizedBox(
                width: 60.w,
                height: 60.w,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: Colors.transparent,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress < 0.5
                        ? Colors.orange
                        : progress < 0.85
                            ? Colors.blue
                            : Colors.green,
                  ),
                ),
              );
            },
          ),

          // Percentage Text
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${(progress * 100).toInt()}%',
                style: GoogleFonts.inter(
                  fontSize: 24.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              Text(
                'Complete',
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
