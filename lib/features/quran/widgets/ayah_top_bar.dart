import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/features/quran/services/quran_service.dart';

class MushafTopBar extends StatelessWidget {
  const MushafTopBar({
    required this.surah,
    required this.currentPage,
    required this.pagesCount,
  });

  final QuranSurah surah;
  final int currentPage;
  final int pagesCount;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w),
      decoration: BoxDecoration(
        color: const Color(0XFF244E38),
        borderRadius: BorderRadius.circular(4.r),
        image: const DecorationImage(
          image: AssetImage('assets/img/top_bar.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black38, BlendMode.darken),
        ),
      ),
      child: Row(
        children: [
          Expanded(child: _TextMethod(text: surah.revelationPlace)),
          _verticalLine(),
          Expanded(
            flex: 2,
            child: Text(
              '${surah.nameArabic}',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: const Color.fromARGB(255, 255, 255, 255),
                fontSize: 20.sp,
                fontWeight: FontWeight.w900,
                fontFamily: 'Amiri',
              ),
            ),
          ),
          _verticalLine(),

          Expanded(child: _TextMethod(text: '${surah.versesCount} آية')),
          _verticalLine(),
          SizedBox(child: _TextMethod(text: '$currentPage/$pagesCount')),
        ],
      ),
    );
  }

  Text _TextMethod({String text = ''}) {
    return Text('$text', textAlign: TextAlign.center, style: _metaStyle());
  }

  SizedBox _verticalLine() {
    return SizedBox(
      height: 70.h,
      child: VerticalDivider(
        color: const Color.fromARGB(255, 0, 0, 0),
        thickness: 2,
      ),
    );
  }

  TextStyle _metaStyle() {
    return TextStyle(
      color: const Color.fromARGB(255, 234, 187, 17),
      fontSize: 12.sp,
      fontWeight: FontWeight.w700,
      // fontFamily: 'Amiri',
      fontFamily: 'Cairo',
    );
  }
}
