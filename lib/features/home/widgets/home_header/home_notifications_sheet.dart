import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/services/in_app_notification_service.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:intl/intl.dart';

class HomeNotificationsSheet extends StatelessWidget {
  const HomeNotificationsSheet({
    super.key,
    required this.notifications,
    required this.onNotificationTap,
  });

  final List<InAppNotification> notifications;

  final Future<void> Function(InAppNotification notification) onNotificationTap;
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
            boxShadow: const [
              BoxShadow(color: Colors.black26, blurRadius: 10, spreadRadius: 1),
            ],
          ),
          padding: EdgeInsets.only(
            top: 14.h,
            left: 16.w,
            right: 16.w,
            bottom: 20.h,
          ),
          child: Directionality(
            textDirection: ui.TextDirection.rtl,
            child: Column(
              children: [
                // Drag Indicator
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.grey.shade300,
                    ),
                  ),
                ),
                SizedBox(height: 16.h),
                // Title
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'تنبيهات اليوم الفائتة',
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primary,
                      ),
                    ),
                    if (notifications.isNotEmpty)
                      Container(
                        padding: EdgeInsets.symmetric(
                          horizontal: 8.w,
                          vertical: 4.h,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade700.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Text(
                          '${notifications.length} معلقة',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(height: 16.h),
                // Notifications list
                Expanded(
                  child: notifications.isEmpty
                      ? _buildEmptyState(isDark)
                      : ListView.separated(
                          controller: scrollController,
                          itemCount: notifications.length,
                          separatorBuilder: (context, index) =>
                              SizedBox(height: 10.h),
                          itemBuilder: (context, index) {
                            final notif = notifications[index];
                            return InkWell(
                              onTap: () async {
                                Navigator.pop(context); // Close bottom sheet
                                await onNotificationTap(notif);
                                // _loadNotifications(); // Reload to refresh badge and list!
                              },
                              borderRadius: BorderRadius.circular(16.r),
                              child: Container(
                                padding: EdgeInsets.all(12.w),
                                decoration: BoxDecoration(
                                  color: cardBg,
                                  borderRadius: BorderRadius.circular(16.r),
                                  border: Border.all(
                                    color: isDark
                                        ? Colors.white10
                                        : Colors.grey.shade100,
                                    width: 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    // Colored Icon circle
                                    Container(
                                      padding: EdgeInsets.all(10.w),
                                      decoration: BoxDecoration(
                                        color: notif.color.withValues(
                                          alpha: 0.1,
                                        ),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        notif.icon,
                                        color: notif.color,
                                        size: 22.sp,
                                      ),
                                    ),
                                    SizedBox(width: 12.w),
                                    // Content
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.spaceBetween,
                                            children: [
                                              Text(
                                                notif.title,
                                                style: TextStyle(
                                                  fontSize: 13.sp,
                                                  fontWeight: FontWeight.w800,
                                                  color: isDark
                                                      ? Colors.white
                                                      : Colors.black87,
                                                ),
                                              ),
                                              Text(
                                                DateFormat(
                                                  'hh:mm a',
                                                  'ar',
                                                ).format(notif.triggerTime),
                                                style: TextStyle(
                                                  fontSize: 9.sp,
                                                  color: Colors.grey.shade500,
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(height: 4.h),
                                          Text(
                                            notif.body,
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                              fontSize: 11.sp,
                                              height: 1.4,
                                              color: isDark
                                                  ? Colors.white60
                                                  : Colors.grey.shade700,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    SizedBox(width: 8.w),
                                    Icon(
                                      Icons.arrow_back_ios_new_rounded,
                                      size: 14.sp,
                                      color: Colors.grey.shade400,
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              color: Colors.green.shade500.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.done_all_rounded,
              color: Colors.green.shade600,
              size: 40.sp,
            ),
          ),
          SizedBox(height: 16.h),
          Text(
            'ما شاء الله! يومك مبارك',
            style: TextStyle(
              fontSize: 14.sp,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          SizedBox(height: 6.h),
          Text(
            'لا توجد تنبيهات فائتة اليوم. تقبل الله طاعتك',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }
}
