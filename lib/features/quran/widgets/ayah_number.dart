import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';

class AyahNumber extends StatelessWidget {
  final int number;

  const AyahNumber({super.key, required this.number});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 4.w),
      padding: EdgeInsets.all(6.w),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black),
      ),
      child: Text(number.toString(), style: TextStyle(fontSize: 14.sp)),
    );
  }
}
