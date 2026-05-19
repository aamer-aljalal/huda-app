import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:huda/core/theme/app_colors.dart';
import 'package:huda/core/widgets/appbars/huda_app_bar.dart';
import 'package:huda/features/quran/services/quran_service.dart';
import 'package:huda/features/quran/views/surah_detail_page.dart';
import 'package:huda/features/Hadith/hadith_service.dart';

class BookmarksPage extends StatefulWidget {
  const BookmarksPage({super.key});

  @override
  State<BookmarksPage> createState() => _BookmarksPageState();
}

class _BookmarksPageState extends State<BookmarksPage> with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  
  List<Map<String, dynamic>> _savedAyahs = [];
  List<HadithModel> _savedHadiths = [];
  List<Map<String, dynamic>> _savedAzkar = [];
  
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadSavedItems();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedItems() async {
    setState(() => _isLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      
      // Load Verses
      final savedAyahsRaw = prefs.getStringList('saved_quran_ayahs') ?? [];
      _savedAyahs = savedAyahsRaw.map((item) {
        return jsonDecode(item) as Map<String, dynamic>;
      }).toList();
      _savedAyahs.sort((a, b) {
        final aTime = DateTime.tryParse(a['savedAt'] ?? '') ?? DateTime.now();
        final bTime = DateTime.tryParse(b['savedAt'] ?? '') ?? DateTime.now();
        return bTime.compareTo(aTime);
      });

      // Load Hadiths from 'favorite_hadith_numbers'
      final favoriteHadithNumbers = prefs.getStringList('favorite_hadith_numbers') ?? [];
      final allHadiths = await HadithService.loadHadiths();
      _savedHadiths = allHadiths.where((hadith) {
        return favoriteHadithNumbers.contains(hadith.number.toString());
      }).toList();

      // Load Azkar (for future use/save capability)
      final savedAzkarRaw = prefs.getStringList('saved_azkar') ?? [];
      _savedAzkar = savedAzkarRaw.map((item) {
        return jsonDecode(item) as Map<String, dynamic>;
      }).toList();

    } catch (_) {}
    setState(() => _isLoading = false);
  }

  Future<void> _deleteAyah(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedList = prefs.getStringList('saved_quran_ayahs') ?? [];
      savedList.removeWhere((item) {
        final decoded = jsonDecode(item) as Map<String, dynamic>;
        return decoded['key'] == key;
      });
      await prefs.setStringList('saved_quran_ayahs', savedList);
      
      HapticFeedback.mediumImpact();
      _loadSavedItems();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الآية من المحفوظات')),
        );
      }
    } catch (_) {}
  }

  Future<void> _deleteHadith(int number) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final favoriteHadithNumbers = prefs.getStringList('favorite_hadith_numbers') ?? [];
      favoriteHadithNumbers.remove(number.toString());
      await prefs.setStringList('favorite_hadith_numbers', favoriteHadithNumbers);
      
      HapticFeedback.mediumImpact();
      _loadSavedItems();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تم حذف الحديث من المفضلة')),
        );
      }
    } catch (_) {}
  }

  Future<void> _goToAyah(int surahNumber, int verseNumber) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    try {
      final surahs = await QuranService.loadSurahs();
      final surah = surahs.firstWhere((s) => s.number == surahNumber);
      final ayahs = await QuranService.loadAyahs(surahNumber);
      
      // Calculate containing page index using the same page splitting logic
      final pages = _splitIntoMushafPages(ayahs);
      int targetPageIndex = 0;
      for (int i = 0; i < pages.length; i++) {
        if (pages[i].any((a) => a.verse == verseNumber)) {
          targetPageIndex = i;
          break;
        }
      }

      // Save page index so SurahDetailPage opens exactly on it
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('quran_page_$surahNumber', targetPageIndex);

      if (!mounted) return;
      Navigator.pop(context); // Pop loading dialog
      
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SurahDetailPage(
            surah: surah,
            ayahs: ayahs,
            initialPage: targetPageIndex,
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        Navigator.pop(context); // Pop loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('تعذر الانتقال إلى الآية')),
        );
      }
    }
  }

  List<List<QuranAyah>> _splitIntoMushafPages(List<QuranAyah> ayahs) {
    final pages = <List<QuranAyah>>[];
    var current = <QuranAyah>[];
    var currentLength = 0;

    for (final ayah in ayahs) {
      final nextLength = currentLength + ayah.text.length;
      final maxLength = current.isEmpty ? 980 : 920;

      if (current.isNotEmpty && nextLength > maxLength) {
        pages.add(current);
        current = <QuranAyah>[];
        currentLength = 0;
      }

      current.add(ayah);
      currentLength += ayah.text.length;
    }

    if (current.isNotEmpty) pages.add(current);
    return pages;
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: HudaAppBar(
          titleText: 'المحفوظات',
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: AppColors.goldAccent,
            indicatorWeight: 3.h,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontSize: 14.sp, fontWeight: FontWeight.bold),
            tabs: const [
              Tab(text: 'الآيات'),
              Tab(text: 'الأحاديث'),
              Tab(text: 'الأذكار'),
            ],
          ),
        ),
        body: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : TabBarView(
                controller: _tabController,
                children: [
                  _buildAyahsTab(),
                  _buildHadithsTab(),
                  _buildAzkarTab(),
                ],
              ),
      ),
    );
  }

  Widget _buildAyahsTab() {
    if (_savedAyahs.isEmpty) {
      return _buildEmptyState(
        icon: Icons.menu_book_rounded,
        title: 'لا توجد آيات محفوظة حالياً',
        subtitle: 'يمكنك حفظ أي آية أثناء قراءتك للقرآن بالضغط المطول عليها واختيار حفظ.',
        buttonText: 'تصفح المصحف الشريف',
        onTap: () {
          Navigator.pushNamed(context, '/quran');
        },
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      itemCount: _savedAyahs.length,
      itemBuilder: (context, index) {
        final item = _savedAyahs[index];
        final key = item['key'] as String;
        final surahName = item['surahName'] as String? ?? '';
        final surahNumber = item['surahNumber'] as int? ?? 1;
        final ayahNumber = item['ayahNumber'] as int? ?? 1;
        final ayahText = item['ayahText'] as String? ?? '';
        final interpretation = item['interpretation'] as String? ?? '';

        return Container(
          margin: EdgeInsets.only(bottom: 16.h),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header of Card
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'سورة $surahName - آية $ayahNumber',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.open_in_new_rounded, size: 18.sp, color: AppColors.primary),
                          tooltip: 'الذهاب للآية',
                          onPressed: () => _goToAyah(surahNumber, ayahNumber),
                        ),
                        IconButton(
                          icon: Icon(Icons.copy_rounded, size: 18.sp, color: AppColors.primary),
                          tooltip: 'نسخ الآية',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: '$ayahText ($surahName:$ayahNumber)'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم نسخ الآية')),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline_rounded, size: 18.sp, color: Colors.red.shade700),
                          tooltip: 'حذف الآية',
                          onPressed: () => _deleteAyah(key),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Body of Card
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      ayahText,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.justify,
                      style: TextStyle(
                        fontSize: 17.sp,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        height: 1.8,
                      ),
                    ),
                    if (interpretation.isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      Divider(color: Colors.grey.withValues(alpha: 0.15)),
                      SizedBox(height: 8.h),
                      Text(
                        'التفسير:',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: AppColors.goldAccent,
                        ),
                      ),
                      SizedBox(height: 4.h),
                      Text(
                        interpretation,
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          fontSize: 13.sp,
                          color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.8),
                          height: 1.6,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHadithsTab() {
    if (_savedHadiths.isEmpty) {
      return _buildEmptyState(
        icon: Icons.menu_book_outlined,
        title: 'لا توجد أحاديث محفوظة حالياً',
        subtitle: 'يمكنك حفظ الأحاديث التي ترغب بالرجوع إليها لاحقاً بالضغط على النجمة في صفحة الأحاديث.',
        buttonText: 'تصفح الأربعين النووية 📖',
        onTap: () {
          Navigator.pushNamed(context, '/hadith');
        },
      );
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
      itemCount: _savedHadiths.length,
      itemBuilder: (context, index) {
        final hadith = _savedHadiths[index];

        return Container(
          margin: EdgeInsets.only(bottom: 16.h),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            borderRadius: BorderRadius.circular(12.r),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.1),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header of Card
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.05),
                  borderRadius: BorderRadius.vertical(top: Radius.circular(12.r)),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      hadith.shortTitle,
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                        fontFamily: 'Cairo',
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(Icons.copy_rounded, size: 18.sp, color: AppColors.primary),
                          tooltip: 'نسخ الحديث',
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: '${hadith.hadith}\n\n[الأربعون النووية - ${hadith.shortTitle}]'));
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('تم نسخ الحديث الشريف بنجاح')),
                            );
                          },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline_rounded, size: 18.sp, color: Colors.red.shade700),
                          tooltip: 'حذف الحديث',
                          onPressed: () => _deleteHadith(hadith.number),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Body of Card
              Padding(
                padding: EdgeInsets.all(16.w),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      hadith.textOnly,
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.justify,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w500,
                        color: Theme.of(context).textTheme.bodyLarge?.color,
                        height: 1.8,
                        fontFamily: 'Amiri',
                      ),
                    ),
                    if (hadith.description.isNotEmpty) ...[
                      SizedBox(height: 12.h),
                      Divider(color: Colors.grey.withValues(alpha: 0.15)),
                      SizedBox(height: 8.h),
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'الشرح والفوائد:',
                              style: TextStyle(
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                color: AppColors.goldAccent,
                                fontFamily: 'Cairo',
                              ),
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              hadith.description,
                              textAlign: TextAlign.justify,
                              style: TextStyle(
                                fontSize: 12.sp,
                                color: Theme.of(context).textTheme.bodyMedium?.color?.withValues(alpha: 0.9),
                                height: 1.6,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAzkarTab() {
    if (_savedAzkar.isEmpty) {
      return _buildEmptyState(
        icon: Icons.bookmark_added_outlined,
        title: 'لا توجد أذكار محفوظة حالياً',
        subtitle: 'يمكنك حفظ الأذكار اليومية لتصل إليها بسرعة وسهولة.',
        buttonText: 'تصفح الأذكار والأوراد',
        onTap: () {
          Navigator.pushNamed(context, '/azkar-categories');
        },
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Center(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 48.sp,
                color: AppColors.primary,
              ),
            ),
            SizedBox(height: 24.h),
            Text(
              title,
              style: TextStyle(
                fontSize: 16.sp,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge?.color,
              ),
            ),
            SizedBox(height: 12.h),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13.sp,
                color: Colors.grey.shade600,
                height: 1.6,
              ),
            ),
            SizedBox(height: 32.h),
            ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.r),
                ),
                elevation: 0,
              ),
              child: Text(
                buttonText,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
