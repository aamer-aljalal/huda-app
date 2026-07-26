import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/features/quran/services/quran_service.dart';

class AyahInterpretationSheet extends StatelessWidget {
  const AyahInterpretationSheet({
    super.key,
    required this.surahName,
    required this.ayah,
    required this.interpretation,
  });

  final String surahName;
  final QuranAyah ayah;
  final String interpretation;

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
          ),
          child: Column(
            children: [
              SizedBox(height: 10.h),
              Container(
                width: 44.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'تفسير الميسر',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: const Color(0xFF1A6B58),
                ),
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  children: [
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9F9),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Text(
                        ayah.text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18.sp,
                          height: 1.8,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1710),
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      interpretation.isEmpty
                          ? 'التفسير غير متوفر'
                          : interpretation,
                      style: TextStyle(
                        fontSize: 15.sp,
                        height: 1.8,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Cairo',
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
