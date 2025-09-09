import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class LiveStatisticsWidget extends StatelessWidget {
  final String dataWiped;
  final int passesCompleted;
  final String currentWriteSpeed;

  const LiveStatisticsWidget({
    Key? key,
    required this.dataWiped,
    required this.passesCompleted,
    required this.currentWriteSpeed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Live Statistics',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          SizedBox(height: 2.h),

          Row(
            children: [
              // Data Wiped
              Expanded(
                child: _buildStatItem(
                  icon: Icons.storage,
                  label: 'Data Wiped',
                  value: dataWiped,
                  color: Colors.red,
                ),
              ),

              // Passes Completed
              Expanded(
                child: _buildStatItem(
                  icon: Icons.sync,
                  label: 'Passes',
                  value: '$passesCompleted/3',
                  color: Colors.blue,
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Current Write Speed (Full Width)
          _buildStatItem(
            icon: Icons.speed,
            label: 'Write Speed',
            value: currentWriteSpeed,
            color: Colors.green,
            isFullWidth: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    bool isFullWidth = false,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isFullWidth ? 0 : 2.w,
        vertical: 1.h,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: color,
                size: 18.sp,
              ),
              SizedBox(width: 2.w),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: Colors.grey.shade400,
                ),
              ),
            ],
          ),
          SizedBox(height: 0.5.h),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
