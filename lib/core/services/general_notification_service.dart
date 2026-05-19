import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:huda/features/quran/views/surah_detail_page.dart';
import 'package:huda/features/quran/services/quran_service.dart';
import 'package:huda/features/azkar/zkar_details.dart';
import 'package:huda/features/azkar/services/azkar_service.dart';
import 'package:huda/main.dart';

class GeneralNotificationService {
  GeneralNotificationService._();

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  // Notification IDs
  static const int idMorningAzkar = 8000;
  static const int idEveningAzkar = 8001;
  static const int idSleepAzkar = 8002;
  static const int idFridayKahf = 8003;
  static const int idFastingMonday = 8004;
  static const int idFastingThursday = 8005;
  static const int idDuha = 8006;
  static const int idQiyam = 8007;
  static const int idDailyContent = 8008;
  static const int idKhatmaReminder = 8020;

  // Periodic Dhikr IDs (six times throughout the day)
  static const List<int> idsPeriodicDhikr = [8009, 8010, 8011, 8012, 8013, 8014];

  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    await _configureLocalTimezone();

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
    );

    try {
      await _notifications.initialize(
        settings: initializationSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) async {
          final payload = response.payload;
          if (payload == null) return;

          if (payload == 'surah_kahf') {
            try {
              final surahs = await QuranService.loadSurahs();
              final kahfSurah = surahs.firstWhere((s) => s.number == 18);
              final ayahs = await QuranService.loadAyahs(18);

              Huda.navigatorKey.currentState?.push(
                MaterialPageRoute(
                  builder: (context) => SurahDetailPage(
                    surah: kahfSurah,
                    ayahs: ayahs,
                  ),
                ),
              );
            } catch (e) {
              debugPrint('Error navigating to Surah Al-Kahf: $e');
            }
          } else if (payload.startsWith('azkar_')) {
            try {
              final targetTitle = payload.substring(6);
              final categories = await AzkarService.loadAzkar();
              final match = categories.firstWhere(
                (c) => c.title == targetTitle,
              );

              Huda.navigatorKey.currentState?.push(
                MaterialPageRoute(
                  builder: (context) => AzkarDetailsScreen(category: match),
                ),
              );
            } catch (e) {
              debugPrint('Error navigating to Azkar: $e');
            }
          } else if (payload == 'khatma_planner') {
            try {
              final prefs = await SharedPreferences.getInstance();
              final lastSurahNumber = prefs.getInt('quran_last_read_surah_number');
              
              if (lastSurahNumber != null) {
                final surahs = await QuranService.loadSurahs();
                final surah = surahs.firstWhere((s) => s.number == lastSurahNumber);
                final ayahs = await QuranService.loadAyahs(lastSurahNumber);

                Huda.navigatorKey.currentState?.push(
                  MaterialPageRoute(
                    builder: (context) => SurahDetailPage(
                      surah: surah,
                      ayahs: ayahs,
                      resumeLastPage: true,
                    ),
                  ),
                );
              } else {
                Huda.navigatorKey.currentState?.pushNamed('/khatma-planner');
              }
            } catch (e) {
              debugPrint('Error navigating to Quran from Khatma notification: $e');
              Huda.navigatorKey.currentState?.pushNamed('/khatma-planner');
            }
          }
        },
      );
    } catch (_) {}

    _initialized = true;
  }

  static Future<void> _configureLocalTimezone() async {
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    } catch (_) {
      tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));
    }
  }

  /// Master method to schedule all enabled notifications on startup
  static Future<void> scheduleAllEnabledNotifications() async {
    await initialize();
    final prefs = await SharedPreferences.getInstance();

    // 1. Azkar (Morning, Evening, Sleep)
    if (prefs.getBool('notifications_azkar') ?? false) {
      await scheduleAzkarNotifications();
    } else {
      await cancelAzkarNotifications();
    }

    // 2. Periodic Dhikr Reminders
    if (prefs.getBool('notifications_custom') ?? false) {
      await schedulePeriodicDhikrs();
    } else {
      await cancelPeriodicDhikrs();
    }

    // 3. Friday Reminder
    if (prefs.getBool('notifications_friday') ?? false) {
      await scheduleFridayReminder();
    } else {
      await _notifications.cancel(id: idFridayKahf);
    }

    // 4. Fasting Reminders
    if (prefs.getBool('notifications_fasting') ?? false) {
      await scheduleFastingReminders();
    } else {
      await _notifications.cancel(id: idFastingMonday);
      await _notifications.cancel(id: idFastingThursday);
    }

    // 5. Duha Prayer
    if (prefs.getBool('notifications_duha') ?? false) {
      await scheduleDuhaReminder();
    } else {
      await _notifications.cancel(id: idDuha);
    }

    // 6. Qiyam Al-Layl
    if (prefs.getBool('notifications_qiyam') ?? false) {
      await scheduleQiyamReminder();
    } else {
      await _notifications.cancel(id: idQiyam);
    }

    // 7. Daily Verse & Hadith
    if (prefs.getBool('notifications_daily_content') ?? false) {
      await scheduleDailyContentReminder();
    } else {
      await _notifications.cancel(id: idDailyContent);
    }
  }

  // ==================== 1. Azkar Reminders ====================

  static Future<void> scheduleAzkarNotifications() async {
    await cancelAzkarNotifications();

    const androidDetails = AndroidNotificationDetails(
      'azkar_reminders_channel',
      'تذكيرات الأذكار والسنن',
      channelDescription: 'تنبيهات يومية لقراءة أذكار الصباح والمساء والنوم',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      category: AndroidNotificationCategory.reminder,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    // Morning Azkar (7:00 AM)
    await _scheduleDailyTime(
      id: idMorningAzkar,
      title: 'أذكار الصباح ☀️',
      body: '«أصبحنا وأصبح الملك لله».. حان وقت أذكار الصباح المأثورة لتنير يومك وتصون عملك.',
      hour: 7,
      minute: 0,
      details: const NotificationDetails(android: androidDetails, iOS: darwinDetails),
      payload: 'azkar_أذكار الصباح',
    );

    // Evening Azkar (5:00 PM)
    await _scheduleDailyTime(
      id: idEveningAzkar,
      title: 'أذكار المساء 🌙',
      body: '«أمسينا وأمسى الملك لله».. حان وقت أذكار المساء لتحفظك وتحرسك حتى تصبح.',
      hour: 17,
      minute: 0,
      details: const NotificationDetails(android: androidDetails, iOS: darwinDetails),
      payload: 'azkar_أذكار المساء',
    );

    // Sleep Azkar (10:00 PM)
    await _scheduleDailyTime(
      id: idSleepAzkar,
      title: 'أذكار النوم وآدابه 🛌',
      body: 'تحصن بآية الكرسي والمعوذات واقرأ أذكار النوم لنوم هادئ وحماية ربانية.',
      hour: 22,
      minute: 0,
      details: const NotificationDetails(android: androidDetails, iOS: darwinDetails),
      payload: 'azkar_أذكار النوم',
    );
  }

  static Future<void> cancelAzkarNotifications() async {
    await _notifications.cancel(id: idMorningAzkar);
    await _notifications.cancel(id: idEveningAzkar);
    await _notifications.cancel(id: idSleepAzkar);
  }

  // ==================== 2. Periodic Dhikrs ====================

  static Future<void> schedulePeriodicDhikrs() async {
    await cancelPeriodicDhikrs();

    const androidDetails = AndroidNotificationDetails(
      'periodic_dhikrs_channel',
      'تذكير الأذكار الدوري المخصص',
      channelDescription: 'تنبيهات دورية بالاستغفار والصلاة على النبي على مدار اليوم',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
      playSound: true,
      category: AndroidNotificationCategory.reminder,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = const NotificationDetails(android: androidDetails, iOS: darwinDetails);

    // Schedule 6 distinct reminders spread across the day
    final times = [
      _DhikrTime(9, 0, 'أستغفر الله العظيم وأتوب إليه', '«من لزم الاستغفار جعل الله له من كل هم فرجاً»'),
      _DhikrTime(11, 0, 'اللهم صلِّ وسلِّم على نبينا محمد  ', '«من صلَّى عليَّ صلاة واحدة صلَّى الله عليه بها عشراً»'),
      _DhikrTime(13, 0, 'سبحان الله وبحمده، سبحان الله العظيم ', '«كلمتان خفيفتان على اللسان، ثقيلتان في الميزان»'),
      _DhikrTime(15, 0, 'لا حول ولا قوة إلا بالله العلي العظيم ', '«كنز من كنوز الجنة.. دواء لتسعة وتسعين داء»'),
      _DhikrTime(19, 0, 'لا إله إلا الله وحده لا شريك له ', '«له الملك وله الحمد وهو على كل شيء قدير»'),
      _DhikrTime(21, 0, 'اللهم صلِّ وسلِّم على نبينا محمد  ', 'أكثروا من الصلاة على الحبيب المصطفى'),
    ];

    for (var i = 0; i < times.length; i++) {
      final t = times[i];
      await _scheduleDailyTime(
        id: idsPeriodicDhikr[i],
        title: t.title,
        body: t.body,
        hour: t.hour,
        minute: t.minute,
        details: details,
      );
    }
  }

  static Future<void> cancelPeriodicDhikrs() async {
    for (final id in idsPeriodicDhikr) {
      await _notifications.cancel(id: id);
    }
  }

  // ==================== 3. Friday Kahf ====================

  static Future<void> scheduleFridayReminder() async {
    await _notifications.cancel(id: idFridayKahf);

    const androidDetails = AndroidNotificationDetails(
      'friday_channel',
      'تنبيهات يوم الجمعة',
      channelDescription: 'تذكير بقراءة سورة الكهف والسنن والصلاة على النبي',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      category: AndroidNotificationCategory.reminder,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _scheduleWeeklyDayAndTime(
      id: idFridayKahf,
      title: 'جمعة مباركة عامرة بالذكر 🕌',
      body: 'لا تنسَ سنن الجمعة: قراءة سورة الكهف لنور ما بين الجمعتين، الصلاة على النبي ﷺ وكثرة الدعاء.',
      dayOfWeek: DateTime.friday,
      hour: 9,
      minute: 0,
      details: const NotificationDetails(android: androidDetails, iOS: darwinDetails),
      payload: 'surah_kahf',
    );
  }

  // ==================== 4. Fasting Reminders ====================

  static Future<void> scheduleFastingReminders() async {
    await _notifications.cancel(id: idFastingMonday);
    await _notifications.cancel(id: idFastingThursday);

    const androidDetails = AndroidNotificationDetails(
      'fasting_channel',
      'تنبيهات الصيام',
      channelDescription: 'تذكير بصيام الاثنين والخميس والأيام البيض',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    final details = const NotificationDetails(android: androidDetails, iOS: darwinDetails);

    // Fasting Monday: Schedule on Sunday evening (8:00 PM)
    await _scheduleWeeklyDayAndTime(
      id: idFastingMonday,
      title: 'تذكير بصيام الاثنين غداً 🌙',
      body: 'تُرفع الأعمال غداً الاثنين.. فكن من الصائمين لتنال أجر صيام التطوع والسنن المأثورة.',
      dayOfWeek: DateTime.sunday,
      hour: 20,
      minute: 0,
      details: details,
    );

    // Fasting Thursday: Schedule on Wednesday evening (8:00 PM)
    await _scheduleWeeklyDayAndTime(
      id: idFastingThursday,
      title: 'تذكير بصيام الخميس غداً 🌙',
      body: 'صيام يوم في سبيل الله يبعد وجهك عن النار سبعين خريفاً.. لا تدع صيام الخميس يفوتك.',
      dayOfWeek: DateTime.wednesday,
      hour: 20,
      minute: 0,
      details: details,
    );
  }

  // ==================== 5. Duha Reminder ====================

  static Future<void> scheduleDuhaReminder() async {
    await _notifications.cancel(id: idDuha);

    const androidDetails = AndroidNotificationDetails(
      'duha_channel',
      'صلاة الضحى',
      channelDescription: 'تذكير بصلاة الضحى اليومية',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _scheduleDailyTime(
      id: idDuha,
      title: 'صلاة الضحى صلاة الأوابين ☀️',
      body: 'تصدق عن مفاصل بدنك الـ ٣٦٠ بركعتين من صلاة الضحى اليوم، لا تحرم نفسك أجرها الوفير.',
      hour: 9,
      minute: 30,
      details: const NotificationDetails(android: androidDetails, iOS: darwinDetails),
    );
  }

  // ==================== 6. Qiyam Al-Layl ====================

  static Future<void> scheduleQiyamReminder() async {
    await _notifications.cancel(id: idQiyam);

    const androidDetails = AndroidNotificationDetails(
      'qiyam_channel',
      'قيام الليل والوتر',
      channelDescription: 'تذكير بقيام الليل والوتر في الثلث الأخير',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _scheduleDailyTime(
      id: idQiyam,
      title: 'شرف المؤمن قيام الليل والوتر 🌌',
      body: 'ينزل ربنا تبارك وتعالى كل ليلة إلى السماء الدنيا فيقول: هل من داعٍ فأستجيب له؟ هل من مستغفر فأغفر له؟',
      hour: 2,
      minute: 0,
      details: const NotificationDetails(android: androidDetails, iOS: darwinDetails),
    );
  }

  // ==================== 7. Daily Content ====================

  static Future<void> scheduleDailyContentReminder() async {
    await _notifications.cancel(id: idDailyContent);

    const androidDetails = AndroidNotificationDetails(
      'daily_content_channel',
      'آية وحديث اليوم',
      channelDescription: 'تنبيه يومي بالقرآن والحديث الشريف',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _scheduleDailyTime(
      id: idDailyContent,
      title: 'نور لقلبك: آية وحديث اليوم 📖',
      body: 'تأمل في كلام الله العظيم وسنة رسوله المصطفى ﷺ لتنير يومك وتسعد قلبك بالبركة.',
      hour: 12,
      minute: 30,
      details: const NotificationDetails(android: androidDetails, iOS: darwinDetails),
    );
  }

  // ==================== Helper Core Methods ====================

  static Future<void> _scheduleDailyTime({
    required int id,
    required String title,
    required String body,
    required int hour,
    required int minute,
    required NotificationDetails details,
    String? payload,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    try {
      await _notifications.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.time,
        payload: payload,
      );
    } catch (_) {}
  }

  static Future<void> _scheduleWeeklyDayAndTime({
    required int id,
    required String title,
    required String body,
    required int dayOfWeek,
    required int hour,
    required int minute,
    required NotificationDetails details,
    String? payload,
  }) async {
    final now = DateTime.now();
    var scheduledDate = DateTime(
      now.year,
      now.month,
      now.day,
      hour,
      minute,
    );

    // Roll forward to find the matching weekday
    while (scheduledDate.weekday != dayOfWeek) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    // If it's the target day but the time has already passed today, push it to next week
    if (scheduledDate.weekday == dayOfWeek && scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 7));
    }

    try {
      await _notifications.zonedSchedule(
        id: id,
        title: title,
        body: body,
        scheduledDate: tz.TZDateTime.from(scheduledDate, tz.local),
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: payload,
      );
    } catch (_) {}
  }

  static Future<void> scheduleKhatmaReminder(int hour, int minute) async {
    await initialize();
    await _notifications.cancel(id: idKhatmaReminder);

    const androidDetails = AndroidNotificationDetails(
      'khatma_reminders_channel',
      'تذكير الورد اليومي',
      channelDescription: 'تنبيهات يومية لتذكيرك بقراءة وردك اليومي المخطط له',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      category: AndroidNotificationCategory.reminder,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _scheduleDailyTime(
      id: idKhatmaReminder,
      title: 'وردك اليومي من القرآن',
      body: 'حان وقت قراءة وردك اليومي المخطط له لختم كتاب الله. انقر للبدء بالقراءة والمتابعة.',
      hour: hour,
      minute: minute,
      details: const NotificationDetails(android: androidDetails, iOS: darwinDetails),
      payload: 'khatma_planner',
    );
  }

  static Future<void> cancelKhatmaReminder() async {
    await initialize();
    await _notifications.cancel(id: idKhatmaReminder);
  }
}

class _DhikrTime {
  final int hour;
  final int minute;
  final String title;
  final String body;

  _DhikrTime(this.hour, this.minute, this.title, this.body);
}
