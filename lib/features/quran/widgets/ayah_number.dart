import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';

class AyahNumber extends StatelessWidget {
  final int number;
  const AyahNumber({super.key, required this.number});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46.w,
      height: 46.w,
      alignment: Alignment.center,
      margin: EdgeInsets.symmetric(horizontal: 2.w),
      // use provided image as background for the ayah number
      decoration: BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/img/verseNumber.png'),
          fit: BoxFit.contain,
        ),
      ),
      child: Text(
        '$number',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Color.fromARGB(255, 254, 255, 255),
          fontSize: 10.sp,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}
