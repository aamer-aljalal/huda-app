import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/providers/theme_provider.dart';
import 'package:huda/core/theme/app_colors.dart';
import 'package:huda/core/widgets/appbars/huda_app_bar.dart';
import 'package:huda/features/Settings/pages/adhan_settings_page.dart';
import 'package:huda/features/Settings/pages/data_maintenance_page.dart';
import 'package:huda/features/Settings/pages/islamic_notifications_page.dart';
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
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: const HudaAppBar(titleText: 'الإعدادات', elevation: 0),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
        child: Column(
          children: [
            // 1. Navigation sections for Adhan, Islamic alerts, and Maintenance
            _buildSection(
              title: 'أقسام الإعدادات',
              isDark: isDark,
              children: [
                _buildNavigationTile(
                  title: 'إعدادات الأذان والصلوات',
                  subtitle: 'صوت المؤذن، تفعيل أو كتم الأذان التلقائي',
                  icon: Icons.notifications_active_outlined,
                  iconColor: Colors.teal,
                  onTap: () {
                    if (_hapticFeedback) HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const AdhanSettingsPage(),
                      ),
                    ).then((_) => _loadSettings());
                  },
                ),
                const Divider(height: 1, indent: 60, endIndent: 20),
                _buildNavigationTile(
                  title: 'التنبيهات والإشعارات الإسلامية',
                  subtitle: 'أذكار الصباح والمساء، قيام الليل، وصيام النوافل',
                  icon: Icons.spa_outlined,
                  iconColor: Colors.amber.shade700,
                  onTap: () {
                    if (_hapticFeedback) HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const IslamicNotificationsPage(),
                      ),
                    ).then((_) => _loadSettings());
                  },
                ),
                const Divider(height: 1, indent: 60, endIndent: 20),
                _buildNavigationTile(
                  title: 'إدارة البيانات والصيانة',
                  subtitle: 'استيراد وتصدير أذكارك، وإعادة ضبط المصنع',
                  icon: Icons.upload_file_outlined,
                  iconColor: Colors.blue.shade700,
                  onTap: () {
                    if (_hapticFeedback) HapticFeedback.lightImpact();
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const DataMaintenancePage(),
                      ),
                    ).then((_) => _loadSettings());
                  },
                ),
              ],
            ),
            SizedBox(height: 20.h),

            // 2. Theme & Haptics Section (Kept in place!)
            _buildSection(
              title: 'المظهر والتفاعل',
              isDark: isDark,
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8.w),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.palette_outlined,
                              color: AppColors.primary,
                              size: 18.sp,
                            ),
                          ),
                          SizedBox(width: 10.w),
                          Text(
                            'مظهر التطبيق',
                            style: TextStyle(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 14.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _buildThemeChip(
                            'نهاري',
                            Icons.wb_sunny_outlined,
                            isDark,
                          ),
                          _buildThemeChip(
                            'ليلي',
                            Icons.nights_stay_outlined,
                            isDark,
                          ),
                          _buildThemeChip(
                            'تلقائي',
                            Icons.settings_brightness_outlined,
                            isDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1, indent: 60, endIndent: 20),
                _buildSwitchTile(
                  title: 'الاهتزاز التفاعلي',
                  subtitle:
                      'اهتزاز خفيف للأزرار والعداد لتحسين تجربة الاستخدام',
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
              ],
            ),
            SizedBox(height: 24.h),

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
                    'تطبيق هُدى الإسلامي',
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
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final effectiveIconColor = iconColor ?? AppColors.primary;
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
                color: effectiveIconColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: effectiveIconColor, size: 20.sp),
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
                      fontSize: 10.5.sp,
                      color: Colors.grey.shade500,
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
