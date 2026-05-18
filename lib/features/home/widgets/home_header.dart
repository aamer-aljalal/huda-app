import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:huda/core/providers/prayer_provider.dart';
import 'package:adhan/adhan.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:huda/routes/AppRoutes.dart';
import 'package:huda/core/services/recent_actions_service.dart';
import 'package:huda/features/quran/services/quran_service.dart';
import 'package:huda/features/quran/views/surah_detail_page.dart';
import 'package:huda/features/azkar/services/azkar_service.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  bool _isNumericFormat = false;

  String _getGregorianDate(bool isNumeric) {
    final now = DateTime.now();
    final day = DateFormat('d', 'en').format(now);
    final year = DateFormat('yyyy', 'en').format(now);
    if (isNumeric) {
      final month = DateFormat('M', 'en').format(now);
      return '\u200F$day / $month / \u200F$year';
    } else {
      final month = DateFormat('MMMM', 'ar').format(now);
      return '\u200F$day $month \u200F$year';
    }
  }

  String _getHijriDate(bool isNumeric) {
    HijriCalendar.setLocal('ar');
    final hijri = HijriCalendar.now();
    final day = hijri.hDay;
    final year = hijri.hYear;
    if (isNumeric) {
      final month = hijri.hMonth;
      return '\u200F$day / $month / \u200F$year';
    } else {
      final month = hijri.getLongMonthName();
      return '\u200F$day $month \u200F$year';
    }
  String _getDayName() {
    final now = DateTime.now();
    switch (now.weekday) {
      case DateTime.monday:
        return 'الإثنين';
      case DateTime.tuesday:
        return 'الثلاثاء';
      case DateTime.wednesday:
        return 'الأربعاء';
      case DateTime.thursday:
        return 'الخميس';
      case DateTime.friday:
        return 'الجمعة';
      case DateTime.saturday:
        return 'السبت';
      case DateTime.sunday:
        return 'الأحد';
      default:
        return '';
    }
  }

  IconData _getPrayerIcon(String prayerName) {
    switch (prayerName) {
      case 'الفجر':
        return Icons.wb_twilight_rounded;
      case 'الظهر':
        return Icons.wb_sunny_rounded;
      case 'العصر':
        return Icons.wb_sunny_outlined;
      case 'المغرب':
        return Icons.brightness_medium_rounded;
      case 'العشاء':
        return Icons.nights_stay_rounded;
      default:
        return Icons.access_time_rounded;
    }
  }

  Future<void> _resumeQuran(BuildContext context, int surahNumber) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final surahs = await QuranService.loadSurahs();
      final surah = surahs.firstWhere((s) => s.number == surahNumber);
      final ayahs = await QuranService.loadAyahs(surahNumber);

      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SurahDetailPage(surah: surah, ayahs: ayahs),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح الصفحة المحفوظة')),
        );
      }
    }
  }

  Future<void> _resumeAzkar(BuildContext context, String categoryTitle) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final categories = await AzkarService.loadAzkar();
      final category = categories.firstWhere((c) => c.title == categoryTitle);

      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        Navigator.pushNamed(
          context,
          AppRoutes.surahDetails,
          arguments: category,
        );
      }
    } catch (_) {
      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر فتح الأذكار')));
      }
    }
  }

  void _handleRecentActionTap(BuildContext context, RecentAction action) {
    HapticFeedback.lightImpact();
    if (action.category == 'quran') {
      final surahNumber = action.extraData['surah_number'] as int?;
      if (surahNumber != null) {
        _resumeQuran(context, surahNumber);
      }
    } else if (action.category == 'azkar') {
      final categoryTitle = action.extraData['category_title'] as String?;
      if (categoryTitle != null) {
        _resumeAzkar(context, categoryTitle);
      }
    }
  }

  Widget _buildRecentButton(BuildContext context, RecentAction action) {
    IconData getIcon() {
      switch (action.category) {
        case 'quran':
          return Icons.menu_book_rounded;
        case 'azkar':
          return Icons.bookmark_added_rounded;
        case 'names_of_allah':
          return Icons.auto_awesome_rounded;
        default:
          return Icons.history_toggle_off_rounded;
      }
    }

    Color getCategoryColor(ColorScheme colorScheme) {
      switch (action.category) {
        case 'quran':
          return Colors.greenAccent;
        case 'azkar':
          return Colors.amberAccent;
        case 'names_of_allah':
          return Colors.cyanAccent;
        default:
          return Colors.white70;
      }
    }

    return Expanded(
      child: InkWell(
        onTap: () => _handleRecentActionTap(context, action),
        borderRadius: BorderRadius.circular(12.r),
        child: Column(
          // mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              child: Icon(
                getIcon(),
                size: 16.sp,
                color: getCategoryColor(Theme.of(context).colorScheme),
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              '${action.title.replaceAll('سورة ', '')}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 7.5.sp,
                fontWeight: FontWeight.bold,
              ),
            ),
            // Row(
            //   children: [
            //     Text(
            //       '${action.title.replaceAll('سورة ', '')} : ',
            //       maxLines: 1,
            //       overflow: TextOverflow.ellipsis,
            //       textAlign: TextAlign.center,
            //       style: TextStyle(
            //         color: Colors.white,
            //         fontSize: 7.5.sp,
            //         fontWeight: FontWeight.bold,
            //       ),
            //     ),
            //     // SizedBox(height: 1.h),
            //     // Text(
            //     //   action.subtitle,
            //     //   maxLines: 1,
            //     //   overflow: TextOverflow.ellipsis,
            //     //   textAlign: TextAlign.center,
            //     //   style: TextStyle(color: Colors.white60, fontSize: 7.5.sp),
            //     // ),
            //   ],
            // ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prayerProvider = Provider.of<PrayerProvider>(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final currentPrayerTimes = {
      'الفجر': prayerProvider.getFormattedPrayerTime(Prayer.fajr),
      'الظهر': prayerProvider.getFormattedPrayerTime(Prayer.dhuhr),
      'العصر': prayerProvider.getFormattedPrayerTime(Prayer.asr),
      'المغرب': prayerProvider.getFormattedPrayerTime(Prayer.maghrib),
      'العشاء': prayerProvider.getFormattedPrayerTime(Prayer.isha),
    };

    final dynamicNextPrayer =
        prayerProvider.nextPrayer != null &&
            prayerProvider.nextPrayer != Prayer.none
        ? prayerProvider.getPrayerName(prayerProvider.nextPrayer!)
        : '...';

    final countdown = prayerProvider.timeUntilNextPrayer.inSeconds > 0
        ? _formatDuration(prayerProvider.timeUntilNextPrayer)
        : '--:--';

    return SliverAppBar(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(10.r)),
      ),
      automaticallyImplyLeading: false,
      toolbarHeight: 80.h,
      expandedHeight: 380.h,
      pinned: true,
      backgroundColor: colorScheme.primary, // استخدم اللون الأساسي من الثيم
      elevation: 0,
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            image: const DecorationImage(
              image: AssetImage('assets/img/header_bg.png'),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(15.r)),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(
                  0.2,
                ), // تظليل متوافق مع الثيم
                blurRadius: 10,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.fromLTRB(20, 50, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Spacer(flex: 2),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isNumericFormat = !_isNumericFormat;
                          });
                          HapticFeedback.lightImpact();
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              size: 14.sp,
                              color: Colors.white,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              '${_getDayName()}، ${_getHijriDate(_isNumericFormat)}',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _isNumericFormat = !_isNumericFormat;
                          });
                          HapticFeedback.lightImpact();
                        },
                        behavior: HitTestBehavior.opaque,
                        child: Text(
                          _getGregorianDate(_isNumericFormat),
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 13.sp,
                          ),
                        ),
                      ),

                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 12.w,
                          vertical: 6.h,
                        ),
                        decoration: BoxDecoration(
                          // استخدام لون السطح مع شفافية ليتناسب مع الوضعين
                          color: colorScheme.surface.withOpacity(0.25),
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 16.sp,
                              color: Colors.white,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              prayerProvider.cityName.isNotEmpty
                                  ? 'بتوقيت : ${prayerProvider.cityName}'
                                  : prayerProvider.cityName,
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10.sp,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  // بطاقة أوقات الصلاة الأفقية
                  Container(
                    padding: EdgeInsets.only(
                      right: 8.w,
                      left: 8.w,
                      bottom: 6.h,
                    ),
                    margin: EdgeInsets.symmetric(vertical: 8.h),
                    decoration: BoxDecoration(
                      // استخدام ألوان الثيم للبطاقة الشفافة
                      color: colorScheme.surface.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12.r),
                      border: Border.all(
                        color: colorScheme.onSurface.withOpacity(0.1),
                      ),
                    ),

                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: 8.w,
                            vertical: 4.h,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              // كم المتبقي للصلاة القادمة (في اليسار)
                              Text(
                                'متبقي لـ $dynamicNextPrayer: $countdown',
                                style: TextStyle(
                                  fontSize: 11.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.amberAccent,
                                ),
                              ),
                              // عنوان مواقيت الصلاة (في اليمين)
                              Text(
                                'مواقيت الصلاة',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: currentPrayerTimes.entries.map((entry) {
                            final isNext = entry.key == dynamicNextPrayer;
                            return AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              padding: EdgeInsets.symmetric(
                                vertical: isNext ? 4 : 0,
                              ),
                              decoration: BoxDecoration(
                                color: isNext
                                    ? colorScheme.surface.withOpacity(0.3)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(8.r),
                              ),
                              child: Padding(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 10.w,
                                  vertical: 0.3.h,
                                ),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      _getPrayerIcon(entry.key),
                                      size: 16.sp,
                                      color: isNext
                                          ? Colors.amberAccent
                                          : Colors.white70,
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      entry.key,
                                      style: TextStyle(
                                        color: isNext
                                            ? Colors.amberAccent
                                            : Colors.white70,
                                        fontSize: 14.sp,
                                        fontWeight: isNext
                                            ? FontWeight.w600
                                            : FontWeight.normal,
                                      ),
                                    ),
                                    SizedBox(height: 6.h),
                                    Text(
                                      entry.value,
                                      style: TextStyle(
                                        color: isNext
                                            ? Colors.amberAccent
                                            : Colors.white,
                                        fontSize: 10.sp,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    if (isNext) ...[
                                      SizedBox(height: 6.h),
                                      Icon(
                                        Icons.arrow_upward,
                                        color: Colors.amberAccent,
                                        size: 14.sp,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                  FutureBuilder<List<RecentAction>>(
                    future: RecentActionsManager.getActions(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.isEmpty) {
                        return const SizedBox.shrink();
                      }
                      final actions = snapshot.data!;
                      return Container(
                        padding: EdgeInsets.symmetric(horizontal: 10.w),
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12.r),
                          border: Border.all(
                            color: colorScheme.onSurface.withValues(alpha: 0.1),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            SizedBox(height: 3.h),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: actions
                                  .map(
                                    (action) =>
                                        _buildRecentButton(context, action),
                                  )
                                  .toList(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
        ),
        collapseMode: CollapseMode.parallax,
      ),
      title: _buildMiniHeader(
        context, // تمرير الـ context لاستخدام الثيم
        prayerProvider,
        dynamicNextPrayer,
      ),
      systemOverlayStyle: SystemUiOverlayStyle.light,
    );
  }

  String _formatDuration(Duration d) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");
    int hours = d.inHours;
    int minutes = d.inMinutes.remainder(60);
    return "$hours:${twoDigits(minutes)}";
  }

  Widget _buildMiniHeader(
    BuildContext context,
    PrayerProvider provider,
    String nextName,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final now = DateTime.now();
    final timeDigits = DateFormat('h:mm', 'en').format(now);
    final amPmEn = DateFormat('a', 'en').format(now); // "AM" or "PM"
    final amPmAr = amPmEn == 'AM' ? 'ص' : 'م';
    final currentTime = '$timeDigits $amPmAr';

    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
          decoration: BoxDecoration(
            // استخدام ألوان الوضع الليلي/النهاري بدلاً من ألوان ثابتة
            color: colorScheme.surface,
            borderRadius: BorderRadius.circular(30.r),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.1),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.access_time,
                size: 17.sp,
                color: colorScheme.primary, // اللون الأساسي للتطبيق
              ),
              SizedBox(width: 6.w),
              Text(
                currentTime,
                style: TextStyle(
                  color: colorScheme.primary, // اللون الأساسي للتطبيق
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.settings_outlined, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, AppRoutes.settings);
            },
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 22,
          ),
        ),
        SizedBox(width: 8.w),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: const Icon(Icons.notifications_none, color: Colors.white),
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
            iconSize: 22,
          ),
        ),
      ],
    );
  }
}
