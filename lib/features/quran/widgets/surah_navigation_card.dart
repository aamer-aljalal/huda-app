import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class SurahNavigationCard extends StatelessWidget {
  const SurahNavigationCard({
    super.key,
    required this.title,
    required this.surahName,
    required this.isNext,
    required this.onTap,
  });

  final String title;
  final String surahName;
  final bool isNext;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: const Color(0xFF1E1A12).withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isNext)
              Icon(
                Icons.keyboard_arrow_right_rounded,
                color: const Color(0xFF1A6B58),
                size: 20.sp,
              ),
            SizedBox(width: 4.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Cairo',
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  surahName,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: const Color(0xFF1E1A12),
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Amiri',
                  ),
                ),
              ],
            ),
            SizedBox(width: 4.w),
            if (!isNext)
              Icon(
                Icons.keyboard_arrow_left_rounded,
                color: const Color(0xFF1A6B58),
                size: 20.sp,
              ),
          ],
        ),
      ),
    );
  }
}
