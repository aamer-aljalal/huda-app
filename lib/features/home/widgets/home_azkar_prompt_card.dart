import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/features/azkar/model/zekr_category.dart';
import 'package:huda/features/azkar/services/azkar_service.dart';
import 'package:huda/routes/AppRoutes.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomeAzkarPromptCard extends StatefulWidget {
  const HomeAzkarPromptCard({super.key});

  @override
  State<HomeAzkarPromptCard> createState() => _HomeAzkarPromptCardState();
}

class _HomeAzkarPromptCardState extends State<HomeAzkarPromptCard> {
  ZekrCategory? _category;
  _AzkarPrompt? _prompt;
  bool _isLoading = true;
  bool _isHidden = false;

  @override
  void initState() {
    super.initState();
    _loadPrompt();
  }

  Future<void> _loadPrompt() async {
    final prompt = _AzkarPrompt.forNow(DateTime.now());
    if (prompt == null) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isHidden = true;
      });
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final hiddenKey = _hiddenKey(prompt);
    final isHidden = prefs.getBool(hiddenKey) ?? false;

    if (isHidden) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _isHidden = true;
      });
      return;
    }

    final categories = await AzkarService.loadAzkar();
    final category = categories.firstWhere(
      (item) => item.title == prompt.categoryTitle,
      orElse: () => categories.first,
    );

    if (!mounted) return;
    setState(() {
      _prompt = prompt;
      _category = category;
      _isLoading = false;
    });
  }

  Future<void> _openAzkar() async {
    final prompt = _prompt;
    final category = _category;
    if (prompt == null || category == null) return;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_hiddenKey(prompt), true);

    if (!mounted) return;
    setState(() => _isHidden = true);

    await Navigator.pushNamed(
      context,
      AppRoutes.surahDetails,
      arguments: category,
    );
  }

  String _hiddenKey(_AzkarPrompt prompt) {
    final now = DateTime.now();
    final date = '${now.year}-${now.month}-${now.day}';
    return 'home_azkar_prompt_${prompt.categoryTitle}_$date';
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading || _isHidden || _prompt == null || _category == null) {
      return const SizedBox.shrink();
    }

    return _PromptCard(prompt: _prompt!, onTap: _openAzkar);
  }
}

class _PromptCard extends StatelessWidget {
  const _PromptCard({required this.prompt, required this.onTap});

  final _AzkarPrompt prompt;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.r),
          child: Ink(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
            decoration: BoxDecoration(
              color: colorScheme.primary,
              borderRadius: BorderRadius.circular(8.r),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.12),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 40.w,
                  height: 40.w,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Icon(prompt.icon, color: Colors.white, size: 22.sp),
                ),
                SizedBox(width: 10.w),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        prompt.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          fontSize: 13.sp,
                          height: 1.25,
                        ),
                      ),
                      SizedBox(height: 2.h),
                      Text(
                        prompt.subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white.withValues(alpha: 0.86),
                          fontSize: 10.sp,
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 6.w),
                Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 14.sp,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AzkarPrompt {
  const _AzkarPrompt({
    required this.categoryTitle,
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String categoryTitle;
  final String title;
  final String subtitle;
  final IconData icon;

  static _AzkarPrompt? forNow(DateTime now) {
    final hour = now.hour;

    if (hour >= 4 && hour < 12) {
      return const _AzkarPrompt(
        categoryTitle: 'أذكار الصباح',
        title: 'حان وقت قراءة أذكار الصباح',
        subtitle: 'ابدأ يومك بذكر الله واطمئنان القلب.',
        icon: Icons.wb_sunny_outlined,
      );
    }

    if (hour >= 16 && hour < 21) {
      return const _AzkarPrompt(
        categoryTitle: 'أذكار المساء',
        title: 'حان وقت قراءة أذكار المساء',
        subtitle: 'اختم يومك بسكينة وذكر قبل المساء.',
        icon: Icons.nights_stay_outlined,
      );
    }

    if (hour >= 21 || hour < 4) {
      return const _AzkarPrompt(
        categoryTitle: 'أذكار النوم',
        title: 'حان وقت قراءة أذكار النوم',
        subtitle: 'اقرأ ورد النوم قبل أن تستريح.',
        icon: Icons.bedtime_outlined,
      );
    }

    return null;
  }
}
