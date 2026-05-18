import 'package:flutter/material.dart';
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
        extraData: {
          'surah_number': widget.surah.number,
        },
      );
    } catch (_) {}
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
  });

  final QuranSurah surah;
  final List<QuranAyah> ayahs;
  final bool isFirstPage;
  final int pageNumber;
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
              Container(
                width: 400.w,
                height: 650.h,
                child: Padding(
                  padding: EdgeInsets.only(
                    top: 60.h,
                    right: 30.w,
                    left: 30.w,
                    bottom: 18.h,
                  ),
                  child: Expanded(
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
      spans.add(TextSpan(text: '${ayah.text} '));
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: AyahNumber(number: ayah.verse),
        ),
      );
      spans.add(const TextSpan(text: ' '));
    }
    return spans;
  }
}
