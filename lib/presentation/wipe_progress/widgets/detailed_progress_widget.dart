import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class DetailedProgressWidget extends StatelessWidget {
  final String currentFile;
  final int filesCompleted;
  final int totalFiles;
  final String estimatedTimeRemaining;

  const DetailedProgressWidget({
    Key? key,
    required this.currentFile,
    required this.filesCompleted,
    required this.totalFiles,
    required this.estimatedTimeRemaining,
  }) : super(key: key);

  String _truncateFilename(String filename) {
    if (filename.length <= 30) return filename;
    return '${filename.substring(0, 15)}...${filename.substring(filename.length - 10)}';
  }

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
            'Current Progress',
            style: GoogleFonts.inter(
              fontSize: 16.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),

          SizedBox(height: 2.h),

          // Current File
          Row(
            children: [
              Icon(
                Icons.description,
                color: Colors.blue,
                size: 20.sp,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Processing File:',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    Text(
                      _truncateFilename(currentFile),
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Files Progress
          Row(
            children: [
              Icon(
                Icons.folder,
                color: Colors.green,
                size: 20.sp,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Files Completed:',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    Text(
                      '$filesCompleted of $totalFiles files',
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 2.h),

          // Time Remaining
          Row(
            children: [
              Icon(
                Icons.access_time,
                color: Colors.orange,
                size: 20.sp,
              ),
              SizedBox(width: 3.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Estimated Time:',
                      style: GoogleFonts.inter(
                        fontSize: 12.sp,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    Text(
                      estimatedTimeRemaining,
                      style: GoogleFonts.inter(
                        fontSize: 14.sp,
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}