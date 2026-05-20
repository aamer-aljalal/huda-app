import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/Routes/AppRoutes.dart';
import 'package:tarteel/core/providers/prayer_provider.dart';
import 'package:tarteel/core/services/in_app_notification_service.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:intl/intl.dart';

class HomeMiniHeader extends StatelessWidget {
  const HomeMiniHeader({
    super.key,
    required this.provider,
    required this.nextName,
    required this.activeNotifications,
    required this.onNotificationTap,
  });

  final PrayerProvider provider;
  final String nextName;
  final List<InAppNotification> activeNotifications;
  final VoidCallback onNotificationTap;

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);

    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final now = DateTime.now();
    final timeDigits = DateFormat('h:mm', 'en').format(now);
    final amPmEn = DateFormat('a', 'en').format(now); // "AM" or "PM"
    final amPmAr = amPmEn == 'AM' ? 'ص' : 'م';
    final currentTime = '$timeDigits $amPmAr';

    String dayName = '';
    switch (now.weekday) {
      case DateTime.monday:
        dayName = 'الإثنين';
        break;
      case DateTime.tuesday:
        dayName = 'الثلاثاء';
        break;
      case DateTime.wednesday:
        dayName = 'الأربعاء';
        break;
      case DateTime.thursday:
        dayName = 'الخميس';
        break;
      case DateTime.friday:
        dayName = 'الجمعة';
        break;
      case DateTime.saturday:
        dayName = 'السبت';
        break;
      case DateTime.sunday:
        dayName = 'الأحد';
        break;
    }
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 6.h),
          decoration: BoxDecoration(
            border: Border.all(
              color: brightness == Brightness.dark
                  ? AppColors.greenBorder.withOpacity(0.50)
                  : AppColors.disabled,
              width: 2.w,
            ),

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
                '$currentTime  •  $dayName',
                style: TextStyle(
                  color: colorScheme.primary, // اللون الأساسي للتطبيق
                  fontWeight: FontWeight.bold,
                  fontSize: 12.sp,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),

        const Spacer(),

        SizedBox(width: 6.w),
        _buildHeaderActionButton(
          context: context,
          icon: Icons.favorite_outline,
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.bookmarks);
          },
        ),

        SizedBox(width: 2.w),

        _buildHeaderActionButton(
          context: context,
          icon: Icons.settings_outlined,
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.settings);
          },
        ),
        SizedBox(width: 2.w),

        _buildHeaderActionButton(
          context: context,
          icon: Icons.explore_outlined,
          onPressed: () {
            Navigator.pushNamed(context, AppRoutes.qibla);
          },
        ),
        SizedBox(width: 2.w),

        Stack(
          clipBehavior: Clip.none,
          children: [
            _buildHeaderActionButton(
              context: context,
              icon: activeNotifications.isNotEmpty
                  ? Icons.notifications_active_outlined
                  : Icons.notifications_none,
              onPressed: onNotificationTap,
            ),
            if (activeNotifications.isNotEmpty)
              Positioned(
                top: -2.h,
                right: -2.w,
                child: Container(
                  padding: EdgeInsets.all(4.w),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  constraints: BoxConstraints(minWidth: 12.w, minHeight: 15.h),
                  child: Text(
                    '${activeNotifications.length}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 8.sp,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildHeaderActionButton({
    required BuildContext context,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 42.w,
      height: 42.h,
      decoration: BoxDecoration(
        // border: Border.all(color: AppColors.goldAccent),
        border: Border.all(color: AppColors.darkPrimaryText),
        color: colorScheme.surface.withValues(alpha: 0.3),
        shape: BoxShape.circle,
      ),

      child: IconButton(
        icon: Icon(icon, color: Colors.white),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        iconSize: 22,
      ),
    );
  }
}
