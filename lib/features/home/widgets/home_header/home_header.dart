import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huda/core/theme/app_colors.dart';
import 'package:huda/features/home/widgets/home_header/home_mini_header.dart';
import 'package:huda/features/home/widgets/home_header/home_notifications_sheet.dart';
import 'package:huda/features/home/widgets/home_header/home_prayer_card.dart';
import 'package:huda/features/home/widgets/home_header/home_recent_actions.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:huda/core/providers/prayer_provider.dart';
import 'package:adhan/adhan.dart';
import 'package:hijri/hijri_calendar.dart';
import 'package:huda/routes/AppRoutes.dart';
import 'package:huda/features/quran/services/quran_service.dart';
import 'package:huda/features/quran/views/surah_detail_page.dart';
import 'package:huda/features/azkar/services/azkar_service.dart';
import 'package:huda/features/azkar/zkar_details.dart';
import 'package:huda/core/services/in_app_notification_service.dart';

class HomeHeader extends StatefulWidget {
  const HomeHeader({super.key});

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  bool _isNumericFormat = false;
  List<InAppNotification> _activeNotifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  Future<void> _loadNotifications() async {
    try {
      final list = await InAppNotificationService.getActiveNotifications();
      if (mounted) {
        setState(() {
          _activeNotifications = list;
        });
      }
    } catch (_) {}
  }

  void _showNotificationsBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        // return StatefulBuilder(
        //   builder: (context, setModalState) {
        //     final isDark = Theme.of(context).brightness == Brightness.dark;
        //     final cardBg = isDark
        //         ? const Color(0xFF2C2C2C)
        //         : Colors.grey.shade50;

        //     return;
        //   },
        // );
        return HomeNotificationsSheet(
          notifications: _activeNotifications,
          onNotificationTap: (notification) async {
            await _handleNotificationClick(notification);
            await _loadNotifications();
          },
        );
      },
    );
  }

  Future<void> _handleNotificationClick(InAppNotification notif) async {
    if (notif.type == 'surah_kahf') {
      try {
        final surahs = await QuranService.loadSurahs();
        final kahfSurah = surahs.firstWhere((s) => s.number == 18);
        final ayahs = await QuranService.loadAyahs(18);

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                SurahDetailPage(surah: kahfSurah, ayahs: ayahs),
          ),
        ).then((_) => _loadNotifications());
      } catch (_) {}
    } else if (notif.type == 'morning_azkar' ||
        notif.type == 'evening_azkar' ||
        notif.type == 'sleep_azkar') {
      try {
        final targetTitle = notif.type == 'morning_azkar'
            ? 'أذكار الصباح'
            : notif.type == 'evening_azkar'
            ? 'أذكار المساء'
            : 'أذكار النوم';
        final categories = await AzkarService.loadAzkar();
        final match = categories.firstWhere((c) => c.title == targetTitle);

        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => AzkarDetailsScreen(category: match),
          ),
        ).then((_) => _loadNotifications());
      } catch (_) {}
    } else {
      await InAppNotificationService.markCompleted(notif.type);

      String message = 'تقبل الله طاعتك وصالح أعمالك';
      if (notif.type == 'fasting') {
        message = 'تقبل الله صيامك وطاعتك المباركة';
      } else if (notif.type == 'daily_content') {
        message = 'تم الإطلاع على آية وحديث اليوم بنجاح';
        if (mounted) {
          Navigator.pushNamed(
            context,
            AppRoutes.hadith,
          ).then((_) => _loadNotifications());
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message, textAlign: TextAlign.right),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

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
      automaticallyImplyLeading: false,
      toolbarHeight: 380.h,

      pinned: false,
      // pinned: true,
      flexibleSpace: Container(
        child: Container(
          decoration: BoxDecoration(
            image: const DecorationImage(
              image: AssetImage('assets/img/header_bg.png'),
              fit: BoxFit.cover,
            ),

            // borderRadius: BorderRadius.vertical(bottom: Radius.circular(5.r)),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: EdgeInsets.only(
                left: 20.w,
                top: 20.h,
                right: 20.w,
                bottom: 30.h,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  HomeMiniHeader(
                    provider: prayerProvider,
                    nextName: dynamicNextPrayer,
                    activeNotifications: _activeNotifications,
                    onNotificationTap: () {
                      _showNotificationsBottomSheet(context);
                    },
                  ),

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
                              _getHijriDate(_isNumericFormat),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 13.sp,
                                fontFamily: 'Amiri',
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
                            fontFamily: 'Amiri',
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
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  // بطاقة أوقات الصلاة الأفقية
                  HomePrayerCard(
                    countdown: countdown,
                    dynamicNextPrayer: dynamicNextPrayer,
                    currentPrayerTimes: currentPrayerTimes,
                  ),

                  const HomeRecentActions(),
                ],
              ),
            ),
          ),
        ),
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
}
