import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:huda/core/theme/app_colors.dart';
import 'package:provider/provider.dart';
import 'package:huda/core/providers/prayer_provider.dart';
import 'package:adhan/adhan.dart';

class HomeHeader extends StatelessWidget {
  String get gregorianDate {
    final now = DateTime.now();
    return DateFormat('d MMMM yyyy', 'ar').format(now);
  }

  String get hijriDate => '1445 / رمضان 1';

  const HomeHeader({super.key});

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

    return SliverAppBar(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(10.r)),
      ),
      automaticallyImplyLeading: false,
      toolbarHeight: 90.h,
      expandedHeight: 450.h,
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
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14.sp,
                            color: Colors
                                .white, // لون ثابت لأن الخلفية دائماً صورة
                          ),
                          SizedBox(width: 6.w),
                          Text(
                            '$hijriDate',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13.sp,
                            ),
                          ),
                        ],
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
                  Text(
                    '$gregorianDate',
                    style: TextStyle(color: Colors.white70, fontSize: 13.sp),
                  ),
                  SizedBox(height: 10.h),
                  // بطاقة أوقات الصلاة الأفقية
                  Container(
                    padding: EdgeInsets.symmetric(
                      vertical: 8.h,
                      horizontal: 8.w,
                    ),
                    margin: EdgeInsets.symmetric(vertical: 8.h),
                    decoration: BoxDecoration(
                      // استخدام ألوان الثيم للبطاقة الشفافة
                      color: colorScheme.surface.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(25.r),
                      border: Border.all(
                        color: colorScheme.onSurface.withOpacity(0.1),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'مواقيت الصلاة',
                          textAlign: TextAlign.left,
                          style: TextStyle(
                            fontSize: 12.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white, // اللون ثابت وواضح
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
                                borderRadius: BorderRadius.circular(15.r),
                              ),
                              child: Padding(
                                padding: EdgeInsets.all(6.0.w),
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
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

                  const Spacer(flex: 1),
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
    String twoDigitMinutes = twoDigits(d.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(d.inSeconds.remainder(60));
    return "${twoDigits(d.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

  Widget _buildMiniHeader(
    BuildContext context,
    PrayerProvider provider,
    String nextName,
  ) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final countdown = provider.timeUntilNextPrayer.inSeconds > 0
        ? _formatDuration(provider.timeUntilNextPrayer)
        : '--:--:--';

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
                color: theme.shadowColor.withOpacity(0.1),
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
                size: 16.sp,
                color: colorScheme.primary, // اللون الأساسي للتطبيق
              ),
              SizedBox(width: 6.w),
              Text(
                'باقي لـ $nextName: $countdown',
                style: TextStyle(
                  color: colorScheme.primary, // اللون الأساسي للتطبيق
                  fontWeight: FontWeight.bold,
                  fontSize: 13.sp,
                ),
              ),
            ],
          ),
        ),
        const Spacer(),
        Container(
          decoration: BoxDecoration(
            color: colorScheme.surface.withOpacity(0.2),
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
