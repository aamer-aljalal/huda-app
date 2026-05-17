import 'package:adhan/adhan.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class AdhanMuezzin {
  const AdhanMuezzin({
    required this.id,
    required this.name,
    required this.rawResourceName,
  });

  final String id;
  final String name;
  final String rawResourceName;
}

class AdhanNotificationService {
  AdhanNotificationService._();

  static const String _selectedMuezzinKey = 'selected_adhan_muezzin';
  static const String _notificationsEnabledKey = 'prayer_notifications_enabled';
  static const int _notificationBaseId = 9000;

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;

  static const List<AdhanMuezzin> muezzins = [
    AdhanMuezzin(
      id: 'adhan_mevlan_kurtishi',
      name: 'مولانا كورتشي',
      rawResourceName: 'adhan_mevlan_kurtishi',
    ),
    AdhanMuezzin(
      id: 'adhan_islam_sobhi',
      name: 'إسلام صبحي',
      rawResourceName: 'adhan_islam_sobhi',
    ),
    AdhanMuezzin(
      id: 'adhan_abdul_rahman',
      name: 'عبد الرحمن',
      rawResourceName: 'adhan_abdul_rahman',
    ),
    AdhanMuezzin(
      id: 'adhan_mohammad_marwan',
      name: 'محمد مروان',
      rawResourceName: 'adhan_mohammad_marwan',
    ),
    AdhanMuezzin(
      id: 'adhan_nasser_alqatami',
      name: 'ناصر القطامي',
      rawResourceName: 'adhan_nasser_alqatami',
    ),
  ];

  static AdhanMuezzin get defaultMuezzin => muezzins.first;

  static Future<void> initialize() async {
    if (_initialized) return;

    tz.initializeTimeZones();
    final localTimezone = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(localTimezone.identifier));

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinSettings = DarwinInitializationSettings();
    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    await _notifications.initialize(initializationSettings);
    await _requestPermissions();

    _initialized = true;
  }

  static Future<void> _requestPermissions() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    await androidPlugin?.requestNotificationsPermission();
    await androidPlugin?.requestExactAlarmsPermission();

    await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  static Future<bool> arePrayerNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  static Future<void> setPrayerNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
  }

  static Future<AdhanMuezzin> selectedMuezzin() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_selectedMuezzinKey);

    return muezzins.firstWhere(
      (muezzin) => muezzin.id == id,
      orElse: () => defaultMuezzin,
    );
  }

  static Future<void> setSelectedMuezzin(AdhanMuezzin muezzin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedMuezzinKey, muezzin.id);
  }

  static Future<void> schedulePrayerAdhan({
    required Coordinates coordinates,
    required CalculationParameters calculationParameters,
  }) async {
    await initialize();

    final enabled = await arePrayerNotificationsEnabled();
    await cancelPrayerAdhan();
    if (!enabled) return;

    final selected = await selectedMuezzin();
    final now = DateTime.now();
    final today = PrayerTimes(
      coordinates,
      DateComponents.from(now),
      calculationParameters,
    );
    final tomorrowDate = now.add(const Duration(days: 1));
    final tomorrow = PrayerTimes(
      coordinates,
      DateComponents.from(tomorrowDate),
      calculationParameters,
    );

    final prayers = <Prayer>[
      Prayer.fajr,
      Prayer.dhuhr,
      Prayer.asr,
      Prayer.maghrib,
      Prayer.isha,
    ];

    for (var index = 0; index < prayers.length; index++) {
      final prayer = prayers[index];
      final todayTime = today.timeForPrayer(prayer);
      final scheduledTime = todayTime != null && todayTime.isAfter(now)
          ? todayTime
          : tomorrow.timeForPrayer(prayer);

      if (scheduledTime == null) continue;

      await _scheduleSingleAdhan(
        id: _notificationBaseId + index,
        prayerName: _prayerName(prayer),
        scheduledTime: scheduledTime,
        muezzin: selected,
      );
    }
  }

  static Future<void> cancelPrayerAdhan() async {
    for (var index = 0; index < 5; index++) {
      await _notifications.cancel(_notificationBaseId + index);
    }
  }

  static Future<void> _scheduleSingleAdhan({
    required int id,
    required String prayerName,
    required DateTime scheduledTime,
    required AdhanMuezzin muezzin,
  }) async {
    final channelId = 'adhan_${muezzin.rawResourceName}';
    final androidDetails = AndroidNotificationDetails(
      channelId,
      'أذان ${muezzin.name}',
      channelDescription: 'تشغيل أذان ${muezzin.name} عند دخول وقت الصلاة',
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      sound: RawResourceAndroidNotificationSound(muezzin.rawResourceName),
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
    );

    const darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    await _notifications.zonedSchedule(
      id: id,
      title: 'حان الآن موعد صلاة $prayerName',
      body: 'الله أكبر',
      scheduledDate: tz.TZDateTime.from(scheduledTime, tz.local),
      notificationDetails: NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
        macOS: darwinDetails,
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
    );
  }

  static String _prayerName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 'الفجر';
      case Prayer.dhuhr:
        return 'الظهر';
      case Prayer.asr:
        return 'العصر';
      case Prayer.maghrib:
        return 'المغرب';
      case Prayer.isha:
        return 'العشاء';
      case Prayer.sunrise:
        return 'الشروق';
      case Prayer.none:
        return '';
    }
  }
}
