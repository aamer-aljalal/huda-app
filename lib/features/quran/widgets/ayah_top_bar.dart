import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/features/quran/services/quran_service.dart';
import 'package:tarteel/features/quran/views/quran_verse_search_page.dart';

class MushafTopBar extends StatelessWidget {
  const MushafTopBar({
    super.key,
    required this.surah,
    required this.isPageView,
    required this.onReadingModeChanged,
    required this.allSurahs,
    required this.onNavigateToSurah,
  });

  final QuranSurah surah;
  final bool isPageView;
  final ValueChanged<bool> onReadingModeChanged;
  final List<QuranSurah> allSurahs;
  final Function(int surahNumber) onNavigateToSurah;

  void _showReadingSettings(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return ReadingSettingsSheet(
          isPageView: isPageView,
          onReadingModeChanged: onReadingModeChanged,
        );
      },
    );
  }

  void _showSurahSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return SurahSelectorSheet(
          allSurahs: allSurahs,
          currentSurah: surah,
          onNavigate: onNavigateToSurah,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 8.h),
      decoration: BoxDecoration(
        color: const Color(0XFF244E38),
        borderRadius: BorderRadius.circular(4.r),
        image: const DecorationImage(
          image: AssetImage('assets/img/top_bar.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(Colors.black38, BlendMode.darken),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 2. Surah Selector Menu
          IconButton(
            icon: Icon(
              Icons.format_list_bulleted_rounded,
              color: Colors.white.withValues(alpha: 0.9),
              size: 20.sp,
            ),
            onPressed: () => _showSurahSelector(context),
            tooltip: 'فهرس السور',
          ),

          // Centered Premium Surah Name & Info (Auto-scales, no overlap)
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    'سورة ${surah.nameArabic}',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w900,
                      fontFamily: 'Amiri',
                      height: 1.8,
                    ),
                  ),
                ),
                SizedBox(height: 2.h),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    '${surah.revelationPlace == 'makkah' ? 'مكية' : 'مدنية'} • ${surah.versesCount} آية',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: const Color(0xFFEABB11),
                      fontSize: 12.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'Cairo',
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Left Actions: Settings, Back Button
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 3. Settings (Gear icon)
              IconButton(
                icon: Icon(
                  Icons.settings_rounded,
                  color: Colors.white.withValues(alpha: 0.9),
                  size: 20.sp,
                ),
                onPressed: () => _showReadingSettings(context),
                tooltip: 'إعدادات القراءة',
              ),

              // Back Button
              IconButton(
                icon: Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: Colors.white,
                  size: 20.sp,
                ),
                onPressed: () => Navigator.pop(context),
                tooltip: 'رجوع',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ReadingSettingsSheet extends StatelessWidget {
  final bool isPageView;
  final ValueChanged<bool> onReadingModeChanged;

  const ReadingSettingsSheet({
    super.key,
    required this.isPageView,
    required this.onReadingModeChanged,
  });

  Widget _buildSearchCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        Navigator.pop(context); // close sheet
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const QuranVerseSearchPage()),
        );
      },
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: isDark ? Colors.black12 : Colors.grey.shade50,
          border: Border.all(
            color: isDark ? Colors.white10 : Colors.grey.shade200,
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(
              Icons.search_rounded,
              color: AppColors.goldAccent,
              size: 24.sp,
            ),
            SizedBox(width: 16.w),
            Expanded( 
              child: Text(
                'البحث عن آية في المصحف',
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ),
            Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Colors.grey,
              size: 14.sp,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 24.h + bottomPadding),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF162521) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.grey.shade400,
                  borderRadius: BorderRadius.circular(2.r),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            // Text(
            //   'خيارات عرض المصحف',
            //   textAlign: TextAlign.center,
            //   style: TextStyle(
            //     fontSize: 16.sp,
            //     fontWeight: FontWeight.bold,
            //     fontFamily: 'Cairo',
            //     color: isDark ? Colors.white : AppColors.primary,
            //   ),
            // ),

            // Search option at the top
            _buildSearchCard(context),
            SizedBox(height: 16.h),
            Row(
              children: [
                Expanded(
                  child: Divider(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    thickness: 1,
                  ),
                ),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.w),
                  child: Text(
                    'طريقة العرض',
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Cairo',
                      color: isDark ? Colors.white70 : Colors.grey.shade700,
                    ),
                  ),
                ),
                Expanded(
                  child: Divider(
                    color: isDark ? Colors.white24 : Colors.grey.shade300,
                    thickness: 1,
                  ),
                ),
              ],
            ),
            SizedBox(height: 12.h),
            Row(
              children: [
                Expanded(
                  child: _buildModeCard(
                    context: context,
                    title: 'صفحات',
                    icon: Icons.auto_stories_rounded,
                    isActive: isPageView,
                    onTap: () {
                      onReadingModeChanged(true);
                      Navigator.pop(context);
                    },
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: _buildModeCard(
                    context: context,
                    title: 'قائمة متصلة',
                    icon: Icons.format_list_bulleted_rounded,
                    isActive: !isPageView,
                    onTap: () {
                      onReadingModeChanged(false);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModeCard({
    required BuildContext context,
    required String title,
    required IconData icon,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
        decoration: BoxDecoration(
          color: isActive
              ? (isDark
                    ? AppColors.primary.withValues(alpha: 0.15)
                    : AppColors.primary.withValues(alpha: 0.05))
              : (isDark ? Colors.black12 : Colors.grey.shade50),
          border: Border.all(
            color: isActive
                ? AppColors.goldAccent
                : (isDark ? Colors.white10 : Colors.grey.shade200),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isActive ? AppColors.goldAccent : Colors.grey,
              size: 24.sp,
            ),
            SizedBox(width: 16.w),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 9.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: isActive
                      ? (isDark ? Colors.white : AppColors.primary)
                      : (isDark ? Colors.grey : Colors.black87),
                ),
              ),
            ),
            if (isActive)
              Icon(
                Icons.check_circle,
                color: AppColors.goldAccent,
                size: 20.sp,
              ),
          ],
        ),
      ),
    );
  }
}

class SurahSelectorSheet extends StatefulWidget {
  final List<QuranSurah> allSurahs;
  final QuranSurah currentSurah;
  final Function(int surahNumber) onNavigate;

  const SurahSelectorSheet({
    super.key,
    required this.allSurahs,
    required this.currentSurah,
    required this.onNavigate,
  });

  @override
  State<SurahSelectorSheet> createState() => _SurahSelectorSheetState();
}

class _SurahSelectorSheetState extends State<SurahSelectorSheet> {
  final TextEditingController _searchController = TextEditingController();
  List<QuranSurah> _filteredSurahs = [];

  @override
  void initState() {
    super.initState();
    _filteredSurahs = widget.allSurahs;
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        _filteredSurahs = widget.allSurahs;
      });
      return;
    }

    setState(() {
      _filteredSurahs = widget.allSurahs.where((s) {
        final name = s.nameArabic;
        final nameEnglish = s.nameEnglish.toLowerCase();
        final search = query.toLowerCase();
        return name.contains(search) || nameEnglish.contains(search);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF162521) : Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              width: 40.w,
              height: 4.h,
              margin: EdgeInsets.symmetric(vertical: 12.h),
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(2.r),
              ),
            ),
            // Title
            Text(
              'سور القرآن الكريم',
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: isDark ? Colors.white : AppColors.primary,
              ),
            ),
            SizedBox(height: 12.h),
            // Search textfield
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: TextField(
                controller: _searchController,
                textAlign: TextAlign.right,
                style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp),
                decoration: InputDecoration(
                  hintText: 'ابحث عن سورة...',
                  hintStyle: TextStyle(
                    color: Colors.grey,
                    fontSize: 13.sp,
                    fontFamily: 'Cairo',
                  ),
                  prefixIcon: const Icon(Icons.search, color: Colors.grey),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                  filled: true,
                  fillColor: isDark ? Colors.black12 : Colors.grey.shade100,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 10.h,
                    horizontal: 16.w,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            SizedBox(height: 16.h),
            // List view
            Expanded(
              child: _filteredSurahs.isEmpty
                  ? Center(
                      child: Text(
                        'لا توجد نتائج بحث',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontFamily: 'Cairo',
                          color: Colors.grey,
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _filteredSurahs.length,
                      padding: EdgeInsets.only(
                        left: 16.w,
                        right: 16.w,
                        top: 8.h,
                        bottom: 24.h + bottomPadding,
                      ),
                      itemBuilder: (context, index) {
                        final surah = _filteredSurahs[index];
                        final isCurrent =
                            surah.number == widget.currentSurah.number;
                        return Padding(
                          padding: EdgeInsets.only(bottom: 8.h),
                          child: InkWell(
                            onTap: () {
                              Navigator.pop(context);
                              widget.onNavigate(surah.number);
                            },
                            borderRadius: BorderRadius.circular(12.r),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16.w,
                                vertical: 12.h,
                              ),
                              decoration: BoxDecoration(
                                color: isCurrent
                                    ? (isDark
                                          ? AppColors.primary.withValues(
                                              alpha: 0.2,
                                            )
                                          : AppColors.primary.withValues(
                                              alpha: 0.05,
                                            ))
                                    : (isDark
                                          ? Colors.white10
                                          : Colors.grey.shade50),
                                border: Border.all(
                                  color: isCurrent
                                      ? AppColors.goldAccent
                                      : Colors.transparent,
                                  width: 1,
                                ),
                                borderRadius: BorderRadius.circular(12.r),
                              ),
                              child: Row(
                                children: [
                                  // Surah Number badge
                                  Container(
                                    width: 32.w,
                                    height: 32.w,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: isCurrent
                                          ? AppColors.goldAccent
                                          : (isDark
                                                ? Colors.white10
                                                : Colors.grey.shade200),
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${surah.number}',
                                        style: TextStyle(
                                          fontSize: 12.sp,
                                          fontWeight: FontWeight.bold,
                                          color: isCurrent
                                              ? Colors.white
                                              : (isDark
                                                    ? Colors.white70
                                                    : Colors.black87),
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 16.w),
                                  // Surah Info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'سورة ${surah.nameArabic}',
                                          style: TextStyle(
                                            fontSize: 14.sp,
                                            fontWeight: FontWeight.bold,
                                            fontFamily: 'Cairo',
                                            color: isCurrent
                                                ? AppColors.goldAccent
                                                : (isDark
                                                      ? Colors.white
                                                      : Colors.black87),
                                          ),
                                        ),
                                        Text(
                                          '${surah.revelationPlace == 'makkah' ? 'مكية' : 'مدنية'} • ${surah.versesCount} آية',
                                          style: TextStyle(
                                            fontSize: 11.sp,
                                            fontFamily: 'Cairo',
                                            color: isDark
                                                ? Colors.grey.shade400
                                                : Colors.grey.shade600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (isCurrent)
                                    Icon(
                                      Icons.check_circle,
                                      color: AppColors.goldAccent,
                                      size: 18.sp,
                                    ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
