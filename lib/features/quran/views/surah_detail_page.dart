import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/features/quran/controllers/quran_reading_controller.dart';
import 'package:tarteel/features/quran/services/quran_service.dart';
import 'package:tarteel/features/quran/widgets/ayah_top_bar.dart';
import 'package:tarteel/features/quran/widgets/ayah_actions_sheet.dart';
import 'package:tarteel/features/quran/widgets/ayah_interpretation_sheet.dart';
import 'package:tarteel/features/quran/widgets/mushaf_page.dart';
import 'package:tarteel/features/quran/widgets/reading_modes/quran_continuous_scroll_view.dart';
import 'package:tarteel/features/quran/widgets/reading_modes/quran_page_view.dart';
import 'package:tarteel/core/services/in_app_notification_service.dart';

class SurahDetailPage extends StatefulWidget {
  const SurahDetailPage({
    super.key,
    required this.surah,
    required this.ayahs,
    this.initialPage = 0,
    this.initialAyah,
    this.isKhatmaSession = false,
  });

  final QuranSurah surah;
  final List<QuranAyah> ayahs;
  final int initialPage;
  final int? initialAyah;
  final bool isKhatmaSession;

  @override
  State<SurahDetailPage> createState() => _SurahDetailPageState();
}

class _SurahDetailPageState extends State<SurahDetailPage> {
  late final List<List<QuranAyah>> _continuousPages;
  List<List<QuranAyah>> _paginatedPages = [];
  late List<List<QuranAyah>> _pages;
  late List<GlobalKey> _pageKeys;
  late final GlobalKey _centerSliverKey;
  int _currentPage = 0;
  int _centerPage = 0;
  final bool _isLoading = false;
  List<QuranSurah> _allSurahs = [];
  final ValueNotifier<QuranAyah?> _pressedAyahNotifier = ValueNotifier(null);

  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();
  bool _isPageView = false;
  double _initialScrollOffset = 0.0;
  bool _hasBookmarkedInThisSession = false;
  final GlobalKey _initialAyahKey = GlobalKey();
  late final Map<int, GlobalKey> _ayahKeys;

  @override
  void initState() {
    super.initState();
    _continuousPages = [widget.ayahs];
    _paginatedPages = QuranReadingController.splitIntoPages(widget.ayahs);
    _pages = _continuousPages;
    _pageKeys = List.generate(_pages.length, (_) => GlobalKey());
    _centerSliverKey = GlobalKey();

    _ayahKeys = {for (var a in widget.ayahs) a.verse: GlobalKey()};
    if (widget.initialAyah != null &&
        _ayahKeys.containsKey(widget.initialAyah)) {
      _ayahKeys[widget.initialAyah!] = _initialAyahKey;
    }

    int startPage = widget.initialPage;
    if (widget.initialAyah != null) {
      for (int i = 0; i < _pages.length; i++) {
        if (_pages[i].any((a) => a.verse == widget.initialAyah)) {
          startPage = i;
          break;
        }
      }
    }

    _centerPage = startPage;
    if (_centerPage >= _pages.length) _centerPage = 0;
    _currentPage = _centerPage;

    _loadAllSurahs();
    _loadReadingModePreference();

    if (widget.surah.number == 18) {
      InAppNotificationService.markCompleted('surah_kahf');
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initialScrollOffset = _scrollController.hasClients
          ? _scrollController.position.pixels
          : 0.0;
      _saveRecentQuranAction();

      // Scroll to target initial Ayah if present
      if (widget.initialAyah != null &&
          _initialAyahKey.currentContext != null) {
        Scrollable.ensureVisible(
          _initialAyahKey.currentContext!,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          alignment: 0.1, // Near top
        );
      }
    });
  }

  Future<void> _loadReadingModePreference() async {
    final mode = await QuranReadingController.getReadingMode();
    if (mounted) {
      setState(() {
        _isPageView = mode == 'page';
        _pages = _isPageView ? _paginatedPages : _continuousPages;
        _pageKeys = List.generate(_pages.length, (_) => GlobalKey());
      });
    }
  }

  void _toggleReadingMode() {
    setState(() {
      _isPageView = !_isPageView;
      _pages = _isPageView ? _paginatedPages : _continuousPages;
      _pageKeys = List.generate(_pages.length, (_) => GlobalKey());
    });
    QuranReadingController.setReadingMode(_isPageView ? 'page' : 'list');
  }

  Future<void> _loadAllSurahs() async {
    try {
      final surahs = await QuranService.loadSurahs();
      if (mounted) {
        setState(() {
          _allSurahs = surahs;
        });
      }
    } catch (_) {}
  }

  Future<void> _saveRecentQuranAction() async {
    await QuranReadingController.saveRecentAction(
      surah: widget.surah,
      currentPage: _currentPage,
      initialAyah: widget.initialAyah,
      isKhatmaSession: widget.isKhatmaSession,
    );
  }

  void _saveCurrentVisibleAyah() {
    QuranReadingController.saveTopVisibleAyah(
      surah: widget.surah,
      ayahs: widget.ayahs,
      ayahKeys: _ayahKeys,
      isKhatmaSession: widget.isKhatmaSession,
    );
  }

  Future<void> _showAyahActions(QuranAyah ayah) async {
    _pressedAyahNotifier.value = ayah;
    final interpretation = await QuranService.loadInterpretation(
      surahNumber: ayah.chapter,
      ayahNumber: ayah.verse,
    );

    if (!mounted) {
      _pressedAyahNotifier.value = null;
      return;
    }
    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: AyahActionsSheet(
            surah: widget.surah,
            ayah: ayah,
            interpretation: interpretation,
            isKhatmaSession: widget.isKhatmaSession,
            onCopy: () => QuranReadingController.copyAyah(
              context: context,
              surah: widget.surah,
              ayah: ayah,
            ),
            onSave: () => QuranReadingController.saveAyahToFavorites(
              context: context,
              surah: widget.surah,
              ayah: ayah,
              interpretation: interpretation,
            ),
            onInterpretation: () => _showInterpretation(ayah, interpretation),
            onUpdateKhatma: widget.isKhatmaSession
                ? () async {
                    final success =
                        await QuranReadingController.updateKhatmaBookmark(
                          context: context,
                          ayah: ayah,
                        );
                    if (success && mounted) {
                      setState(() {
                        _hasBookmarkedInThisSession = true;
                        _initialScrollOffset =
                            _scrollController.position.pixels;
                      });
                    }
                  }
                : null,
          ),
        );
      },
    );
    _pressedAyahNotifier.value = null;
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
          child: AyahInterpretationSheet(
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
    _pressedAyahNotifier.dispose();
    _scrollController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  Widget _buildPageSliver(int index) {
    return MushafPage(
      key: _pageKeys[index],
      surah: widget.surah,
      ayahs: _pages[index],
      isFirstPage: index == 0,
      isLastPage: index == _pages.length - 1,
      pageNumber: index + 1,
      onAyahLongPress: _showAyahActions,
      nextSurah: _nextSurah,
      prevSurah: _prevSurah,
      onNavigate: _navigateToSurah,
      pressedAyahNotifier: _pressedAyahNotifier,
      initialAyah: widget.initialAyah,
      initialAyahKey: _initialAyahKey,
      ayahKeys: _ayahKeys,
    );
  }

  QuranSurah? get _nextSurah {
    if (_allSurahs.isEmpty) return null;
    final nextNumber = widget.surah.number + 1;
    if (nextNumber > 114) return null;
    return _allSurahs.firstWhere((s) => s.number == nextNumber);
  }

  QuranSurah? get _prevSurah {
    if (_allSurahs.isEmpty) return null;
    final prevNumber = widget.surah.number - 1;
    if (prevNumber < 1) return null;
    return _allSurahs.firstWhere((s) => s.number == prevNumber);
  }

  Future<void> _navigateToSurah(int surahNumber) async {
    try {
      final surahs = await QuranService.loadSurahs();
      final targetSurah = surahs.firstWhere((s) => s.number == surahNumber);
      final ayahs = await QuranService.loadAyahs(surahNumber);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (context) => SurahDetailPage(
            surah: targetSurah,
            ayahs: ayahs,
            isKhatmaSession: widget.isKhatmaSession,
          ),
        ),
      );
    } catch (_) {}
  }

  Future<bool> _onWillPop() async {
    if (!widget.isKhatmaSession || _hasBookmarkedInThisSession) return true;

    if (_scrollController.hasClients) {
      final currentOffset = _scrollController.position.pixels;
      if (currentOffset - _initialScrollOffset > 500) {
        return await QuranReadingController.showKhatmaExitWarning(context);
      }
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && mounted) {
          Navigator.pop(context);
        }
      },
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color.fromARGB(255, 255, 255, 255),
          body: SafeArea(
            child: Column(
              children: [
                MushafTopBar(
                  surah: widget.surah,
                  isPageView: _isPageView,
                  onToggleReadingMode: _toggleReadingMode,
                ),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.only(top: 80.h, bottom: 40.h),
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/img/surah_detail_green.png'),
                        fit: BoxFit.fill,
                      ),
                    ),
                    child: Padding(
                      padding: EdgeInsets.only(right: 18.w, left: 18.w),
                      child: _isLoading
                          ? const Center(child: CircularProgressIndicator())
                          : _isPageView
                          ? QuranPageView(
                              pageController: _pageController,
                              totalPages: _pages.length,
                              buildPageSliver: _buildPageSliver,
                              onPageChanged: (index) {
                                setState(() {
                                  _currentPage = index;
                                });
                              },
                            )
                          : QuranContinuousScrollView(
                              scrollController: _scrollController,
                              centerSliverKey: _centerSliverKey,
                              centerPage: _centerPage,
                              totalPages: _pages.length,
                              buildPageSliver: _buildPageSliver,
                              onScrollEnd: _saveCurrentVisibleAyah,
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
