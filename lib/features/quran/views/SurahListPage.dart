import 'package:flutter_screenutil/flutter_screenutil.dart';
// ================== صفحة قائمة السور (ثابتة) ==================
import 'package:flutter/material.dart';
import 'package:huda/core/widgets/appbars/huda_app_bar.dart';

class Surah {
  final int id;
  final String nameArabic;
  final String nameEnglish;
  final int versesCount;

  Surah({
    required this.id,
    required this.nameArabic,
    required this.nameEnglish,
    required this.versesCount,
  });
}

class SurahListPage extends StatefulWidget {
  const SurahListPage({super.key});

  @override
  State<SurahListPage> createState() => _SurahListPageState();
}

class _SurahListPageState extends State<SurahListPage> {
  late List<Surah> allSurahs;
  List<Surah> filteredSurahs = [];
  TextEditingController searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    allSurahs = _generateSurahsList();
    filteredSurahs = allSurahs;
    searchController.addListener(_filterSurahs);
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  void _filterSurahs() {
    String query = searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        filteredSurahs = allSurahs;
      } else {
        filteredSurahs = allSurahs.where((surah) {
          return surah.nameArabic.contains(query) ||
              surah.nameEnglish.toLowerCase().contains(query) ||
              surah.id.toString().contains(query);
        }).toList();
      }
    });
  }

  // قائمة أول 20 سورة (يمكنك إكمال الباقي حتى 114)
  List<Surah> _generateSurahsList() {
    return [
      Surah(
        id: 1,
        nameArabic: 'الفاتحة',
        nameEnglish: 'Al-Fatihah',
        versesCount: 7,
      ),
      Surah(
        id: 2,
        nameArabic: 'البقرة',
        nameEnglish: 'Al-Baqarah',
        versesCount: 286,
      ),
      Surah(
        id: 3,
        nameArabic: 'آل عمران',
        nameEnglish: "Aal-e-Imran",
        versesCount: 200,
      ),
      Surah(
        id: 4,
        nameArabic: 'النساء',
        nameEnglish: "An-Nisa'",
        versesCount: 176,
      ),
      Surah(
        id: 5,
        nameArabic: 'المائدة',
        nameEnglish: "Al-Ma'idah",
        versesCount: 120,
      ),
      Surah(
        id: 6,
        nameArabic: 'الأنعام',
        nameEnglish: "Al-An'am",
        versesCount: 165,
      ),
      Surah(
        id: 7,
        nameArabic: 'الأعراف',
        nameEnglish: "Al-A'raf",
        versesCount: 206,
      ),
      Surah(
        id: 8,
        nameArabic: 'الأنفال',
        nameEnglish: "Al-Anfal",
        versesCount: 75,
      ),
      Surah(
        id: 9,
        nameArabic: 'التوبة',
        nameEnglish: "At-Tawbah",
        versesCount: 129,
      ),
      Surah(id: 10, nameArabic: 'يونس', nameEnglish: "Yunus", versesCount: 109),
      Surah(id: 11, nameArabic: 'هود', nameEnglish: "Hud", versesCount: 123),
      Surah(id: 12, nameArabic: 'يوسف', nameEnglish: "Yusuf", versesCount: 111),
      Surah(
        id: 13,
        nameArabic: 'الرعد',
        nameEnglish: "Ar-Ra'd",
        versesCount: 43,
      ),
      Surah(
        id: 14,
        nameArabic: 'إبراهيم',
        nameEnglish: "Ibrahim",
        versesCount: 52,
      ),
      Surah(
        id: 15,
        nameArabic: 'الحجر',
        nameEnglish: "Al-Hijr",
        versesCount: 99,
      ),
      Surah(
        id: 16,
        nameArabic: 'النحل',
        nameEnglish: "An-Nahl",
        versesCount: 128,
      ),
      Surah(
        id: 17,
        nameArabic: 'الإسراء',
        nameEnglish: "Al-Isra",
        versesCount: 111,
      ),
      Surah(
        id: 18,
        nameArabic: 'الكهف',
        nameEnglish: "Al-Kahf",
        versesCount: 110,
      ),
      Surah(id: 19, nameArabic: 'مريم', nameEnglish: "Maryam", versesCount: 98),
      Surah(id: 20, nameArabic: 'طه', nameEnglish: "Taha", versesCount: 135),
      // أضف باقي السور حسب الحاجة
    ];
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: HudaAppBar(
        titleText: 'قائمة السور',
        showSearch: true,
        searchController: searchController,
        searchHint: 'ابحث عن سورة...',
        centerTitle: true,
        elevation: 0,
      ),

      body: filteredSurahs.isEmpty
          ? Center(
              child: Text(
                'لا توجد نتائج',
                style: TextStyle(fontSize: 18.sp, color: Colors.grey),
              ),
            )
          : ListView.builder(
              padding: EdgeInsets.all(16.w),
              itemCount: filteredSurahs.length,
              itemBuilder: (context, index) {
                final surah = filteredSurahs[index];
                return GestureDetector(
                  onTap: () {
                    // سيتم ربطها لاحقاً من قبلك
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('تم اختيار سورة ${surah.nameArabic}'),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20.r),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20.w,
                        vertical: 8.h,
                      ),
                      leading: CircleAvatar(
                        backgroundColor: const Color(
                          0xFF1A6B58,
                        ).withOpacity(0.1),
                        child: Text(
                          '${surah.id}',
                          style: TextStyle(
                            color: Color(0xFF1A6B58),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(
                        surah.nameArabic,
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1E2A32),
                        ),
                      ),
                      subtitle: Text(
                        '${surah.nameEnglish} • ${surah.versesCount} آية',
                        style: TextStyle(fontSize: 13.sp, color: Colors.grey),
                      ),
                      trailing: Icon(
                        Icons.chevron_left,
                        color: Color(0xFF1A6B58),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
