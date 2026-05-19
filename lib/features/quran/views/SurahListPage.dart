import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/widgets/appbars/huda_app_bar.dart';
import 'package:huda/features/quran/services/quran_service.dart';
import 'package:huda/features/quran/views/surah_detail_page.dart';
import 'package:huda/features/quran/views/quran_verse_search_page.dart';

class SurahListPage extends StatefulWidget {
  const SurahListPage({super.key});

  @override
  State<SurahListPage> createState() => _SurahListPageState();
}

class _SurahListPageState extends State<SurahListPage> {
  final TextEditingController searchController = TextEditingController();

  List<QuranSurah> allSurahs = [];
  List<QuranSurah> filteredSurahs = [];
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _loadSurahs();
    searchController.addListener(_filterSurahs);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSurahs() async {
    try {
      final surahs = await QuranService.loadSurahs();
      if (!mounted) return;
      setState(() {
        allSurahs = surahs;
        filteredSurahs = surahs;
        isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        errorMessage = 'تعذر تحميل سور القرآن';
        isLoading = false;
      });
    }
  }

  void _filterSurahs() {
    final query = searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredSurahs = allSurahs;
      } else {
        filteredSurahs = allSurahs.where((surah) {
          return surah.nameArabic.contains(query) ||
              surah.nameEnglish.toLowerCase().contains(query) ||
              surah.transliteration.toLowerCase().contains(query) ||
              surah.number.toString().contains(query);
        }).toList();
      }
    });
  }

  Future<void> _openSurah(QuranSurah surah) async {
    final ayahs = await QuranService.loadAyahs(surah.number);
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SurahDetailPage(surah: surah, ayahs: ayahs),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: HudaAppBar(
          titleText: 'القرآن الكريم',
          showSearch: true,
          searchController: searchController,
          searchHint: 'ابحث عن سورة...',
          onVerseSearchPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const QuranVerseSearchPage()),
            );
          },
          centerTitle: true,
          elevation: 0,
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (errorMessage != null) {
      return Center(
        child: Text(
          errorMessage!,
          style: TextStyle(fontSize: 16.sp, color: Colors.red.shade700),
        ),
      );
    }

    if (filteredSurahs.isEmpty) {
      return Center(
        child: Text(
          'لا توجد نتائج',
          style: TextStyle(
            fontSize: 18.sp,
            color: Colors.grey,
            fontFamily: 'Cairo',
          ),
        ),
      );
    }

    final isSearching = searchController.text.trim().isNotEmpty;

    return ListView.builder(
      padding: EdgeInsets.all(16.w),
      itemCount: filteredSurahs.length + (isSearching ? 0 : 1),
      itemBuilder: (context, index) {
        if (!isSearching && index == 0) {
          return _buildKhatmaPromoCard();
        }
        final surah = filteredSurahs[isSearching ? index : index - 1];
        return _SurahTile(surah: surah, onTap: () => _openSurah(surah));
      },
    );
  }

  Widget _buildKhatmaPromoCard() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Custom premium HSL-tailored colors for an elite royal-islamic visual style
    final emeraldDeep = isDark
        ? const Color(0xFF0F3A2E)
        : const Color(0xFF144D3E);
    final emeraldLight = isDark
        ? const Color(0xFF1D5A4A)
        : const Color(0xFF227E67);
    const accentGold = Color(0xFFE2B755);

    return Padding(
      padding: EdgeInsets.only(
        bottom: 12.h,
      ), // Matches _SurahTile padding exactly!
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [emeraldDeep, emeraldLight],
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
          ),
          borderRadius: BorderRadius.circular(
            8.r,
          ), // Matches _SurahTile radius exactly!
          border: Border.all(
            color: accentGold.withValues(alpha: 0.35),
            width: 1.2.w,
          ),
          boxShadow: [
            BoxShadow(
              color: emeraldDeep.withValues(alpha: 0.15),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(8.r),
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(context, '/khatma-planner');
            },
            borderRadius: BorderRadius.circular(8.r),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16.w,
                vertical: 14.h,
              ),
               // Matches _SurahTile height balance perfectly!
              child: Row(
                children: [
                  // Gold Ring Glowing Icon Container (Matches _SurahNumber size perfectly)
                  Container(
                    width: 42.w,
                    height: 42.w,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.12),
                      border: Border.all(
                        color: accentGold.withValues(alpha: 0.4),
                        width: 1.5.w,
                      ),
                    ),
                    child: Icon(
                      Icons.auto_awesome_outlined,
                      color: accentGold,
                      size: 20.sp,
                    ),
                  ),
                  SizedBox(width: 14.w),


                  Expanded(
                    child: Row(
                      children: [
                        Text(
                          'خطة اتمام المصحف ',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10.sp,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'Cairo',
                          ),
                        ),
                        SizedBox(width: 8.w),
                        // Floating Gold Badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: 6.w,
                            vertical: 2.h,
                          ),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [accentGold, Color(0xFFC5953C)],
                            ),
                            borderRadius: BorderRadius.circular(6.r),
                          ),
                          child: Text(
                            'جديد',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8.sp,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  SizedBox(width: 10.w),
                  const Icon(Icons.chevron_left, color: Colors.white70),


                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SurahTile extends StatelessWidget {
  const _SurahTile({required this.surah, required this.onTap});

  final QuranSurah surah;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.r),
          child: Container(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.14),
              ),
              boxShadow: [
                BoxShadow(
                  color: theme.shadowColor.withValues(alpha: 0.05),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              children: [
                _SurahNumber(number: surah.number),
                SizedBox(width: 14.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        surah.nameArabic,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'Amiri',
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        '${surah.revelationPlace} • ${surah.versesCount} آية • ${surah.transliteration}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontSize: 10.sp,
                          fontFamily: 'Cairo',
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_left, color: colorScheme.primary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SurahNumber extends StatelessWidget {
  const _SurahNumber({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 42.w,
      height: 42.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primary.withValues(alpha: 0.1),
        border: Border.all(color: colorScheme.primary.withValues(alpha: 0.45)),
      ),
      child: Text(
        '$number',
        style: TextStyle(
          color: colorScheme.primary,
          fontWeight: FontWeight.w800,
          fontSize: 14.sp,
          fontFamily: 'Cairo',
        ),
      ),
    );
  }
}
