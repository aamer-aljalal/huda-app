// import 'dart:ui' as ui;
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:tarteel/core/theme/app_colors.dart';
// import 'package:intl/intl.dart';
// import 'package:provider/provider.dart';
// import 'package:tarteel/core/providers/prayer_provider.dart';
// import 'package:adhan/adhan.dart';
// import 'package:hijri/hijri_calendar.dart';
// import 'package:tarteel/routes/AppRoutes.dart';
// import 'package:tarteel/core/services/recent_actions_service.dart';
// import 'package:tarteel/features/quran/services/quran_service.dart';
// import 'package:tarteel/features/quran/views/surah_detail_page.dart';
// import 'package:tarteel/features/azkar/services/azkar_service.dart';
// import 'package:tarteel/features/azkar/zkar_details.dart';
// import 'package:tarteel/core/services/in_app_notification_service.dart';

// class HomeHeader extends StatefulWidget {
//   const HomeHeader({super.key});

//   @override
//   State<HomeHeader> createState() => _HomeHeaderState();
// }

// class _HomeHeaderState extends State<HomeHeader> {
//   bool _isNumericFormat = false;
//   List<InAppNotification> _activeNotifications = [];

//   @override
//   void initState() {
//     super.initState();
//     _loadNotifications();
//   }

//   Future<void> _loadNotifications() async {
//     try {
//       final list = await InAppNotificationService.getActiveNotifications();
//       if (mounted) {
//         setState(() {
//           _activeNotifications = list;
//         });
//       }
//     } catch (_) {}
//   }

//   void _showNotificationsBottomSheet(BuildContext context) {
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setModalState) {
//             final isDark = Theme.of(context).brightness == Brightness.dark;
//             final cardBg = isDark
//                 ? const Color(0xFF2C2C2C)
//                 : Colors.grey.shade50;

//             return DraggableScrollableSheet(
//               initialChildSize: 0.6,
//               minChildSize: 0.4,
//               maxChildSize: 0.9,
//               builder: (context, scrollController) {
//                 return Container(
//                   decoration: BoxDecoration(
//                     color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
//                     borderRadius: BorderRadius.vertical(
//                       top: Radius.circular(24.r),
//                     ),
//                     boxShadow: const [
//                       BoxShadow(
//                         color: Colors.black26,
//                         blurRadius: 10,
//                         spreadRadius: 1,
//                       ),
//                     ],
//                   ),
//                   padding: EdgeInsets.only(
//                     top: 14.h,
//                     left: 16.w,
//                     right: 16.w,
//                     bottom: 20.h,
//                   ),
//                   child: Directionality(
//                     textDirection: ui.TextDirection.rtl,
//                     child: Column(
//                       children: [
//                         // Drag Indicator
//                         Center(
//                           child: Container(
//                             width: 40.w,
//                             height: 4.h,
//                             decoration: BoxDecoration(
//                               color: isDark
//                                   ? Colors.white24
//                                   : Colors.grey.shade300,
//                               borderRadius: BorderRadius.circular(10.r),
//                             ),
//                           ),
//                         ),
//                         SizedBox(height: 16.h),
//                         // Title
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                           children: [
//                             Text(
//                               'تنبيهات اليوم الفائتة',
//                               style: TextStyle(
//                                 fontSize: 16.sp,
//                                 fontWeight: FontWeight.w900,
//                                 color: AppColors.primary,
//                               ),
//                             ),
//                             if (_activeNotifications.isNotEmpty)
//                               Container(
//                                 padding: EdgeInsets.symmetric(
//                                   horizontal: 8.w,
//                                   vertical: 4.h,
//                                 ),
//                                 decoration: BoxDecoration(
//                                   color: Colors.red.shade700.withValues(
//                                     alpha: 0.1,
//                                   ),
//                                   borderRadius: BorderRadius.circular(12.r),
//                                 ),
//                                 child: Text(
//                                   '${_activeNotifications.length} معلقة',
//                                   style: TextStyle(
//                                     color: Colors.red.shade700,
//                                     fontSize: 10.sp,
//                                     fontWeight: FontWeight.bold,
//                                   ),
//                                 ),
//                               ),
//                           ],
//                         ),
//                         SizedBox(height: 16.h),
//                         // Notifications list
//                         Expanded(
//                           child: _activeNotifications.isEmpty
//                               ? _buildEmptyState(isDark)
//                               : ListView.separated(
//                                   controller: scrollController,
//                                   itemCount: _activeNotifications.length,
//                                   separatorBuilder: (context, index) =>
//                                       SizedBox(height: 10.h),
//                                   itemBuilder: (context, index) {
//                                     final notif = _activeNotifications[index];
//                                     return InkWell(
//                                       onTap: () async {
//                                         Navigator.pop(
//                                           context,
//                                         ); // Close bottom sheet
//                                         await _handleNotificationClick(notif);
//                                         _loadNotifications(); // Reload to refresh badge and list!
//                                       },
//                                       borderRadius: BorderRadius.circular(16.r),
//                                       child: Container(
//                                         padding: EdgeInsets.all(12.w),
//                                         decoration: BoxDecoration(
//                                           color: cardBg,
//                                           borderRadius: BorderRadius.circular(
//                                             16.r,
//                                           ),
//                                           border: Border.all(
//                                             color: isDark
//                                                 ? Colors.white10
//                                                 : Colors.grey.shade100,
//                                             width: 1,
//                                           ),
//                                         ),
//                                         child: Row(
//                                           children: [
//                                             // Colored Icon circle
//                                             Container(
//                                               padding: EdgeInsets.all(10.w),
//                                               decoration: BoxDecoration(
//                                                 color: notif.color.withValues(
//                                                   alpha: 0.1,
//                                                 ),
//                                                 shape: BoxShape.circle,
//                                               ),
//                                               child: Icon(
//                                                 notif.icon,
//                                                 color: notif.color,
//                                                 size: 22.sp,
//                                               ),
//                                             ),
//                                             SizedBox(width: 12.w),
//                                             // Content
//                                             Expanded(
//                                               child: Column(
//                                                 crossAxisAlignment:
//                                                     CrossAxisAlignment.start,
//                                                 children: [
//                                                   Row(
//                                                     mainAxisAlignment:
//                                                         MainAxisAlignment
//                                                             .spaceBetween,
//                                                     children: [
//                                                       Text(
//                                                         notif.title,
//                                                         style: TextStyle(
//                                                           fontSize: 13.sp,
//                                                           fontWeight:
//                                                               FontWeight.w800,
//                                                           color: isDark
//                                                               ? Colors.white
//                                                               : Colors.black87,
//                                                         ),
//                                                       ),
//                                                       Text(
//                                                         DateFormat(
//                                                           'hh:mm a',
//                                                           'ar',
//                                                         ).format(
//                                                           notif.triggerTime,
//                                                         ),
//                                                         style: TextStyle(
//                                                           fontSize: 9.sp,
//                                                           color: Colors
//                                                               .grey
//                                                               .shade500,
//                                                         ),
//                                                       ),
//                                                     ],
//                                                   ),
//                                                   SizedBox(height: 4.h),
//                                                   Text(
//                                                     notif.body,
//                                                     maxLines: 2,
//                                                     overflow:
//                                                         TextOverflow.ellipsis,
//                                                     style: TextStyle(
//                                                       fontSize: 11.sp,
//                                                       height: 1.4,
//                                                       color: isDark
//                                                           ? Colors.white60
//                                                           : Colors
//                                                                 .grey
//                                                                 .shade700,
//                                                     ),
//                                                   ),
//                                                 ],
//                                               ),
//                                             ),
//                                             SizedBox(width: 8.w),
//                                             Icon(
//                                               Icons.arrow_back_ios_new_rounded,
//                                               size: 14.sp,
//                                               color: Colors.grey.shade400,
//                                             ),
//                                           ],
//                                         ),
//                                       ),
//                                     );
//                                   },
//                                 ),
//                         ),
//                       ],
//                     ),
//                   ),
//                 );
//               },
//             );
//           },
//         );
//       },
//     );
//   }

//   Widget _buildEmptyState(bool isDark) {
//     return Center(
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.center,
//         children: [
//           Container(
//             padding: EdgeInsets.all(16.w),
//             decoration: BoxDecoration(
//               color: Colors.green.shade500.withValues(alpha: 0.1),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(
//               Icons.done_all_rounded,
//               color: Colors.green.shade600,
//               size: 40.sp,
//             ),
//           ),
//           SizedBox(height: 16.h),
//           Text(
//             'ما شاء الله! يومك مبارك',
//             style: TextStyle(
//               fontSize: 14.sp,
//               fontWeight: FontWeight.w800,
//               color: isDark ? Colors.white : Colors.black87,
//             ),
//           ),
//           SizedBox(height: 6.h),
//           Text(
//             'لا توجد تنبيهات فائتة اليوم. تقبل الله طاعتك',
//             textAlign: TextAlign.center,
//             style: TextStyle(fontSize: 11.sp, color: Colors.grey.shade500),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _handleNotificationClick(InAppNotification notif) async {
//     if (notif.type == 'surah_kahf') {
//       try {
//         final surahs = await QuranService.loadSurahs();
//         final kahfSurah = surahs.firstWhere((s) => s.number == 18);
//         final ayahs = await QuranService.loadAyahs(18);

//         if (!mounted) return;
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) =>
//                 SurahDetailPage(surah: kahfSurah, ayahs: ayahs),
//           ),
//         ).then((_) => _loadNotifications());
//       } catch (_) {}
//     } else if (notif.type == 'morning_azkar' ||
//         notif.type == 'evening_azkar' ||
//         notif.type == 'sleep_azkar') {
//       try {
//         final targetTitle = notif.type == 'morning_azkar'
//             ? 'أذكار الصباح'
//             : notif.type == 'evening_azkar'
//             ? 'أذكار المساء'
//             : 'أذكار النوم';
//         final categories = await AzkarService.loadAzkar();
//         final match = categories.firstWhere((c) => c.title == targetTitle);

//         if (!mounted) return;
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (context) => AzkarDetailsScreen(category: match),
//           ),
//         ).then((_) => _loadNotifications());
//       } catch (_) {}
//     } else {
//       await InAppNotificationService.markCompleted(notif.type);

//       String message = 'تقبل الله طاعتك وصالح أعمالك';
//       if (notif.type == 'fasting') {
//         message = 'تقبل الله صيامك وطاعتك المباركة';
//       } else if (notif.type == 'daily_content') {
//         message = 'تم الإطلاع على آية وحديث اليوم بنجاح';
//         if (mounted) {
//           Navigator.pushNamed(
//             context,
//             AppRoutes.hadith,
//           ).then((_) => _loadNotifications());
//         }
//       }

//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//             content: Text(message, textAlign: TextAlign.right),
//             backgroundColor: AppColors.primary,
//           ),
//         );
//       }
//     }
//   }

//   String _getGregorianDate(bool isNumeric) {
//     final now = DateTime.now();
//     final day = DateFormat('d', 'en').format(now);
//     final year = DateFormat('yyyy', 'en').format(now);
//     if (isNumeric) {
//       final month = DateFormat('M', 'en').format(now);
//       return '\u200F$day / $month / \u200F$year';
//     } else {
//       final month = DateFormat('MMMM', 'ar').format(now);
//       return '\u200F$day $month \u200F$year';
//     }
//   }

//   String _getHijriDate(bool isNumeric) {
//     HijriCalendar.setLocal('ar');
//     final hijri = HijriCalendar.now();
//     final day = hijri.hDay;
//     final year = hijri.hYear;
//     if (isNumeric) {
//       final month = hijri.hMonth;
//       return '\u200F$day / $month / \u200F$year';
//     } else {
//       final month = hijri.getLongMonthName();
//       return '\u200F$day $month \u200F$year';
//     }
//   }

//   IconData _getPrayerIcon(String prayerName) {
//     switch (prayerName) {
//       case 'الفجر':
//         return Icons.wb_twilight_rounded;
//       case 'الظهر':
//         return Icons.wb_sunny_rounded;
//       case 'العصر':
//         return Icons.wb_sunny_outlined;
//       case 'المغرب':
//         return Icons.brightness_medium_rounded;
//       case 'العشاء':
//         return Icons.nights_stay_rounded;
//       default:
//         return Icons.access_time_rounded;
//     }
//   }

//   Future<void> _resumeQuran(BuildContext context, int surahNumber) async {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => const Center(child: CircularProgressIndicator()),
//     );

//     try {
//       final surahs = await QuranService.loadSurahs();
//       final surah = surahs.firstWhere((s) => s.number == surahNumber);
//       final ayahs = await QuranService.loadAyahs(surahNumber);

//       if (context.mounted) {
//         Navigator.pop(context); // Close dialog
//         Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => SurahDetailPage(
//               surah: surah,
//               ayahs: ayahs,
//               resumeLastPage: true,
//             ),
//           ),
//         );
//       }
//     } catch (_) {
//       if (context.mounted) {
//         Navigator.pop(context); // Close dialog
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(content: Text('تعذر فتح الصفحة المحفوظة')),
//         );
//       }
//     }
//   }

//   Future<void> _resumeAzkar(BuildContext context, String categoryTitle) async {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => const Center(child: CircularProgressIndicator()),
//     );

//     try {
//       final categories = await AzkarService.loadAzkar();
//       final category = categories.firstWhere((c) => c.title == categoryTitle);

//       if (context.mounted) {
//         Navigator.pop(context); // Close dialog
//         Navigator.pushNamed(
//           context,
//           AppRoutes.zkarDetails,
//           arguments: category,
//         );
//       }
//     } catch (_) {
//       if (context.mounted) {
//         Navigator.pop(context); // Close dialog
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(const SnackBar(content: Text('تعذر فتح الأذكار')));
//       }
//     }
//   }

//   Future<void> _resumeHadith(BuildContext context, int hadithNumber) async {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) => const Center(child: CircularProgressIndicator()),
//     );

//     try {
//       if (context.mounted) {
//         Navigator.pop(context); // Close dialog
//         Navigator.pushNamed(context, AppRoutes.hadith, arguments: hadithNumber);
//       }
//     } catch (_) {
//       if (context.mounted) {
//         Navigator.pop(context); // Close dialog
//         ScaffoldMessenger.of(
//           context,
//         ).showSnackBar(const SnackBar(content: Text('تعذر فتح الحديث')));
//       }
//     }
//   }

//   void _handleRecentActionTap(BuildContext context, RecentAction action) {
//     HapticFeedback.lightImpact();
//     if (action.category == 'quran') {
//       final surahNumber = action.extraData['surah_number'] as int?;
//       if (surahNumber != null) {
//         _resumeQuran(context, surahNumber);
//       }
//     } else if (action.category == 'azkar') {
//       final categoryTitle = action.extraData['category_title'] as String?;
//       if (categoryTitle != null) {
//         _resumeAzkar(context, categoryTitle);
//       }
//     } else if (action.category == 'hadith') {
//       final hadithNumber = action.extraData['hadith_number'] as int?;
//       if (hadithNumber != null) {
//         _resumeHadith(context, hadithNumber);
//       }
//     }
//   }

//   Widget _buildRecentButton(BuildContext context, RecentAction action) {
//     IconData getIcon() {
//       switch (action.category) {
//         case 'quran':
//           return Icons.menu_book_rounded;
//         case 'azkar':
//           return Icons.bookmark_added_rounded;
//         case 'hadith':
//           return Icons.auto_stories_rounded;
//         case 'names_of_allah':
//           return Icons.auto_awesome_rounded;
//         default:
//           return Icons.history_toggle_off_rounded;
//       }
//     }

//     Color getCategoryColor(ColorScheme colorScheme) {
//       switch (action.category) {
//         case 'quran':
//           return Colors.greenAccent;
//         case 'azkar':
//           return Colors.amberAccent;
//         case 'hadith':
//           return Colors.orangeAccent;
//         case 'names_of_allah':
//           return Colors.cyanAccent;
//         default:
//           return Colors.white70;
//       }
//     }

//     return Expanded(
//       child: InkWell(
//         onTap: () => _handleRecentActionTap(context, action),
//         borderRadius: BorderRadius.circular(12.r),
//         child: Column(
//           // mainAxisSize: MainAxisSize.min,
//           children: [
//             Container(
//               padding: EdgeInsets.all(6.w),
//               decoration: BoxDecoration(
//                 border: Border.all(color: AppColors.darkPrimaryText),

//                 color: Theme.of(
//                   context,
//                 ).colorScheme.surface.withValues(alpha: 0.22),
//                 shape: BoxShape.circle,
//               ),
//               child: Icon(
//                 getIcon(),
//                 size: 16.sp,
//                 // color: getCategoryColor(Theme.of(context).colorScheme),
//                 color: Colors.white,
//               ),
//             ),
//             SizedBox(height: 2.h),
//             Text(
//               '${action.title.replaceAll('سورة ', '')}',
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               textAlign: TextAlign.center,
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: 7.5.sp,
//                 fontWeight: FontWeight.bold,
//                 fontFamily: 'Cairo',
//               ),
//             ),
//             SizedBox(height: 2.h),
//           ],
//         ),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final prayerProvider = Provider.of<PrayerProvider>(context);
//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;

//     final currentPrayerTimes = {
//       'الفجر': prayerProvider.getFormattedPrayerTime(Prayer.fajr),
//       'الظهر': prayerProvider.getFormattedPrayerTime(Prayer.dhuhr),
//       'العصر': prayerProvider.getFormattedPrayerTime(Prayer.asr),
//       'المغرب': prayerProvider.getFormattedPrayerTime(Prayer.maghrib),
//       'العشاء': prayerProvider.getFormattedPrayerTime(Prayer.isha),
//     };

//     final dynamicNextPrayer =
//         prayerProvider.nextPrayer != null &&
//             prayerProvider.nextPrayer != Prayer.none
//         ? prayerProvider.getPrayerName(prayerProvider.nextPrayer!)
//         : '...';

//     final countdown = prayerProvider.timeUntilNextPrayer.inSeconds > 0
//         ? _formatDuration(prayerProvider.timeUntilNextPrayer)
//         : '--:--';

//     return SliverAppBar(
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.vertical(bottom: Radius.circular(10.r)),
//       ),
//       automaticallyImplyLeading: false,
//       toolbarHeight: 80.h,
//       expandedHeight: 380.h,
//       pinned: true,
//       backgroundColor: colorScheme.primary,
//       elevation: 0,
//       flexibleSpace: FlexibleSpaceBar(
//         background: Container(
//           decoration: BoxDecoration(
//             image: const DecorationImage(
//               image: AssetImage('assets/img/header_bg.png'),
//               fit: BoxFit.cover,
//             ),
//             borderRadius: BorderRadius.vertical(bottom: Radius.circular(5.r)),
//             boxShadow: [
//               BoxShadow(
//                 color: theme.shadowColor.withOpacity(
//                   0.2,
//                 ), // تظليل متوافق مع الثيم
//                 blurRadius: 10,
//                 offset: Offset(0, 5),
//               ),
//             ],
//           ),
//           child: SafeArea(
//             bottom: false,
//             child: Padding(
//               padding: EdgeInsets.fromLTRB(20, 50, 20, 24),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   const Spacer(flex: 2),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             _isNumericFormat = !_isNumericFormat;
//                           });
//                           HapticFeedback.lightImpact();
//                         },
//                         behavior: HitTestBehavior.opaque,
//                         child: Row(
//                           children: [
//                             Icon(
//                               Icons.calendar_today,
//                               size: 14.sp,
//                               color: Colors.white,
//                             ),
//                             SizedBox(width: 6.w),
//                             Text(
//                               _getHijriDate(_isNumericFormat),
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 13.sp,
//                                 fontFamily: 'Amiri',
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                     children: [
//                       GestureDetector(
//                         onTap: () {
//                           setState(() {
//                             _isNumericFormat = !_isNumericFormat;
//                           });
//                           HapticFeedback.lightImpact();
//                         },
//                         behavior: HitTestBehavior.opaque,
//                         child: Text(
//                           _getGregorianDate(_isNumericFormat),
//                           style: TextStyle(
//                             color: Colors.white70,
//                             fontSize: 13.sp,
//                             fontFamily: 'Amiri',
//                           ),
//                         ),
//                       ),

//                       Container(
//                         padding: EdgeInsets.symmetric(
//                           horizontal: 12.w,
//                           vertical: 6.h,
//                         ),
//                         decoration: BoxDecoration(
//                           // استخدام لون السطح مع شفافية ليتناسب مع الوضعين
//                           color: colorScheme.surface.withOpacity(0.25),
//                           borderRadius: BorderRadius.circular(30.r),
//                         ),
//                         child: Row(
//                           mainAxisAlignment: MainAxisAlignment.center,
//                           children: [
//                             Icon(
//                               Icons.location_on,
//                               size: 16.sp,
//                               color: Colors.white,
//                             ),
//                             SizedBox(width: 6.w),
//                             Text(
//                               prayerProvider.cityName.isNotEmpty
//                                   ? 'بتوقيت : ${prayerProvider.cityName}'
//                                   : prayerProvider.cityName,
//                               style: TextStyle(
//                                 color: Colors.white,
//                                 fontSize: 10.sp,
//                                 fontFamily: 'Cairo',
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                     ],
//                   ),

//                   // بطاقة أوقات الصلاة الأفقية
//                   Container(
//                     padding: EdgeInsets.only(
//                       right: 8.w,
//                       left: 8.w,
//                       bottom: 6.h,
//                     ),
//                     margin: EdgeInsets.symmetric(vertical: 8.h),
//                     decoration: BoxDecoration(
//                       // استخدام ألوان الثيم للبطاقة الشفافة
//                       color: colorScheme.surface.withOpacity(0.15),
//                       borderRadius: BorderRadius.circular(12.r),
//                       border: Border.all(
//                         color: colorScheme.onSurface.withOpacity(0.1),
//                       ),
//                     ),

//                     child: Column(
//                       crossAxisAlignment: CrossAxisAlignment.start,
//                       children: [
//                         Padding(
//                           padding: EdgeInsets.symmetric(
//                             horizontal: 8.w,
//                             vertical: 4.h,
//                           ),
//                           child: Row(
//                             mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                             children: [
//                               // كم المتبقي للصلاة القادمة (في اليسار)
//                               Row(
//                                 children: [
//                                   Text(
//                                     '$countdown : ',
//                                     style: TextStyle(
//                                       fontSize: 11.sp,
//                                       fontWeight: FontWeight.bold,
//                                       color: Colors.white,
//                                       fontFamily: 'Amiri',
//                                     ),
//                                   ),
//                                   Text(
//                                     'متبقي لـ $dynamicNextPrayer',
//                                     style: TextStyle(
//                                       fontSize: 11.sp,
//                                       fontWeight: FontWeight.w600,
//                                       color: Colors.amberAccent,
//                                       fontFamily: 'Cairo',
//                                     ),
//                                   ),
//                                 ],
//                               ),
//                               // عنوان مواقيت الصلاة (في اليمين)
//                               Text(
//                                 'مواقيت الصلاة',
//                                 style: TextStyle(
//                                   fontSize: 12.sp,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.white,
//                                   fontFamily: 'Cairo',
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                         Row(
//                           mainAxisAlignment: MainAxisAlignment.spaceAround,
//                           children: currentPrayerTimes.entries.map((entry) {
//                             final isNext = entry.key == dynamicNextPrayer;
//                             return AnimatedContainer(
//                               duration: const Duration(milliseconds: 300),
//                               padding: EdgeInsets.symmetric(
//                                 vertical: isNext ? 4 : 0,
//                               ),
//                               decoration: BoxDecoration(
//                                 // border: Border.all(
//                                 //   color: isNext
//                                 //       ? AppColors.goldAccent
//                                 //       : Colors.transparent,
//                                 // ),
//                                 color: isNext
//                                     ? colorScheme.surface.withOpacity(0.3)
//                                     : Colors.transparent,
//                                 borderRadius: BorderRadius.circular(8.r),
//                               ),
//                               child: Padding(
//                                 padding: EdgeInsets.symmetric(
//                                   horizontal: 10.w,
//                                   vertical: 0.3.h,
//                                 ),
//                                 child: Column(
//                                   mainAxisSize: MainAxisSize.min,
//                                   children: [
//                                     Icon(
//                                       _getPrayerIcon(entry.key),
//                                       size: 16.sp,
//                                       color: isNext
//                                           ? Colors.amberAccent
//                                           : Colors.white70,
//                                     ),
//                                     SizedBox(height: 4.h),
//                                     Text(
//                                       entry.key,
//                                       style: TextStyle(
//                                         color: isNext
//                                             ? Colors.amberAccent
//                                             : Colors.white70,
//                                         fontSize: 11.sp,
//                                         fontWeight: isNext
//                                             ? FontWeight.bold
//                                             : FontWeight.w600,
//                                         fontFamily: 'Cairo',
//                                       ),
//                                     ),
//                                     SizedBox(height: 6.h),
//                                     Text(
//                                       entry.value,
//                                       style: TextStyle(
//                                         color: isNext
//                                             ? Colors.amberAccent
//                                             : Colors.white,
//                                         fontSize: 10.sp,
//                                         fontFamily: 'Amiri',

//                                         fontWeight: FontWeight.bold,
//                                       ),
//                                     ),
//                                     if (isNext) ...[
//                                       SizedBox(height: 6.h),
//                                       Icon(
//                                         Icons.arrow_upward,
//                                         color: Colors.amberAccent,
//                                         size: 14.sp,
//                                       ),
//                                     ],
//                                   ],
//                                 ),
//                               ),
//                             );
//                           }).toList(),
//                         ),
//                       ],
//                     ),
//                   ),
//                   FutureBuilder<List<RecentAction>>(
//                     future: RecentActionsManager.getActions(),
//                     builder: (context, snapshot) {
//                       if (!snapshot.hasData || snapshot.data!.isEmpty) {
//                         return const SizedBox.shrink();
//                       }
//                       final actions = snapshot.data!;
//                       return Container(
//                         padding: EdgeInsets.symmetric(horizontal: 10.w),
//                         decoration: BoxDecoration(
//                           color: colorScheme.surface.withValues(alpha: 0.15),
//                           borderRadius: BorderRadius.circular(12.r),
//                           border: Border.all(
//                             color: colorScheme.onSurface.withValues(alpha: 0.1),
//                           ),
//                         ),
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             SizedBox(height: 3.h),
//                             Row(
//                               mainAxisAlignment: MainAxisAlignment.spaceAround,
//                               children: actions
//                                   .map(
//                                     (action) =>
//                                         _buildRecentButton(context, action),
//                                   )
//                                   .toList(),
//                             ),
//                           ],
//                         ),
//                       );
//                     },
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//         collapseMode: CollapseMode.parallax,
//       ),
//       title: _buildMiniHeader(
//         context, // تمرير الـ context لاستخدام الثيم
//         prayerProvider,
//         dynamicNextPrayer,
//       ),
//       systemOverlayStyle: SystemUiOverlayStyle.light,
//     );
//   }

//   String _formatDuration(Duration d) {
//     String twoDigits(int n) => n.toString().padLeft(2, "0");
//     int hours = d.inHours;
//     int minutes = d.inMinutes.remainder(60);
//     return "$hours:${twoDigits(minutes)}";
//   }

//   Widget _buildMiniHeader(
//     BuildContext context,
//     PrayerProvider provider,
//     String nextName,
//   ) {
//     final brightness = MediaQuery.platformBrightnessOf(context);

//     final theme = Theme.of(context);
//     final colorScheme = theme.colorScheme;

//     final now = DateTime.now();
//     final timeDigits = DateFormat('h:mm', 'en').format(now);
//     final amPmEn = DateFormat('a', 'en').format(now); // "AM" or "PM"
//     final amPmAr = amPmEn == 'AM' ? 'ص' : 'م';
//     final currentTime = '$timeDigits $amPmAr';

//     String dayName = '';
//     switch (now.weekday) {
//       case DateTime.monday:
//         dayName = 'الإثنين';
//         break;
//       case DateTime.tuesday:
//         dayName = 'الثلاثاء';
//         break;
//       case DateTime.wednesday:
//         dayName = 'الأربعاء';
//         break;
//       case DateTime.thursday:
//         dayName = 'الخميس';
//         break;
//       case DateTime.friday:
//         dayName = 'الجمعة';
//         break;
//       case DateTime.saturday:
//         dayName = 'السبت';
//         break;
//       case DateTime.sunday:
//         dayName = 'الأحد';
//         break;
//     }

//     return Row(
//       children: [
//         Container(
//           padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
//           decoration: BoxDecoration(
//             border: Border.all(
//               color: brightness == Brightness.dark
//                   ? AppColors.greenBorder.withOpacity(0.50)
//                   : AppColors.disabled,
//               width: 2.w,
//             ),

//             // استخدام ألوان الوضع الليلي/النهاري بدلاً من ألوان ثابتة
//             color: colorScheme.surface,
//             borderRadius: BorderRadius.circular(30.r),
//             boxShadow: [
//               BoxShadow(
//                 color: theme.shadowColor.withValues(alpha: 0.1),
//                 blurRadius: 4,
//                 offset: const Offset(0, 2),
//               ),
//             ],
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Icon(
//                 Icons.access_time,
//                 size: 17.sp,
//                 color: colorScheme.primary, // اللون الأساسي للتطبيق
//               ),
//               SizedBox(width: 6.w),
//               Text(
//                 '$currentTime  •  $dayName',
//                 style: TextStyle(
//                   color: colorScheme.primary, // اللون الأساسي للتطبيق
//                   fontWeight: FontWeight.bold,
//                   fontSize: 12.sp,
//                   fontFamily: 'Cairo',
//                 ),
//               ),
//             ],
//           ),
//         ),
//         const Spacer(),
//         _buildHeaderActionButton(
//           context: context,
//           icon: Icons.bookmark_border_rounded,
//           onPressed: () {
//             Navigator.pushNamed(context, AppRoutes.bookmarks);
//           },
//         ),

//         SizedBox(width: 8.w),

//         _buildHeaderActionButton(
//           context: context,
//           icon: Icons.settings_outlined,
//           onPressed: () {
//             Navigator.pushNamed(context, AppRoutes.settings);
//           },
//         ),

//         SizedBox(width: 8.w),

//         Stack(
//           clipBehavior: Clip.none,
//           children: [
//             _buildHeaderActionButton(
//               context: context,
//               icon: _activeNotifications.isNotEmpty
//                   ? Icons.notifications_active_outlined
//                   : Icons.notifications_none,
//               onPressed: () => _showNotificationsBottomSheet(context),
//             ),
//             if (_activeNotifications.isNotEmpty)
//               Positioned(
//                 top: -2.h,
//                 right: -2.w,
//                 child: Container(
//                   padding: EdgeInsets.all(4.w),
//                   decoration: const BoxDecoration(
//                     color: Colors.red,
//                     shape: BoxShape.circle,
//                   ),
//                   constraints: BoxConstraints(minWidth: 16.w, minHeight: 16.h),
//                   child: Text(
//                     '${_activeNotifications.length}',
//                     textAlign: TextAlign.center,
//                     style: TextStyle(
//                       color: Colors.white,
//                       fontSize: 8.sp,
//                       fontWeight: FontWeight.bold,
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ],
//     );
//   }

//   Widget _buildHeaderActionButton({
//     required BuildContext context,
//     required IconData icon,
//     required VoidCallback onPressed,
//   }) {
//     final colorScheme = Theme.of(context).colorScheme;

//     return Container(
//       decoration: BoxDecoration(
//         // border: Border.all(color: AppColors.goldAccent),
//         // border: Border.all(color: AppColors.darkPrimaryText),
//         color: colorScheme.surface.withValues(alpha: 0.2),
//         shape: BoxShape.circle,
//       ),

//       child: IconButton(
//         icon: Icon(icon, color: Colors.white),
//         onPressed: onPressed,
//         padding: EdgeInsets.zero,
//         constraints: const BoxConstraints(),
//         iconSize: 22,
//       ),
//     );
//   }
// }
