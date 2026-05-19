import 'dart:async';
import 'package:flutter/material.dart';
import 'package:adhan/adhan.dart';
import 'package:intl/intl.dart';
import 'package:huda/core/services/adhan_notification_service.dart';
import 'package:huda/core/services/adhan_player_service.dart';

class PrayerProvider extends ChangeNotifier {
  // موقع مكة المكرمة الثابت
  final String _cityName = 'مكة المكرمة';
  final double _lat = 21.4225;
  final double _lng = 39.8262;
  late final Coordinates _coordinates = Coordinates(_lat, _lng);
  late final CalculationParameters _calculationParameters = CalculationMethod
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
      // حساب المواقيت فوراً بناءً على مكة المكرمة بدون إنترنت أو GPS
      _calculatePrayerTimes();
      await scheduleAdhanNotifications();
      _startTimer();
    } catch (e) {
      _errorMessage = 'حدث خطأ أثناء جلب البيانات: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
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
