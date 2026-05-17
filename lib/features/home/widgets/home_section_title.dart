import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:huda/core/theme/app_colors.dart';

class HomeSectionTitle extends StatelessWidget {
  final IconData icon;
  final String title;
  const HomeSectionTitle({super.key, required this.icon, required this.title});

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);

    return Row(
      children: [
        Icon(
          icon,
          color: brightness == Brightness.dark
              ? AppColors.white
              : AppColors.primary,
          size: 24.sp,
        ),
        SizedBox(width: 15.w),
        Text(
          title,
          style: TextStyle(
            fontSize: 20.sp,
            fontWeight: FontWeight.bold,
            color: brightness == Brightness.dark
                ? AppColors.white
                : AppColors.primary,
          ),
        ),
      ],
    );
  }
}
