import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/features/quran/services/quran_service.dart';

class MushafTopBar extends StatelessWidget {
  const MushafTopBar({
    super.key,
    required this.surah,
  });

  final QuranSurah surah;

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
          Expanded(child: _metaText(surah.revelationPlace)),
          _divider(),
          Expanded(
            flex: 2,
            child: Text(
              surah.nameArabic,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.w900,
                fontFamily: 'Amiri',
              ),
            ),
          ),
          _divider(),
          Expanded(child: _metaText('${surah.versesCount} آية')),
        ],
      ),
    );
  }

  Text _metaText(String text) {
    return Text(
      text,
      textAlign: TextAlign.center,
      style: TextStyle(
        color: const Color(0xFFEABB11),
        fontSize: 12.sp,
        fontWeight: FontWeight.w700,
        fontFamily: 'Cairo',
      ),
    );
  }

  SizedBox _divider() {
    return SizedBox(
      height: 70.h,
      child: const VerticalDivider(color: Colors.black, thickness: 2),
    );
  }
}
