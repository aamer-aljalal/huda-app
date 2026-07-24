// ============================================================================
// اسم الملف: adhan_notification_service.dart
// وصف الملف: خدمة جدولة وعرض إشعارات الأذان المحلية عند دخول أوقات الصلوات الخمس.
//            يعتمد الملف على حزمة 'flutter_local_notifications' للتعامل مع نظام
//            التشغيل لجدولة منبهات دقيقة، وتشغيل صوت الأذان المخصص لكل مؤذن
//            حتى لو كان التطبيق مغلقاً أو الهاتف في وضع السبات.
// ============================================================================

import 'package:adhan/adhan.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'dart:io' show Platform;
import 'native_alarm_service.dart';

/// كلاس يمثل بيانات المؤذن (الاسم، المعرف، ومسار ملف الصوت)
class AdhanMuezzin {
  const AdhanMuezzin({
    required this.id,
    required this.name,
    required this.rawResourceName,
    required this.assetPath,
  });

  final String id; // المعرف الفريد للمؤذن (يستخدم في الإعدادات)
  final String name; // الاسم المعروض للمستخدم باللغة العربية
  final String
  rawResourceName; // اسم ملف الصوت بدون صيغة (للاستخدام في نظام أندرويد res/raw)
  final String assetPath; // مسار ملف الصوت في الأصول (للاستخدام داخل التطبيق)
}

/// الخدمة المسؤولة عن إعداد، طلب صلاحيات، وجدولة إشعارات الأذان المحددة بالثانية
class AdhanNotificationService {
  AdhanNotificationService._(); // لمنع إنشاء كائن من هذا الكلاس (Utility Class)

  static const String _selectedMuezzinKey = 'selected_adhan_muezzin';
  static const String _notificationsEnabledKey = 'prayer_notifications_enabled';

  // رقم أساسي تبدأ منه معرفات الإشعارات (ID) لتجنب التداخل مع إشعارات أخرى في التطبيق
  static const int _notificationBaseId = 9000;

  static final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static bool _initialized = false;
  static bool _notificationsAvailable = true;

  /// قائمة المؤذنين المتاحين في التطبيق وأسماء ملفاتهم الصوتية
  static const List<AdhanMuezzin> muezzins = [
    AdhanMuezzin(
      id: 'adhan_mevlan_kurtishi',
      name: 'مولانا كورتشي',
      rawResourceName: 'adhan_mevlan_kurtishi',
      assetPath: 'assets/audio/adhan/adhan_mevlan_kurtishi.m4a',
    ),
    AdhanMuezzin(
      id: 'adhan_islam_sobhi',
      name: 'إسلام صبحي',
      rawResourceName: 'adhan_islam_sobhi',
      assetPath: 'assets/audio/adhan/adhan_islam_sobhi.m4a',
    ),
    AdhanMuezzin(
      id: 'adhan_abdul_rahman',
      name: 'عبد الرحمن',
      rawResourceName: 'adhan_abdul_rahman',
      assetPath: 'assets/audio/adhan/adhan_abdul_rahman.m4a',
    ),
    AdhanMuezzin(
      id: 'adhan_mohammad_marwan',
      name: 'محمد مروان',
      rawResourceName: 'adhan_mohammad_marwan',
      assetPath: 'assets/audio/adhan/adhan_mohammad_marwan.m4a',
    ),
    AdhanMuezzin(
      id: 'adhan_nasser_alqatami',
      name: 'ناصر القطامي',
      rawResourceName: 'adhan_nasser_alqatami',
      assetPath: 'assets/audio/adhan/adhan_nasser_alqatami.m4a',
    ),
  ];

  static AdhanMuezzin get defaultMuezzin => muezzins.first;

  /// تهيئة إعدادات الإشعارات وتحديد المنطقة الزمنية عند تشغيل التطبيق
  static Future<void> initialize() async {
    if (_initialized) return;

    // تهيئة مكتبة المناطق الزمنية (Timezone) لضمان دقة مواعيد الجدولة
    tz.initializeTimeZones();
    await _configureLocalTimezone();

    // إعدادات التهيئة الخاصة بنظام الأندرويد (تحديد أيقونة الإشعار الافتراضية)
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );

    // إعدادات التهيئة الخاصة بنظام الـ iOS
    const darwinSettings = DarwinInitializationSettings();

    const initializationSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _notifications.initialize(settings: initializationSettings);
      await _requestPermissions();
    } on MissingPluginException {
      _notificationsAvailable = false;
    } on PlatformException {
      _notificationsAvailable = false;
    }

    _initialized = true;
  }

  /// تحديد المنطقة الزمنية الحالية للهاتف، مع وضع الرياض كافتياطي في حال الفشل
  static Future<void> _configureLocalTimezone() async {
    try {
      final localTimezone = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(localTimezone.identifier));
    } on MissingPluginException {
      tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));
    } on PlatformException {
      tz.setLocalLocation(tz.getLocation('Asia/Riyadh'));
    }
  }

  /// طلب الأذونات الخاصة بالإشعارات والمنبه الدقيق من نظامي التشغيل
  static Future<void> _requestPermissions() async {
    final androidPlugin = _notifications
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    // طلب إذن عرض الإشعارات (أندرويد 13+)
    await androidPlugin?.requestNotificationsPermission();

    // طلب إذن جدولة منبهات دقيقة بالثانية (ضروري جداً لتشغيل الأذان في وقته تماماً)
    await androidPlugin?.requestExactAlarmsPermission();

    // طلب أذونات الإشعارات لنظام iOS (تنبيه، شارة، صوت مخصص)
    await _notifications
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, badge: true, sound: true);
  }

  /// التحقق من حالة تفعيل إشعارات الأذان من إعدادات التطبيق
  static Future<bool> arePrayerNotificationsEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_notificationsEnabledKey) ?? true;
  }

  /// حفظ حالة تفعيل أو إلغاء تفعيل إشعارات الأذان
  static Future<void> setPrayerNotificationsEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsEnabledKey, enabled);
  }

  /// الحصول على المؤذن المختار حالياً من قبل المستخدم
  static Future<AdhanMuezzin> selectedMuezzin() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getString(_selectedMuezzinKey);

    return muezzins.firstWhere(
      (muezzin) => muezzin.id == id,
      orElse: () => defaultMuezzin,
    );
  }

  /// حفظ المؤذن المختار الجديد
  static Future<void> setSelectedMuezzin(AdhanMuezzin muezzin) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_selectedMuezzinKey, muezzin.id);
  }

  /// جدولة الإشعارات والمنبهات للصلوات الخمس بناءً على موقع المستخدم
  static Future<void> schedulePrayerAdhan({
    required Coordinates coordinates,
    required CalculationParameters calculationParameters,
  }) async {
    await initialize();
    if (!_notificationsAvailable) return;

    final enabled = await arePrayerNotificationsEnabled();

    // مسح كافة التنبيهات المجدولة سابقاً لتجنب التكرار والتضارب
    await cancelPrayerAdhan();
    if (!enabled) return;

    final selected = await selectedMuezzin();
    final now = DateTime.now();

    // حساب مواقيت اليوم
    final today = PrayerTimes(
      coordinates,
      DateComponents.from(now),
      calculationParameters,
    );

    // حساب مواقيت الغد (تستخدم في حال مرت الصلاة اليوم)
    final tomorrowDate = now.add(const Duration(days: 1));
    final tomorrow = PrayerTimes(
      coordinates,
      DateComponents.from(tomorrowDate),
      calculationParameters,
    );

    // قائمة الصلوات المطلوب جدولتها
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

      // إذا كان وقت الصلاة اليوم قد مضى، نقوم بجدولتها لوقت الغد
      final scheduledTime = todayTime != null && todayTime.isAfter(now)
          ? todayTime
          : tomorrow.timeForPrayer(prayer);

      if (scheduledTime == null) continue;

      // جدولة منبه الصلاة
      await _scheduleSingleAdhan(
        id: _notificationBaseId + index,
        prayerName: _prayerName(prayer),
        scheduledTime: scheduledTime,
        muezzin: selected,
      );
    }
  }

  /// إلغاء كافة إشعارات الأذان الخمسة المجدولة في النظام
  static Future<void> cancelPrayerAdhan() async {
    if (!_notificationsAvailable) return;

    for (var index = 0; index < 5; index++) {
      await _notifications.cancel(id: _notificationBaseId + index);
    }

    // إلغاء كافة المنبهات المجدولة في الأندرويد الأصلي أيضاً
    if (Platform.isAndroid) {
      await NativeAlarmService.cancelAllAlarms();
    }
  }

  /// جدولة إشعار/منبه فردي لصلاة معينة بصوت المؤذن المحدد
  static Future<void> _scheduleSingleAdhan({
    required int id,
    required String prayerName,
    required DateTime scheduledTime,
    required AdhanMuezzin muezzin,
  }) async {
    // 1. إذا كان الهاتف أندرويد، نجدول المنبه الأصلي فورا
    if (Platform.isAndroid) {
      final prefs = await SharedPreferences.getInstance();
      final vibrateEnabled = prefs.getBool('adhan_vibration_enabled') ?? true;
      final volumeLevel = prefs.getDouble('adhan_volume') ?? 1.0;

      final success = await NativeAlarmService.scheduleAlarm(
        id: 'adhan_prayer_$id',
        type: 'ADHAN',
        title: 'حان الآن موعد صلاة $prayerName',
        subtitle: 'أذان بصوت المؤذن ${muezzin.name}',
        audioFile: muezzin.rawResourceName,
        audioSource: 'RAW_RESOURCE',
        // scheduledTime: scheduledTime,
        scheduledTime: DateTime.now().add(const Duration(seconds: 30)),
        vibrate: vibrateEnabled,
        fullScreen: true,
        volume: volumeLevel,
        loopAudio: false,
      );

      if (success) {
        debugPrint(
          'Native Adhan scheduled successfully for $prayerName at $scheduledTime',
        );
        return; // ننهي الدالة لكي لا تتم جدولة إشعار مكرر عبر flutter_local_notifications
      } else {
        debugPrint(
          'Native Adhan scheduling failed for $prayerName, falling back to local notifications',
        );
      }
    }

    // 2. الدعم البديل للـ iOS أو في حال فشل الأندرويد الأصلي
    // 💡 تم إضافة الحاق '_v4' لاسم معرف القناة (channelId) لحل مشكلة كاش الأندرويد.
    final channelId = 'adhan_${muezzin.rawResourceName}_channel_v4';

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

    // تفاصيل إعدادات الـ iOS (تم تحديد الصوت بصيغة .m4a ليعمل بشكل صحيح)
    final darwinDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      sound: '${muezzin.rawResourceName}.m4a',
    );

    try {
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
    } catch (e) {
      debugPrint('Exact alarm scheduling failed, falling back to inexact: $e');
      try {
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
          androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        );
      } catch (innerError) {
        debugPrint('Fallback notification scheduling failed: $innerError');
      }
    }
  }

  /// ترجمة اسم الصلاة من الكلاس الداخلي إلى اللغة العربية لعرضه للمستخدم
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
