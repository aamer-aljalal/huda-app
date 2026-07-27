import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/features/quran/services/quran_service.dart';

class MushafTopBar extends StatelessWidget {
  const MushafTopBar({
    super.key,
    required this.surah,
    this.isPageView = false,
    this.onToggleReadingMode,
  });

  final QuranSurah surah;
  final bool isPageView;
  final VoidCallback? onToggleReadingMode;

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
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (onToggleReadingMode != null) ...[
                  Tooltip(
                    message: isPageView
                        ? 'التغيير إلى القائمة المتصلة'
                        : 'التغيير إلى عرض الصفحات',
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: onToggleReadingMode,
                        borderRadius: BorderRadius.circular(20.r),
                        child: Padding(
                          padding: EdgeInsets.all(4.w),
                          child: Icon(
                            isPageView
                                ? Icons.format_list_bulleted_rounded
                                : Icons.auto_stories_rounded,
                            color: const Color(0xFFEABB11),
                            size: 20.sp,
                          ),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 2.w),
                ],
                Flexible(child: _metaText(surah.revelationPlace)),
              ],
            ),
          ),
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
