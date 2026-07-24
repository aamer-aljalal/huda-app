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

class AdhanSettingsPage extends StatefulWidget {
  const AdhanSettingsPage({super.key});

  @override
  State<AdhanSettingsPage> createState() => _AdhanSettingsPageState();
}

class _AdhanSettingsPageState extends State<AdhanSettingsPage> {
  bool _soundEnabled = true;
  AdhanMuezzin? _activeMuezzin;
  bool _hapticFeedback = true;
  double _adhanVolume = 1.0;
  bool _vibrationEnabled = true;
  bool _isTestingAdhan = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final notificationsEnabled =
        await AdhanNotificationService.arePrayerNotificationsEnabled();
    final activeMuezzin = await AdhanNotificationService.selectedMuezzin();
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;
    setState(() {
      _soundEnabled = notificationsEnabled;
      _activeMuezzin = activeMuezzin;
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
    // إعادة جدولة المنبهات بالصوت الجديد
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
    // إعادة جدولة المنبهات بالاهتزاز الجديد
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
      if (_activeMuezzin == null) return;
      if (_hapticFeedback) HapticFeedback.mediumImpact();

      setState(() {
        _isTestingAdhan = true;
      });

      final success = await NativeAlarmService.playTestAdhan(
        audioFile: _activeMuezzin!.rawResourceName,
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

  void _showMuezzinSelectionSheet() async {
    final activeMuezzin = await AdhanNotificationService.selectedMuezzin();
    final AudioPlayer previewPlayer = AudioPlayer();
    String? playingMuezzinId;

    if (!mounted) return;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24.r)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final isDark = Theme.of(context).brightness == Brightness.dark;
          return Container(
            padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h),
            height: 520.h,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40.w,
                    height: 4.h,
                    margin: EdgeInsets.only(bottom: 16.h),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.grey.shade800
                          : Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                  ),
                ),
                Text(
                  'اختر صوت المؤذن',
                  style: TextStyle(
                    fontSize: 18.sp,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16.h),
                Expanded(
                  child: ListView.builder(
                    itemCount: AdhanNotificationService.muezzins.length,
                    itemBuilder: (context, index) {
                      final muezzin = AdhanNotificationService.muezzins[index];
                      final isSelected = activeMuezzin.id == muezzin.id;
                      final isPlaying = playingMuezzinId == muezzin.id;

                      return Container(
                        margin: EdgeInsets.only(bottom: 10.h),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.primary.withValues(alpha: 0.05)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(16.r),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.primary.withValues(alpha: 0.3)
                                : (isDark
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade200),
                          ),
                        ),
                        child: ListTile(
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 4.h,
                          ),
                          title: Text(
                            muezzin.name,
                            style: TextStyle(
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.w500,
                              color: isSelected ? AppColors.primary : null,
                              fontSize: 15.sp,
                            ),
                            textAlign: TextAlign.right,
                          ),
                          leading: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(
                                  isPlaying
                                      ? Icons.stop_circle_rounded
                                      : Icons.play_circle_outline_rounded,
                                  color: isPlaying
                                      ? Colors.red
                                      : AppColors.primary,
                                  size: 28.sp,
                                ),
                                onPressed: () async {
                                  if (isPlaying) {
                                    await previewPlayer.stop();
                                    setModalState(() {
                                      playingMuezzinId = null;
                                    });
                                  } else {
                                    try {
                                      await previewPlayer.setAsset(
                                        muezzin.assetPath,
                                      );
                                      setModalState(() {
                                        playingMuezzinId = muezzin.id;
                                      });
                                      previewPlayer.play();
                                      previewPlayer.processingStateStream
                                          .listen((state) {
                                            if (state ==
                                                ProcessingState.completed) {
                                              setModalState(() {
                                                playingMuezzinId = null;
                                              });
                                            }
                                          });
                                    } catch (e) {
                                      debugPrint('Error playing preview: $e');
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle_rounded,
                                  color: AppColors.primary,
                                  size: 24.sp,
                                )
                              : null,
                          onTap: () async {
                            if (_hapticFeedback) {
                              HapticFeedback.mediumImpact();
                            }
                            await previewPlayer.stop();
                            await AdhanNotificationService.setSelectedMuezzin(
                              muezzin,
                            );

                            if (mounted) {
                              final prayerProvider = context
                                  .read<PrayerProvider>();
                              await prayerProvider.scheduleAdhanNotifications();
                              if (mounted) {
                                Navigator.pop(context);
                                _loadSettings();
                              }
                            }
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    ).then((_) {
      previewPlayer.dispose();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const tarteelAppBar(
        titleText: 'إعدادات الأذان والصلوات',
        elevation: 0,
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          children: [
            _buildSection(
              title: 'التنبيهات والأذان',
              isDark: isDark,
              children: [
                _buildSwitchTile(
                  title: 'تفعيل تنبيهات الأذان والصلوات',
                  subtitle:
                      'تشغيل صوت المؤذن عند دخول وقت الصلاة وتنبيه الأذان',
                  value: _soundEnabled,
                  icon: Icons.notifications_active_outlined,
                  onChanged: (value) => _updateSoundEnabled(value),
                  iconColor: Colors.teal,
                ),
                if (_soundEnabled) ...[
                  const Divider(height: 1, indent: 60, endIndent: 20),
                  _buildNavigationTile(
                    title: 'صوت المؤذن المختار',
                    subtitle: _activeMuezzin?.name ?? 'مولانا كورتشي',
                    icon: Icons.volume_up_outlined,
                    trailingText: 'تغيير ومراجعة',
                    onTap: _showMuezzinSelectionSheet,
                  ),
                ],
              ],
            ),
            SizedBox(height: 20.h),
            if (_soundEnabled) ...[
              _buildSection(
                title: 'خيارات الصوت والاهتزاز',
                isDark: isDark,
                children: [
                  _buildSwitchTile(
                    title: 'الاهتزاز مع الأذان',
                    subtitle: 'تفعيل اهتزاز الهاتف عند تشغيل الأذان',
                    value: _vibrationEnabled,
                    icon: Icons.vibration_rounded,
                    onChanged: (value) => _updateVibrationEnabled(value),
                    iconColor: Colors.blueGrey,
                  ),
                  const Divider(height: 1, indent: 60, endIndent: 20),
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
                                size: 20.sp,
                              ),
                            ),
                            SizedBox(width: 14.w),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'مستوى صوت الأذان',
                                    style: TextStyle(
                                      fontSize: 13.5.sp,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 4.h),
                                  Text(
                                    'تحديد شدة صوت الأذان عند الرنين',
                                    style: TextStyle(
                                      fontSize: 10.5.sp,
                                      color: Colors.grey.shade500,
                                    ),
                                  ),
                                ],
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
                            }
                          },
                          onChangeEnd: (val) {
                            _updateAdhanVolume(val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const Divider(height: 1, indent: 60, endIndent: 20),
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
                                : 'اختبر صوت ورنين الأذان الآن',
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
                          ),
                          label: Text(
                            _isTestingAdhan ? 'إيقاف الأذان' : 'تشغيل تجريبي',
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
              ),
              SizedBox(height: 20.h),
            ],
            // Premium Info Box
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
    );
  }

  Widget _buildSection({
    required String title,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.3)
                : Colors.grey.shade100,
            blurRadius: 16,
            spreadRadius: 2,
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(
              right: 20.w,
              left: 20.w,
              top: 18.h,
              bottom: 8.h,
            ),
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
                  title,
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : AppColors.primary,
                    letterSpacing: 0.2,
                  ),
                ),
              ],
            ),
          ),
          ...children,
        ],
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
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10.5.sp,
                    color: Colors.grey.shade500,
                    height: 1.3,
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

  Widget _buildNavigationTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required String trailingText,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(10.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppColors.primary, size: 20.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 13.5.sp,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: AppColors.goldAccent,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 6.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Row(
                children: [
                  Text(
                    trailingText,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: AppColors.primary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(width: 6.w),
                  Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 10.sp,
                    color: AppColors.primary,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
