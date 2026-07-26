import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/providers/theme_provider.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'dart:convert';
import 'package:share_plus/share_plus.dart';
import 'package:tarteel/core/services/general_notification_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _hapticFeedback = true;
  String _themeMode = 'تلقائي';
  bool _notificationsAzkar = true;
  bool _notificationsFriday = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _hapticFeedback = prefs.getBool('haptic_feedback') ?? true;
      _themeMode = prefs.getString('theme_mode') ?? 'تلقائي';
      _notificationsAzkar = prefs.getBool('notifications_azkar') ?? true;
      _notificationsFriday = prefs.getBool('notifications_friday') ?? true;
    });
  }

  Future<void> _exportData() async {
    if (_hapticFeedback) HapticFeedback.lightImpact();
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys();
      final Map<String, dynamic> backupData = {};
      for (final key in keys) {
        backupData[key] = prefs.get(key);
      }

      final String jsonStr = jsonEncode(backupData);
      await Share.share(jsonStr, subject: 'نسخة احتياطية من تطبيق هدى');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'حدث خطأ أثناء تصدير البيانات: $e',
              textAlign: TextAlign.right,
            ),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  void _showImportDialog() {
    if (_hapticFeedback) HapticFeedback.lightImpact();
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24.r),
        ),
        title: const Text(
          'استيراد نسخة احتياطية',
          textAlign: TextAlign.right,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Text(
              'قم بلصق كود النسخة الاحتياطية الذي قمت بتصديره ومشاركته سابقاً في الحقل أدناه لاسترجاع كافة بياناتك وتفضيلاتك:',
              textAlign: TextAlign.right,
              style: TextStyle(fontSize: 12),
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: controller,
              maxLines: 5,
              textDirection: TextDirection.ltr,
              decoration: InputDecoration(
                hintText: '{...}',
                hintStyle: TextStyle(color: Colors.grey.shade400),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
                contentPadding: EdgeInsets.all(12.w),
              ),
              style: TextStyle(fontSize: 11.sp, fontFamily: 'monospace'),
            ),
          ],
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final String text = controller.text.trim();
              if (text.isEmpty) return;

              try {
                final Map<String, dynamic> data = jsonDecode(text);
                final prefs = await SharedPreferences.getInstance();

                // Clear existing prefs
                await prefs.clear();

                // Restore each key
                for (final entry in data.entries) {
                  final key = entry.key;
                  final value = entry.value;
                  if (value is bool) {
                    await prefs.setBool(key, value);
                  } else if (value is int) {
                    await prefs.setInt(key, value);
                  } else if (value is double) {
                    await prefs.setDouble(key, value);
                  } else if (value is String) {
                    await prefs.setString(key, value);
                  } else if (value is List) {
                    await prefs.setStringList(key, List<String>.from(value));
                  }
                }

                // Re-initialize all schedules in background
                await GeneralNotificationService.scheduleAllEnabledNotifications();

                // Reload settings on screen
                await _loadSettings();

                navigator.pop();
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text(
                      'تم استيراد النسخة الاحتياطية وإعادة جدولة التنبيهات بنجاح!',
                      textAlign: TextAlign.right,
                    ),
                    backgroundColor: AppColors.primary,
                  ),
                );
              } catch (e) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(
                      'فشل الاستيراد: يرجى التأكد من صحة كود النسخة ($e)',
                      textAlign: TextAlign.right,
                    ),
                    backgroundColor: Colors.red.shade700,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: const Text('استيراد وتطبيق'),
          ),
        ],
      ),
    );
  }

  void _showResetWarningDialog() {
    if (_hapticFeedback) HapticFeedback.vibrate();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20.r),
        ),
        title: const Text(
          'تنبيه هام! إعادة الضبط',
          textAlign: TextAlign.right,
          style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'هل أنت متأكد تماماً أنك تريد إعادة ضبط المصنع؟ سيؤدي هذا الإجراء إلى حذف جميع أذكارك المخصصة والمحفوظات نهائياً ولا يمكن التراجع عنه.',
          textAlign: TextAlign.right,
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: Colors.grey.shade600)),
          ),
          ElevatedButton(
            onPressed: () async {
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              final prefs = await SharedPreferences.getInstance();
              await prefs.clear();

              // Reload settings on screen
              await _loadSettings();

              navigator.pop();
              messenger.showSnackBar(
                const SnackBar(
                  content: Text(
                    'تمت إعادة ضبط المصنع بنجاح',
                    textAlign: TextAlign.right,
                  ),
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10.r),
              ),
            ),
            child: const Text('إعادة ضبط ومسح'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const tarteelAppBar(titleText: 'الإعدادات', elevation: 0),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildThemeChip('نهاري', Icons.wb_sunny_outlined, isDark),
                _buildThemeChip('ليلي', Icons.nights_stay_outlined, isDark),
                _buildThemeChip(
                  'تلقائي',
                  Icons.settings_brightness_outlined,
                  isDark,
                ),
              ],
            ),
            SizedBox(height: 10.h),
            _buildSwitchTile(
              title: 'الاهتزاز التفاعلي',
              subtitle: 'اهتزاز خفيف للأزرار والعداد لتحسين تجربة الاستخدام',
              value: _hapticFeedback,
              icon: Icons.vibration_rounded,
              onChanged: (val) async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('haptic_feedback', val);
                setState(() {
                  _hapticFeedback = val;
                });
                if (val) HapticFeedback.mediumImpact();
              },
              iconColor: Colors.blueGrey,
            ),
            const Divider(height: 1, indent: 60, endIndent: 20),
            _buildSwitchTile(
              title: 'تذكير أذكار الصباح والمساء',
              subtitle: 'تنبيهات يومية لقراءة الأذكار المأثورة في أوقاتها',
              value: _notificationsAzkar,
              icon: Icons.spa_outlined,
              onChanged: (val) async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('notifications_azkar', val);
                setState(() {
                  _notificationsAzkar = val;
                });
                await GeneralNotificationService.scheduleAllEnabledNotifications();
                if (_hapticFeedback) HapticFeedback.lightImpact();
              },
              iconColor: Colors.amber.shade700,
            ),
            const Divider(height: 1, indent: 60, endIndent: 20),
            _buildSwitchTile(
              title: 'تنبيهات يوم الجمعة',
              subtitle: 'تذكير بقراءة سورة الكهف والصلاة على النبي ﷺ',
              value: _notificationsFriday,
              icon: Icons.mosque_outlined,
              onChanged: (val) async {
                final prefs = await SharedPreferences.getInstance();
                await prefs.setBool('notifications_friday', val);
                setState(() {
                  _notificationsFriday = val;
                });
                await GeneralNotificationService.scheduleAllEnabledNotifications();
                if (_hapticFeedback) HapticFeedback.lightImpact();
              },
              iconColor: Colors.green.shade700,
            ),
            SizedBox(height: 20.h),

            _buildSection(
              title: 'النسخ الاحتياطي والصيانة',
              isDark: isDark,
              children: [
                _buildActionTile(
                  icon: Icons.upload_file_outlined,
                  title: 'تصدير البيانات والمحفوظات',
                  color: Colors.blue.shade700,
                  onTap: _exportData,
                ),
                const Divider(height: 1, indent: 60, endIndent: 20),
                _buildActionTile(
                  icon: Icons.download_outlined,
                  title: 'استيراد البيانات والمحفوظات',
                  color: AppColors.primary,
                  onTap: _showImportDialog,
                ),
                const Divider(height: 1, indent: 60, endIndent: 20),
                _buildActionTile(
                  icon: Icons.delete_forever_outlined,
                  title: 'إعادة ضبط المصنع',
                  color: Colors.red.shade700,
                  onTap: _showResetWarningDialog,
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // Premium Caution Box
            Container(
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: Colors.red.shade700.withValues(alpha: 0.15),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.red.shade700,
                    size: 24.sp,
                  ),
                  SizedBox(width: 12.w),
                  Expanded(
                    child: Text(
                      'تنبيه: عملية إعادة ضبط المصنع ستقوم بمسح كامل للإعدادات المخزنة محلياً على جهازك بشكل دائم ولا يمكن استردادها.',
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
            SizedBox(height: 20.h),

            // 3. App Info Gilded Card
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isDark
                      ? [const Color(0xFF1E1E1E), const Color(0xFF121212)]
                      : [Colors.grey.shade50, Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24.r),
                border: Border.all(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.2)
                        : Colors.grey.shade100,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.all(12.w),
                    decoration: BoxDecoration(
                      color: AppColors.goldAccent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.mosque_outlined,
                      size: 36.sp,
                      color: AppColors.goldAccent,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'تطبيق ترتيل الإسلامي',
                    style: TextStyle(
                      fontSize: 16.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    'الإصدار 1.0.0',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: Colors.grey.shade500,
                    ),
                  ),
                  SizedBox(height: 12.h),
                  Text(
                    'نسأل الله أن يتقبل منا ومنكم صالح الأعمال، وأن يجعل هذا العمل خالصاً لوجهه الكريم.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isDark
                          ? Colors.grey.shade400
                          : Colors.grey.shade600,
                      height: 1.6,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 30.h),
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
                if (subtitle.isNotEmpty) ...[],
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

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required Color color,
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
                color: color.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: color, size: 20.sp),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 13.5.sp,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 12.sp,
              color: Colors.grey.shade400,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildThemeChip(String label, IconData icon, bool isDark) {
    final isSelected = _themeMode == label;
    return Expanded(
      child: GestureDetector(
        onTap: () async {
          setState(() {
            _themeMode = label;
          });
          if (_hapticFeedback) HapticFeedback.lightImpact();

          // Real-time dynamic theme update!
          if (mounted) {
            await Provider.of<ThemeProvider>(
              context,
              listen: false,
            ).updateTheme(label);
          }
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: EdgeInsets.symmetric(horizontal: 4.w),
          padding: EdgeInsets.symmetric(vertical: 12.h),
          decoration: BoxDecoration(
            color: isSelected
                ? AppColors.primary.withValues(alpha: 0.12)
                : (isDark ? const Color(0xFF2C2C2C) : Colors.grey.shade50),
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isSelected
                  ? AppColors.primary
                  : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : Colors.grey.shade200),
              width: 1.5,
            ),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ]
                : [],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 16.sp,
                color: isSelected
                    ? AppColors.primary
                    : (isDark ? Colors.white60 : Colors.grey.shade600),
              ),
              SizedBox(width: 8.w),
              Text(
                label,
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? Colors.white70 : Colors.grey.shade700),
                  fontSize: 12.sp,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
