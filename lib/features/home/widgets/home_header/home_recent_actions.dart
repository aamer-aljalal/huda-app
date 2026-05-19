import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/services.dart';
import 'package:huda/Routes/AppRoutes.dart';
import 'package:huda/core/services/recent_actions_service.dart';
import 'package:huda/core/theme/app_colors.dart';
import 'package:huda/features/azkar/services/azkar_service.dart';
import 'package:huda/features/quran/services/quran_service.dart';
import 'package:huda/features/quran/views/surah_detail_page.dart';

class HomeRecentActions extends StatelessWidget {
  const HomeRecentActions({super.key});
  Future<void> _resumeQuran(BuildContext context, int surahNumber) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final surahs = await QuranService.loadSurahs();
      final surah = surahs.firstWhere((s) => s.number == surahNumber);
      final ayahs = await QuranService.loadAyahs(surahNumber);

      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SurahDetailPage(
              surah: surah,
              ayahs: ayahs,
              resumeLastPage: true,
            ),
          ),
        );
      }
    } catch (_) {
      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر فتح الصفحة المحفوظة')),
        );
      }
    }
  }

  Future<void> _resumeAzkar(BuildContext context, String categoryTitle) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final categories = await AzkarService.loadAzkar();
      final category = categories.firstWhere((c) => c.title == categoryTitle);

      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        Navigator.pushNamed(
          context,
          AppRoutes.zkarDetails,
          arguments: category,
        );
      }
    } catch (_) {
      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر فتح الأذكار')));
      }
    }
  }

  Future<void> _resumeHadith(BuildContext context, int hadithNumber) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        Navigator.pushNamed(context, AppRoutes.hadith, arguments: hadithNumber);
      }
    } catch (_) {
      if (context.mounted) {
        Navigator.pop(context); // Close dialog
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('تعذر فتح الحديث')));
      }
    }
  }

  void _handleRecentActionTap(BuildContext context, RecentAction action) {
    HapticFeedback.lightImpact();
    if (action.category == 'quran') {
      final surahNumber = action.extraData['surah_number'] as int?;
      if (surahNumber != null) {
        _resumeQuran(context, surahNumber);
      }
    } else if (action.category == 'azkar') {
      final categoryTitle = action.extraData['category_title'] as String?;
      if (categoryTitle != null) {
        _resumeAzkar(context, categoryTitle);
      }
    } else if (action.category == 'hadith') {
      final hadithNumber = action.extraData['hadith_number'] as int?;
      if (hadithNumber != null) {
        _resumeHadith(context, hadithNumber);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return FutureBuilder<List<RecentAction>>(
      future: RecentActionsManager.getActions(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox.shrink();
        }
        final actions = snapshot.data!;
        return Container(
          padding: EdgeInsets.symmetric(horizontal: 10.w),
          decoration: BoxDecoration(
            color: colorScheme.surface.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: colorScheme.onSurface.withValues(alpha: 0.1),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 3.h),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: actions
                    .map((action) => _buildRecentButton(context, action))
                    .toList(),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildRecentButton(BuildContext context, RecentAction action) {
    IconData getIcon() {
      switch (action.category) {
        case 'quran':
          return Icons.menu_book_rounded;
        case 'azkar':
          return Icons.bookmark_added_rounded;
        case 'hadith':
          return Icons.auto_stories_rounded;
        case 'names_of_allah':
          return Icons.auto_awesome_rounded;
        default:
          return Icons.history_toggle_off_rounded;
      }
    }

    // Color getCategoryColor(ColorScheme colorScheme) {
    //   switch (action.category) {
    //     case 'quran':
    //       return Colors.greenAccent;
    //     case 'azkar':
    //       return Colors.amberAccent;
    //     case 'hadith':
    //       return Colors.orangeAccent;
    //     case 'names_of_allah':
    //       return Colors.cyanAccent;
    //     default:
    //       return Colors.white70;
    //   }
    // }

    return Expanded(
      child: InkWell(
        onTap: () => _handleRecentActionTap(context, action),
        borderRadius: BorderRadius.circular(12.r),
        child: Column(
          // mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.darkPrimaryText),

                color: Theme.of(
                  context,
                ).colorScheme.surface.withValues(alpha: 0.22),
                shape: BoxShape.circle,
              ),
              child: Icon(
                getIcon(),
                size: 16.sp,
                // color: getCategoryColor(Theme.of(context).colorScheme),
                color: Colors.white,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              '${action.title.replaceAll('سورة ', '')}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 7.5.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            SizedBox(height: 2.h),
          ],
        ),
      ),
    );
  }
}
