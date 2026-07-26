import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/providers/prayer_provider.dart';
import 'package:tarteel/core/services/adhan_notification_service.dart';
import 'package:tarteel/core/services/native_alarm_service.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AdhanMuezzinScreen extends StatefulWidget {
  const AdhanMuezzinScreen({super.key});

  @override
  State<AdhanMuezzinScreen> createState() => _AdhanMuezzinScreenState();
}

class _AdhanMuezzinScreenState extends State<AdhanMuezzinScreen> {
  final AudioPlayer _player = AudioPlayer();

  bool _soundEnabled = true;
  AdhanMuezzin _selectedMuezzin = AdhanNotificationService.defaultMuezzin;
  bool _hapticFeedback = true;
  double _adhanVolume = 1.0;
  bool _vibrationEnabled = true;
  bool _isTestingAdhan = false;
  String? _playingMuezzinId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        setState(() => _playingMuezzinId = null);
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    if (_isTestingAdhan) {
      NativeAlarmService.stopActiveAlarm();
    }
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final notificationsEnabled =
        await AdhanNotificationService.arePrayerNotificationsEnabled();
    final activeMuezzin = await AdhanNotificationService.selectedMuezzin();
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;
    setState(() {
      _soundEnabled = notificationsEnabled;
      _selectedMuezzin = activeMuezzin;
      _hapticFeedback = prefs.getBool('haptic_feedback') ?? true;
      _adhanVolume = prefs.getDouble('adhan_volume') ?? 1.0;
      _vibrationEnabled = prefs.getBool('adhan_vibration_enabled') ?? true;
    });
  }

  Future<void> _updateSoundEnabled(bool enabled) async {
    if (_hapticFeedback) HapticFeedback.lightImpact();
    setState(() {
      _soundEnabled = enabled;
    });

    await AdhanNotificationService.setPrayerNotificationsEnabled(enabled);

    if (!mounted) return;
    final prayerProvider = context.read<PrayerProvider>();
    if (enabled) {
      await prayerProvider.scheduleAdhanNotifications();
    } else {
      await AdhanNotificationService.cancelPrayerAdhan();
    }
  }

  Future<void> _updateAdhanVolume(double val) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('adhan_volume', val);
    setState(() {
      _adhanVolume = val;
    });
    if (mounted) {
      final prayerProvider = context.read<PrayerProvider>();
      await prayerProvider.scheduleAdhanNotifications();
    }
  }

  Future<void> _updateVibrationEnabled(bool val) async {
    if (_hapticFeedback) HapticFeedback.lightImpact();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('adhan_vibration_enabled', val);
    setState(() {
      _vibrationEnabled = val;
    });
    if (_isTestingAdhan) {
      await NativeAlarmService.updateTestVibration(val);
    }
    if (mounted) {
      final prayerProvider = context.read<PrayerProvider>();
      await prayerProvider.scheduleAdhanNotifications();
    }
  }

  Future<void> _toggleTestAdhan() async {
    if (_isTestingAdhan) {
      await NativeAlarmService.stopActiveAlarm();
      setState(() {
        _isTestingAdhan = false;
      });
    } else {
      if (_playingMuezzinId != null) {
        await _player.stop();
        setState(() {
          _playingMuezzinId = null;
        });
      }

      if (_hapticFeedback) HapticFeedback.mediumImpact();

      setState(() {
        _isTestingAdhan = true;
      });

      final success = await NativeAlarmService.playTestAdhan(
        audioFile: _selectedMuezzin.rawResourceName,
        volume: _adhanVolume,
        vibrate: _vibrationEnabled,
      );

      if (!success) {
        setState(() {
          _isTestingAdhan = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('فشل تشغيل الأذان التجريبي')),
          );
        }
      }
    }
  }

  Future<void> _startTestAdhanWithVolume(double val) async {
    if (_isTestingAdhan) return;
    if (_playingMuezzinId != null) {
      await _player.stop();
      setState(() {
        _playingMuezzinId = null;
      });
    }

    setState(() {
      _isTestingAdhan = true;
    });

    final success = await NativeAlarmService.playTestAdhan(
      audioFile: _selectedMuezzin.rawResourceName,
      volume: val,
      vibrate: _vibrationEnabled,
    );

    if (!success) {
      setState(() {
        _isTestingAdhan = false;
      });
    }
  }

  Future<void> _togglePreview(AdhanMuezzin muezzin) async {
    if (_isTestingAdhan) {
      await NativeAlarmService.stopActiveAlarm();
      setState(() {
        _isTestingAdhan = false;
      });
    }

    if (_playingMuezzinId == muezzin.id) {
      await _player.stop();
      if (!mounted) return;
      setState(() => _playingMuezzinId = null);
      return;
    }

    setState(() => _playingMuezzinId = muezzin.id);
    try {
      await _player.stop();
      await _player.setAsset(muezzin.assetPath);
      await _player.play();
    } catch (_) {
      if (!mounted) return;
      setState(() => _playingMuezzinId = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر تشغيل صوت المؤذن')));
    }
  }

  Future<void> _selectMuezzin(AdhanMuezzin muezzin) async {
    if (_hapticFeedback) HapticFeedback.mediumImpact();
    setState(() {
      _selectedMuezzin = muezzin;
      _isSaving = true;
    });

    if (_isTestingAdhan) {
      await NativeAlarmService.stopActiveAlarm();
      setState(() {
        _isTestingAdhan = false;
      });
    }

    await AdhanNotificationService.setSelectedMuezzin(muezzin);

    if (!mounted) return;
    await context.read<PrayerProvider>().scheduleAdhanNotifications();

    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('تم اختيار ${muezzin.name} للأذان')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: const tarteelAppBar(
          titleText: 'إعدادات المؤذن والأذان',
          elevation: 0,
        ),
        body: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. بطاقة إعدادات الأذان والصوت والاهتزاز الموحدة
              if (_soundEnabled) ...[
                SizedBox(height: 24.h),

                // عنوان قسم المؤذنين بدون حاوية خارجية عملاقة
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 4.w),
                  child: Row(
                    children: [
                      Container(
                        width: 4.w,
                        height: 16.h,
                        decoration: BoxDecoration(
                          color: AppColors.primary,
                          borderRadius: BorderRadius.circular(2.r),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        'اختر صوت المؤذن للأذان',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: 12.h),

                // بطاقات المؤذنين المستقلة مباشرة على خلفية الشاشة
                ...List.generate(AdhanNotificationService.muezzins.length, (
                  index,
                ) {
                  final muezzin = AdhanNotificationService.muezzins[index];
                  final isSelected = _selectedMuezzin.id == muezzin.id;
                  final isPlaying = _playingMuezzinId == muezzin.id;

                  return Container(
                    margin: EdgeInsets.only(bottom: 12.h),
                    padding: EdgeInsets.all(14.w),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : (isDark
                                  ? Colors.white.withValues(alpha: 0.05)
                                  : Colors.grey.shade100),
                        width: isSelected ? 1.6 : 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: theme.shadowColor.withValues(
                            alpha: isSelected ? 0.05 : 0.02,
                          ),
                          blurRadius: 8,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40.w,
                          height: 40.w,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.1)
                                : (isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade100),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            isSelected
                                ? Icons.check
                                : Icons.record_voice_over_outlined,
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600),
                            size: 20.sp,
                          ),
                        ),
                        SizedBox(width: 12.w),
                        Expanded(
                          child: Text(
                            muezzin.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w600,
                              color: isSelected ? AppColors.primary : null,
                              fontSize: 14.sp,
                            ),
                          ),
                        ),
                        SizedBox(width: 8.w),
                        IconButton.filledTonal(
                          tooltip: isPlaying
                              ? 'إيقاف المعاينة'
                              : 'استماع للمؤذن',
                          onPressed: () => _togglePreview(muezzin),
                          icon: Icon(
                            isPlaying
                                ? Icons.stop_rounded
                                : Icons.play_arrow_rounded,
                            size: 20.sp,
                          ),
                          style: IconButton.styleFrom(
                            backgroundColor: isPlaying
                                ? Colors.red.withValues(alpha: 0.1)
                                : AppColors.primary.withValues(alpha: 0.1),
                            foregroundColor: isPlaying
                                ? Colors.red
                                : AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        FilledButton(
                          onPressed: isSelected || _isSaving
                              ? null
                              : () => _selectMuezzin(muezzin),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: EdgeInsets.symmetric(horizontal: 14.w),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10.r),
                            ),
                          ),
                          child: _isSaving && isSelected
                              ? SizedBox(
                                  width: 14.w,
                                  height: 14.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  isSelected ? 'مختار' : 'تفعيل',
                                  style: TextStyle(
                                    fontSize: 12.sp,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(24.r),
                  boxShadow: [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.25)
                          : Colors.grey.shade100,
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade100,
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    _buildSwitchTile(
                      title: 'تشغيل الأذان التلقائي',
                      subtitle: 'تنبيه بصوت المؤذن عند دخول وقت الصلاة',
                      value: _soundEnabled,
                      icon: Icons.notifications_active_outlined,
                      onChanged: (value) => _updateSoundEnabled(value),
                      iconColor: Colors.teal,
                    ),
                    if (_soundEnabled) ...[
                      const Divider(height: 1, indent: 64, endIndent: 20),
                      _buildSwitchTile(
                        title: 'الاهتزاز مع الأذان',
                        subtitle: 'تفعيل اهتزاز الهاتف عند تشغيل الأذان',
                        value: _vibrationEnabled,
                        icon: Icons.vibration_rounded,
                        onChanged: (value) => _updateVibrationEnabled(value),
                        iconColor: Colors.blueGrey,
                      ),
                      const Divider(height: 1, indent: 64, endIndent: 20),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 12.h,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: EdgeInsets.all(10.w),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.withValues(alpha: 0.1),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.volume_up_rounded,
                                    color: Colors.amber,
                                    size: 18.sp,
                                  ),
                                ),
                                SizedBox(width: 14.w),
                                Expanded(
                                  child: Text(
                                    'مستوى صوت الأذان',
                                    style: TextStyle(
                                      fontSize: 13.5.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                                Text(
                                  '${(_adhanVolume * 100).toInt()}%',
                                  style: TextStyle(
                                    fontSize: 13.5.sp,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: 8.h),
                            Slider(
                              value: _adhanVolume,
                              min: 0.0,
                              max: 1.0,
                              divisions: 10,
                              activeColor: AppColors.primary,
                              inactiveColor: AppColors.primary.withValues(
                                alpha: 0.2,
                              ),
                              onChanged: (val) {
                                setState(() {
                                  _adhanVolume = val;
                                });
                                if (_isTestingAdhan) {
                                  NativeAlarmService.updateTestVolume(val);
                                } else {
                                  _startTestAdhanWithVolume(val);
                                }
                              },
                              onChangeEnd: (val) {
                                _updateAdhanVolume(val);
                              },
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1, indent: 20, endIndent: 20),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16.w,
                          vertical: 8.h,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                _isTestingAdhan
                                    ? 'جاري تشغيل الأذان التجريبي...'
                                    : 'اختبر صوت ورنين الأذان الأصلي',
                                style: TextStyle(
                                  fontSize: 12.sp,
                                  fontWeight: FontWeight.w500,
                                  color: _isTestingAdhan
                                      ? Colors.red
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                            ElevatedButton.icon(
                              onPressed: _toggleTestAdhan,
                              icon: Icon(
                                _isTestingAdhan
                                    ? Icons.stop_rounded
                                    : Icons.play_arrow_rounded,
                                color: Colors.white,
                                size: 18.sp,
                              ),
                              label: Text(
                                _isTestingAdhan
                                    ? 'إيقاف الأذان'
                                    : 'تشغيل تجريبي',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isTestingAdhan
                                    ? Colors.red.shade600
                                    : AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12.r),
                                ),
                                padding: EdgeInsets.symmetric(
                                  horizontal: 16.w,
                                  vertical: 10.h,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              SizedBox(height: 20.h),

              // 4. صندوق معلومات الموعد التلقائي المحدث
              Container(
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                  borderRadius: BorderRadius.circular(20.r),
                  border: Border.all(
                    color: AppColors.primary.withValues(alpha: 0.15),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primary,
                      size: 24.sp,
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        'يتم تشغيل صوت الأذان كاملاً تلقائياً عند حلول وقت الصلاة وفقاً لموقع مكة المكرمة المبرمج محلياً في التطبيق.',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: isDark ? Colors.white70 : Colors.grey.shade700,
                          height: 1.5,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required Function(bool) onChanged,
    Color? iconColor,
  }) {
    final effectiveIconColor = iconColor ?? AppColors.primary;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(10.w),
            decoration: BoxDecoration(
              color: effectiveIconColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: effectiveIconColor, size: 20.sp),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 13.5.sp,
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 10.w),
          Switch.adaptive(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withValues(alpha: 0.3),
          ),
        ],
      ),
    );
  }
}
