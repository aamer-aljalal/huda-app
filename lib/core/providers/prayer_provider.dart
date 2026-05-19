import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:huda/core/services/adhan_notification_service.dart';
import 'package:huda/core/services/adhan_player_service.dart';

class PrayerProvider extends ChangeNotifier {
  // موقع مكة المكرمة الافتراضي والاحتياطي
  String _cityName = 'مكة المكرمة';
  double _lat = 21.4225;
  double _lng = 39.8262;
  late Coordinates _coordinates = Coordinates(_lat, _lng);
  late CalculationParameters _calculationParameters = CalculationMethod
      .umm_al_qura
      .getParameters();

  // بيانات أوقات الصلاة
  PrayerTimes? _prayerTimes;
  Prayer? _nextPrayer;
  DateTime? _nextPrayerTime;
  Duration _timeUntilNextPrayer = Duration.zero;
  Timer? _timer;

  // حالة التحميل والأخطاء
  bool _isLoading = true;
  String? _errorMessage;

  // Getters
  String get cityName => _cityName;
  PrayerTimes? get prayerTimes => _prayerTimes;
  Prayer? get nextPrayer => _nextPrayer;
  DateTime? get nextPrayerTime => _nextPrayerTime;
  Duration get timeUntilNextPrayer => _timeUntilNextPrayer;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> initializeData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. حساب المواقيت فوراً بناءً على مكة المكرمة بدون إنترنت أو GPS لضمان السرعة المطلقة والاستقرار
      _calculatePrayerTimes();
      _startTimer();

      // 2. محاولة تحديث المواقيت بناءً على إحداثيات موقع المستخدم الحقيقي في الخلفية بشكل آمن
      await _updateLocationAndRecalculate();
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء جلب البيانات: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _updateLocationAndRecalculate() async {
    try {
      // تجنب تشغيل Geolocator على نظام الويندوز تفادياً لأي أعطال أثناء الاختبار
      if (defaultTargetPlatform == TargetPlatform.windows) {
        return;
      }

      // التحقق من تفعيل خدمة تحديد الموقع بالجهاز (GPS)
      final isServiceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isServiceEnabled) return;

      // التحقق من صلاحيات الموقع وطلبها إذا لم تكن ممنوحة
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied ||
            permission == LocationPermission.deniedForever) {
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        return;
      }

      // محاولة الحصول على آخر موقع معروف أولاً لسرعته الفائقة وعدم استهلاك الطاقة
      Position? pos;
      try {
        pos = await Geolocator.getLastKnownPosition();
      } catch (_) {}

      // إعدادات الموقع للأندرويد التي تتخطى مشاكل خدمات جوجل وتعمل بدقة منخفضة مناسبة للمواقيت
      final locationSettings = defaultTargetPlatform == TargetPlatform.android
          ? AndroidSettings(
              accuracy: LocationAccuracy.low,
              forceLocationManager: true,
            )
          : const LocationSettings(
              accuracy: LocationAccuracy.low,
            );

      // إذا لم يتوفر آخر موقع معروف، نطلب الموقع الحالي بمهلة زمنية قصيرة (5 ثوانٍ)
      pos ??= await Geolocator.getCurrentPosition(
        locationSettings: locationSettings,
      ).timeout(const Duration(seconds: 5));

      if (pos != null) {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _coordinates = Coordinates(_lat, _lng);

        // محاولة جلب الاسم الجغرافي للمدينة
        try {
          final placemarks = await placemarkFromCoordinates(_lat, _lng);
          if (placemarks.isNotEmpty) {
            final place = placemarks.first;
            _cityName = place.locality ??
                place.subAdministrativeArea ??
                place.administrativeArea ??
                'موقعي الحالي';
          }
        } catch (_) {
          _cityName = 'موقعي الحالي';
        }

        // إشعار التطبيق بالتحديث وإعادة حساب المواقيت وتحديث إشعارات الأذان
        _calculatePrayerTimes();
        await scheduleAdhanNotifications();
        notifyListeners();
      }
    } catch (e) {
      // في حال حدوث أي خطأ، لا نفعل شيئاً ونبقي على مكة المكرمة كخيار احتياطي آمن 100%
      debugPrint("Silent catch - Qibla/Prayer times location fetch failed: $e");
    }
  }

  void _calculatePrayerTimes() {
    _prayerTimes = PrayerTimes.today(_coordinates, _calculationParameters);
    _updateNextPrayer();
  }

  Future<void> scheduleAdhanNotifications() {
    return AdhanNotificationService.schedulePrayerAdhan(
      coordinates: _coordinates,
      calculationParameters: _calculationParameters,
    );
  }

  void _updateNextPrayer() {
    _prayerTimes = PrayerTimes.today(_coordinates, _calculationParameters);
    if (_prayerTimes != null) {
      Prayer next = _prayerTimes!.nextPrayer();

      // تخطي صلاة الشروق وجعل الصلاة القادمة هي الظهر
      if (next == Prayer.sunrise) {
        next = Prayer.dhuhr;
      }

      if (next == Prayer.none) {
        // إذا انتهت صلوات اليوم، فالصلاة القادمة هي الفجر غداً
        _nextPrayer = Prayer.fajr;
        
        // حساب وقت الفجر للغد
        final tomorrow = DateTime.now().add(const Duration(days: 1));
        final tomorrowTimes = PrayerTimes(
          _coordinates,
          DateComponents.from(tomorrow),
          _calculationParameters,
        );
        _nextPrayerTime = tomorrowTimes.timeForPrayer(Prayer.fajr);
      } else {
        _nextPrayer = next;
        _nextPrayerTime = _prayerTimes!.timeForPrayer(next);
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_prayerTimes != null &&
          _nextPrayer != null &&
          _nextPrayerTime != null) {
        final now = DateTime.now();
        if (now.isAfter(_nextPrayerTime!)) {
          final enteredPrayer = _nextPrayer!;
          if (enteredPrayer != Prayer.sunrise) {
            final prayerName = getPrayerName(enteredPrayer);
            AdhanPlayerService().playAdhan(prayerName);
          }

          // إذا حان وقت الصلاة، نعيد حساب الصلاة التي تليها
          _updateNextPrayer();
          scheduleAdhanNotifications();
          notifyListeners();
        } else {
          _timeUntilNextPrayer = _nextPrayerTime!.difference(now);
          notifyListeners();
        }
      }
    });
  }

  // دوال مساعدة لجلب الوقت كـ String منسق
  String getFormattedPrayerTime(Prayer prayer) {
    if (_prayerTimes == null) return '--:--';
    final time = _prayerTimes!.timeForPrayer(prayer);
    if (time == null) return '--:--';
    return DateFormat('hh:mm').format(time);
  }

  String getPrayerName(Prayer prayer) {
    switch (prayer) {
      case Prayer.fajr:
        return 'الفجر';
      case Prayer.sunrise:
        return 'الشروق';
      case Prayer.dhuhr:
        return 'الظهر';
      case Prayer.asr:
        return 'العصر';
      case Prayer.maghrib:
        return 'المغرب';
      case Prayer.isha:
        return 'العشاء';
      case Prayer.none:
        return '';
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
