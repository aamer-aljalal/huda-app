import 'dart:convert';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/features/quran/services/quran_service.dart';
import 'package:huda/features/quran/widgets/ayah_footer.dart';
import 'package:huda/features/quran/widgets/ayah_number.dart';
import 'package:huda/features/quran/widgets/ayah_top_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:huda/core/services/recent_actions_service.dart';

class SurahDetailPage extends StatefulWidget {
  const SurahDetailPage({super.key, required this.surah, required this.ayahs});

  final QuranSurah surah;
  final List<QuranAyah> ayahs;

  @override
  State<SurahDetailPage> createState() => _SurahDetailPageState();
}

class _SurahDetailPageState extends State<SurahDetailPage> {
  static const String _savedAyahsKey = 'saved_quran_ayahs';

  late final PageController _pageController;
  late final List<List<QuranAyah>> _pages;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pages = _splitIntoMushafPages(widget.ayahs);
    _pageController = PageController();
    _loadSavedPage();
  }

  Future<void> _loadSavedPage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedPage = prefs.getInt('quran_page_${widget.surah.number}') ?? 0;
      if (savedPage > 0 && savedPage < _pages.length) {
        setState(() {
          _currentPage = savedPage;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(savedPage);
          }
        });
      }
    } catch (_) {}

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveRecentQuranAction();
    });
  }

  Future<void> _saveRecentQuranAction() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('quran_page_${widget.surah.number}', _currentPage);
      await RecentActionsManager.addAction(
        category: 'quran',
        title: 'سورة ${widget.surah.nameArabic}',
        subtitle: 'صفحة ${_currentPage + 1}',
        extraData: {'surah_number': widget.surah.number},
      );
    } catch (_) {}
  }

  Future<void> _showAyahActions(QuranAyah ayah) async {
    final interpretation = await QuranService.loadInterpretation(
      surahNumber: ayah.chapter,
      ayahNumber: ayah.verse,
    );

    if (!mounted) return;
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: _AyahActionsSheet(
            surah: widget.surah,
            ayah: ayah,
            interpretation: interpretation,
            onCopy: () => _copyAyah(ayah),
            onSave: () => _saveAyah(ayah, interpretation),
            onInterpretation: () => _showInterpretation(ayah, interpretation),
          ),
        );
      },
    );
  }

  Future<void> _copyAyah(QuranAyah ayah) async {
    await Clipboard.setData(
      ClipboardData(
        text:
            'سورة ${widget.surah.nameArabic} - الآية ${ayah.verse}\n\n${ayah.text}',
      ),
    );

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم نسخ الآية')));
  }

  Future<void> _saveAyah(QuranAyah ayah, String interpretation) async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getStringList(_savedAyahsKey) ?? [];
    final key = '${ayah.chapter}:${ayah.verse}';

    final alreadySaved = saved.any((item) {
      final decoded = jsonDecode(item) as Map<String, dynamic>;
      return decoded['key'] == key;
    });

    if (!alreadySaved) {
      saved.add(
        jsonEncode({
          'key': key,
          'surahNumber': ayah.chapter,
          'surahName': widget.surah.nameArabic,
          'ayahNumber': ayah.verse,
          'ayahText': ayah.text,
          'interpretation': interpretation,
          'savedAt': DateTime.now().toIso8601String(),
        }),
      );
      await prefs.setStringList(_savedAyahsKey, saved);
    }

    if (!mounted) return;
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(alreadySaved ? 'الآية محفوظة سابقاً' : 'تم حفظ الآية'),
      ),
    );
  }

  void _showInterpretation(QuranAyah ayah, String interpretation) {
    Navigator.pop(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: _InterpretationSheet(
            surahName: widget.surah.nameArabic,
            ayah: ayah,
            interpretation: interpretation,
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
        backgroundColor: const Color.fromARGB(255, 255, 255, 255),
        body: SafeArea(
          child: Column(
            children: [
              MushafTopBar(
                surah: widget.surah,
                currentPage: _currentPage + 1,
                pagesCount: _pages.length,
              ),

              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  reverse: true,
                  itemCount: _pages.length,
                  onPageChanged: (page) {
                    setState(() => _currentPage = page);
                    _saveRecentQuranAction();
                  },

                  itemBuilder: (context, index) {
                    return _MushafPage(
                      surah: widget.surah,
                      ayahs: _pages[index],
                      isFirstPage: index == 0,
                      pageNumber: index + 1,
                      onAyahLongPress: _showAyahActions,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MushafPage extends StatelessWidget {
  const _MushafPage({
    required this.surah,
    required this.ayahs,
    required this.isFirstPage,
    required this.pageNumber,
    required this.onAyahLongPress,
  });

  final QuranSurah surah;
  final List<QuranAyah> ayahs;
  final bool isFirstPage;
  final int pageNumber;
  final ValueChanged<QuranAyah> onAyahLongPress;
  bool get _showBasmala =>
      isFirstPage && surah.number != 1 && surah.number != 9;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context);

    return Container(
      decoration: BoxDecoration(
        // الخَلفية الجديدة لصورة السورة
        image: const DecorationImage(
          image: AssetImage('assets/img/surah_detail_green.png'),
          fit: BoxFit.fill,
          // fit: BoxFit.cover,
        ),
      ),
      child: Stack(
        children: [
          Column(
            children: [
              SizedBox(
                width: 400.w,
                height: 650.h,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: 60.h,
                    right: 30.w,
                    left: 30.w,
                    bottom: 18.h,
                  ),
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Column(
                      // mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (isFirstPage) ...[
                          if (_showBasmala) ...[
                            // SizedBox(height: 12.h),
                            Padding(
                              padding: const EdgeInsets.only(top: 10),
                              child: Text(
                                'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: const Color(0xFF1E1A12),
                                  fontSize: textScale.scale(15.sp),
                                  fontWeight: FontWeight.w700,
                                  height: 0.5.h,
                                ),
                              ),
                            ),
                          ],
                          SizedBox(height: 10.h),
                        ],
                        RichText(
                          textDirection: TextDirection.rtl,
                          textAlign: TextAlign.justify,
                          text: TextSpan(
                            style: TextStyle(
                              color: const Color(0xFF1A1710),
                              fontSize: textScale.scale(18.sp),
                              height: 2.05,
                              fontWeight: FontWeight.w500,
                            ),
                            children: _buildAyahSpans(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              AyahFooter(pageNumber: pageNumber),
            ],
          ),
        ],
      ),
    );
  }

  List<InlineSpan> _buildAyahSpans(BuildContext context) {
    final spans = <InlineSpan>[];
    for (final ayah in ayahs) {
      spans.add(
        TextSpan(
          text: '${ayah.text} ',
          recognizer: LongPressGestureRecognizer(
            duration: const Duration(milliseconds: 500),
          )..onLongPress = () => onAyahLongPress(ayah),
        ),
      );
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GestureDetector(
            onLongPress: () => onAyahLongPress(ayah),
            child: AyahNumber(number: ayah.verse),
          ),
        ),
      );
      spans.add(const TextSpan(text: ' '));
    }
    return spans;
  }
}

class _AyahActionsSheet extends StatelessWidget {
  const _AyahActionsSheet({
    required this.surah,
    required this.ayah,
    required this.interpretation,
    required this.onInterpretation,
    required this.onCopy,
    required this.onSave,
  });

  final QuranSurah surah;
  final QuranAyah ayah;
  final String interpretation;
  final VoidCallback onInterpretation;
  final VoidCallback onCopy;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 22.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 44.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.18),
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
          ),
          SizedBox(height: 14.h),
          Text(
            'سورة ${surah.nameArabic} - الآية ${ayah.verse}',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1A6B58),
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            ayah.text,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16.sp,
              height: 1.7,
              color: const Color(0xFF1A1710),
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            children: [
              Expanded(
                child: _SheetActionButton(
                  icon: Icons.menu_book_outlined,
                  label: 'تفسير الآية',
                  onTap: onInterpretation,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _SheetActionButton(
                  icon: Icons.copy,
                  label: 'نسخ الآية',
                  onTap: onCopy,
                ),
              ),
              SizedBox(width: 8.w),
              Expanded(
                child: _SheetActionButton(
                  icon: Icons.bookmark_add_outlined,
                  label: 'حفظ الآية',
                  onTap: onSave,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SheetActionButton extends StatelessWidget {
  const _SheetActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 6.w),
        decoration: BoxDecoration(
          color: const Color(0xFF1A6B58).withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8.r),
          border: Border.all(
            color: const Color(0xFF1A6B58).withValues(alpha: 0.16),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: const Color(0xFF1A6B58), size: 22.sp),
            SizedBox(height: 5.h),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: const Color(0xFF1A6B58),
                fontSize: 11.sp,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InterpretationSheet extends StatelessWidget {
  const _InterpretationSheet({
    required this.surahName,
    required this.ayah,
    required this.interpretation,
  });

  final String surahName;
  final QuranAyah ayah;
  final String interpretation;

  @override
  Widget build(BuildContext context) {
    final hasInterpretation = interpretation.trim().isNotEmpty;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.9,
      builder: (context, controller) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
          ),
          child: ListView(
            controller: controller,
            padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 26.h),
            children: [
              Center(
                child: Container(
                  width: 44.w,
                  height: 4.h,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'تفسير سورة $surahName - الآية ${ayah.verse}',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFF1A6B58),
                ),
              ),
              SizedBox(height: 12.h),
              Text(
                hasInterpretation
                    ? interpretation
                    : 'لا يوجد تفسير متاح لهذه الآية في الملف الحالي.',
                style: TextStyle(
                  fontSize: 16.sp,
                  height: 1.8,
                  color: const Color(0xFF1A1710),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
