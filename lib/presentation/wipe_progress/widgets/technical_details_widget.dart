import 'package:flutter/material.dart';
import 'package:sizer/sizer.dart';
import 'package:google_fonts/google_fonts.dart';

class TechnicalDetailsWidget extends StatelessWidget {
  final bool isExpanded;
  final VoidCallback onToggle;
  final String securityAlgorithm;
  final String verificationStatus;
  final List<String> operationLog;

  const TechnicalDetailsWidget({
    Key? key,
    required this.isExpanded,
    required this.onToggle,
    required this.securityAlgorithm,
    required this.verificationStatus,
    required this.operationLog,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade800),
      ),
      child: Column(
        children: [
          // Header (Always Visible)
          InkWell(
            onTap: onToggle,
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: EdgeInsets.all(4.w),
              child: Row(
                children: [
                  Icon(
                    Icons.settings,
                    color: Colors.blue,
                    size: 20.sp,
                  ),
                  SizedBox(width: 3.w),
                  Expanded(
                    child: Text(
                      'Technical Details',
                      style: GoogleFonts.inter(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade400,
                    size: 24.sp,
                  ),
                ],
              ),
            ),
          ),

          // Expandable Content
          if (isExpanded)
            Padding(
              padding: EdgeInsets.fromLTRB(4.w, 0, 4.w, 4.w),
              child: Column(
                children: [
                  Divider(color: Colors.grey.shade800),
                  SizedBox(height: 2.h),

                  // Security Algorithm
                  _buildDetailRow(
                    'Security Algorithm',
                    securityAlgorithm,
                    Icons.security,
                    Colors.orange,
                  ),

                  SizedBox(height: 2.h),

                  // Verification Status
                  _buildDetailRow(
                    'Verification Status',
                    verificationStatus,
                    Icons.verified,
                    verificationStatus == 'Completed Successfully'
                        ? Colors.green
                        : Colors.orange,
                  ),

                  SizedBox(height: 2.h),

                  // Operation Log
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.history,
                            color: Colors.purple,
                            size: 18.sp,
                          ),
                          SizedBox(width: 2.w),
                          Text(
                            'Operation Log',
                            style: GoogleFonts.inter(
                              fontSize: 14.sp,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 1.h),
                      Container(
                        height: 15.h,
                        padding: EdgeInsets.all(2.w),
                        decoration: BoxDecoration(
                          color: Colors.black,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade700),
                        ),
                        child: ListView.builder(
                          itemCount: operationLog.length,
                          itemBuilder: (context, index) {
                            final logEntry =
                                operationLog[operationLog.length - 1 - index];
                            return Padding(
                              padding: EdgeInsets.only(bottom: 0.5.h),
                              child: Text(
                                logEntry,
                                style: GoogleFonts.inter(
                                  fontSize: 10.sp,
                                  color: Colors.green.shade300,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
      String label, String value, IconData icon, Color color) {
    return Row(
      children: [
        Icon(
          icon,
          color: color,
          size: 18.sp,
        ),
        SizedBox(width: 2.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12.sp,
                  color: Colors.grey.shade400,
                ),
              ),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}