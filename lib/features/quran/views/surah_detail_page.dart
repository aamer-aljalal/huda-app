import 'dart:convert';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/features/quran/services/quran_service.dart';
import 'package:tarteel/features/quran/widgets/ayah_number.dart';
import 'package:tarteel/features/quran/widgets/ayah_top_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarteel/core/services/recent_actions_service.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/services/stats_service.dart';
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
  static const String _savedAyahsKey = 'saved_quran_ayahs';

  late final List<List<QuranAyah>> _pages;
  late final List<GlobalKey> _pageKeys;
  late final GlobalKey _centerSliverKey;
  int _currentPage = 0;
  int _centerPage = 0;
  final bool _isLoading = false;
  List<QuranSurah> _allSurahs = [];
  final ValueNotifier<QuranAyah?> _pressedAyahNotifier = ValueNotifier(null);

  final ScrollController _scrollController = ScrollController();
  double _initialScrollOffset = 0.0;
  bool _hasBookmarkedInThisSession = false;
  final GlobalKey _initialAyahKey = GlobalKey();
  late final Map<int, GlobalKey> _ayahKeys;

  @override
  void initState() {
    super.initState();
    _pages = _splitIntoMushafPages(widget.ayahs);
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
    if (widget.isKhatmaSession) return; // Khatma is tracked manually
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('quran_page_${widget.surah.number}', _currentPage);
      await prefs.setInt('quran_last_read_surah_number', widget.surah.number);

      final currentAyah = widget.initialAyah ?? 1;
      await prefs.setInt('quran_bookmark_surah', widget.surah.number);
      await prefs.setInt('quran_bookmark_ayah', currentAyah);
      await prefs.setInt('quran_ayah_${widget.surah.number}', currentAyah);

      await RecentActionsManager.addAction(
        category: 'quran',
        title: 'سورة ${widget.surah.nameArabic}',
        subtitle: widget.initialAyah != null
            ? 'الآية ${widget.initialAyah}'
            : 'قراءة السورة',
        extraData: {
          'surah_number': widget.surah.number,
          'ayah_number': currentAyah,
        },
      );
    } catch (_) {}
  }

  void _saveCurrentVisibleAyah() async {
    if (widget.isKhatmaSession) return; // Khatma is tracked manually
    try {
      int? topmostAyah;
      double minDiff = double.infinity;

      for (final ayah in widget.ayahs) {
        final key = _ayahKeys[ayah.verse];
        if (key == null) continue;
        final context = key.currentContext;
        if (context == null) continue;
        final box = context.findRenderObject() as RenderBox?;
        if (box == null || !box.hasSize) continue;

        final position = box.localToGlobal(Offset.zero);
        final y = position.dy;

        // We want the ayah closest to the top of the viewport
        if (y >= 80.h && y < minDiff) {
          minDiff = y;
          topmostAyah = ayah.verse;
        }
      }

      if (topmostAyah != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setInt('quran_bookmark_surah', widget.surah.number);
        await prefs.setInt('quran_bookmark_ayah', topmostAyah);
        await prefs.setInt('quran_last_read_surah_number', widget.surah.number);
        await prefs.setInt('quran_ayah_${widget.surah.number}', topmostAyah);

        await RecentActionsManager.addAction(
          category: 'quran',
          title: 'سورة ${widget.surah.nameArabic}',
          subtitle: 'الآية $topmostAyah',
          extraData: {
            'surah_number': widget.surah.number,
            'ayah_number': topmostAyah,
          },
        );
      }
    } catch (_) {}
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
          child: _AyahActionsSheet(
            surah: widget.surah,
            ayah: ayah,
            interpretation: interpretation,
            isKhatmaSession: widget.isKhatmaSession,
            onCopy: () => _copyAyah(ayah),
            onSave: () => _saveAyah(ayah, interpretation),
            onInterpretation: () => _showInterpretation(ayah, interpretation),
            onUpdateKhatma: widget.isKhatmaSession
                ? () => _updateKhatmaBookmark(ayah)
                : null,
          ),
        );
      },
    );
    _pressedAyahNotifier.value = null;
  }

  Future<void> _updateKhatmaBookmark(QuranAyah ayah) async {
    Navigator.pop(context); // close sheet

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('khatma_last_read_surah', ayah.chapter);
      await prefs.setInt('khatma_last_read_ayah', ayah.verse);

      // Update absolute progress
      final absoluteAyah = await QuranService.getAbsoluteAyahOffset(
        ayah.chapter,
        ayah.verse,
      );
      final prevMaxReached = prefs.getInt('khatma_max_reached_ayah') ?? 0;
      final previousTotalRead = prefs.getInt('khatma_ayahs_read') ?? 0;

      if (absoluteAyah > prevMaxReached) {
        final difference = absoluteAyah - prevMaxReached;
        await prefs.setInt('khatma_max_reached_ayah', absoluteAyah);

        final newTotalRead = (previousTotalRead + difference).clamp(0, 6236);
        await prefs.setInt('khatma_ayahs_read', newTotalRead);

        // Update today's read
        final now = DateTime.now();
        final todayStr = '${now.year}-${now.month}-${now.day}';
        var readToday = prefs.getInt('khatma_ayahs_read_today') ?? 0;
        final lastReadStr = prefs.getString('khatma_last_read_date');
        if (lastReadStr != null) {
          final lastReadDate = DateTime.parse(lastReadStr);
          final lastReadDayStr =
              '${lastReadDate.year}-${lastReadDate.month}-${lastReadDate.day}';
          if (todayStr != lastReadDayStr) {
            readToday = 0;
          }
        }

        final newReadToday = readToday + difference;
        await prefs.setInt('khatma_ayahs_read_today', newReadToday);
        await prefs.setString('khatma_last_read_date', now.toIso8601String());

        await StatsService.recordAction('quran', amount: difference);

        if (newTotalRead >= 6236) {
          await StatsService.incrementCompletedKhatmas();
        }
      }

      setState(() {
        _hasBookmarkedInThisSession = true;
        _initialScrollOffset =
            _scrollController.position.pixels; // Reset tracking offset
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديث موضع الختمة إلى آية ${ayah.verse} بنجاح'),
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('حدث خطأ أثناء حفظ موضع الختمة')),
      );
    }
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
    _pressedAyahNotifier.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Widget _buildPageSliver(int index) {
    return _MushafPage(
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

  List<List<QuranAyah>> _splitIntoMushafPages(List<QuranAyah> ayahs) {
    return [ayahs];
  }

  Future<bool> _onWillPop() async {
    if (!widget.isKhatmaSession || _hasBookmarkedInThisSession) return true;

    if (_scrollController.hasClients) {
      final currentOffset = _scrollController.position.pixels;
      if (currentOffset - _initialScrollOffset > 500) {
        final result = await showDialog<bool>(
          context: context,
          builder: (context) {
            final isDark = Theme.of(context).brightness == Brightness.dark;
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: isDark
                    ? const Color(0xFF1E1E1E)
                    : Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16.r),
                ),
                title: Text(
                  'تحديث الختمة',
                  style: TextStyle(
                    fontFamily: 'Cairo',
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
                content: Text(
                  'لقد تقدمت في القراءة دون تحديث موضع الختمة. هل تود الخروج دون تحديث الموضع؟',
                  style: TextStyle(fontFamily: 'Cairo', fontSize: 14.sp),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: Text(
                      'الخروج بدون تحديث',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                    ),
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text(
                      'العودة للتحديث',
                      style: TextStyle(
                        color: Colors.white,
                        fontFamily: 'Cairo',
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
        return result ?? false;
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
                MushafTopBar(surah: widget.surah),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.only(top: 65.h, bottom: 60.h),
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
                          : NotificationListener<ScrollNotification>(
                              onNotification: (notification) {
                                if (notification is ScrollEndNotification) {
                                  _saveCurrentVisibleAyah();
                                }
                                return false;
                              },
                              child: CustomScrollView(
                                controller: _scrollController,
                                center: _centerSliverKey,
                                physics: const BouncingScrollPhysics(),
                                slivers: [
                                  if (_centerPage > 0)
                                    SliverList(
                                      delegate: SliverChildBuilderDelegate((
                                        context,
                                        index,
                                      ) {
                                        final actualIndex =
                                            _centerPage - 1 - index;
                                        return _buildPageSliver(actualIndex);
                                      }, childCount: _centerPage),
                                    ),
                                  SliverList(
                                    key: _centerSliverKey,
                                    delegate: SliverChildBuilderDelegate((
                                      context,
                                      index,
                                    ) {
                                      final actualIndex = _centerPage + index;
                                      return _buildPageSliver(actualIndex);
                                    }, childCount: _pages.length - _centerPage),
                                  ),
                                ],
                              ),
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

class _MushafPage extends StatefulWidget {
  const _MushafPage({
    super.key,
    required this.surah,
    required this.ayahs,
    required this.isFirstPage,
    required this.isLastPage,
    required this.pageNumber,
    required this.onAyahLongPress,
    required this.nextSurah,
    required this.prevSurah,
    required this.onNavigate,
    required this.pressedAyahNotifier,
    required this.ayahKeys,
    this.initialAyah,
    this.initialAyahKey,
  });

  final QuranSurah surah;
  final List<QuranAyah> ayahs;
  final bool isFirstPage;
  final bool isLastPage;
  final int pageNumber;
  final ValueChanged<QuranAyah> onAyahLongPress;
  final QuranSurah? nextSurah;
  final QuranSurah? prevSurah;
  final ValueChanged<int> onNavigate;
  final ValueNotifier<QuranAyah?> pressedAyahNotifier;
  final Map<int, GlobalKey> ayahKeys;
  final int? initialAyah;
  final GlobalKey? initialAyahKey;

  @override
  State<_MushafPage> createState() => _MushafPageState();
}

class _MushafPageState extends State<_MushafPage> {
  bool get _showBasmala => widget.isFirstPage && widget.surah.number != 9;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context);

    return Container(
      width: double.infinity,
      color: Colors.transparent,
      padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Align(
            alignment: Alignment.topCenter,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (widget.isFirstPage) ...[
                  if (_showBasmala) ...[
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
                          fontFamily: 'Amiri',
                        ),
                      ),
                    ),
                  ],
                  SizedBox(height: 30.h),
                ],
                ValueListenableBuilder<QuranAyah?>(
                  valueListenable: widget.pressedAyahNotifier,
                  builder: (context, pressedAyah, child) {
                    return RichText(
                      textDirection: TextDirection.rtl,
                      textAlign: TextAlign.justify,
                      text: TextSpan(
                        style: TextStyle(
                          color: const Color(0xFF1A1710),
                          fontSize: textScale.scale(18.sp),
                          height: 2.05,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'Amiri',
                        ),
                        children: _buildAyahSpans(context, pressedAyah),
                      ),
                    );
                  },
                ),
                if (widget.isLastPage &&
                    (widget.prevSurah != null || widget.nextSurah != null)) ...[
                  SizedBox(height: 32.h),
                  Container(
                    width: 120.w,
                    height: 1.h,
                    color: const Color(0xFF1E1A12).withValues(alpha: 0.15),
                  ),
                  SizedBox(height: 24.h),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      if (widget.prevSurah != null)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6.w),
                            child: _NavigationCard(
                              title: 'السورة السابقة',
                              surahName: widget.prevSurah!.nameArabic,
                              isNext: false,
                              onTap: () =>
                                  widget.onNavigate(widget.prevSurah!.number),
                            ),
                          ),
                        ),
                      if (widget.nextSurah != null)
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(horizontal: 6.w),
                            child: _NavigationCard(
                              title: 'السورة التالية',
                              surahName: widget.nextSurah!.nameArabic,
                              isNext: true,
                              onTap: () =>
                                  widget.onNavigate(widget.nextSurah!.number),
                            ),
                          ),
                        ),
                    ],
                  ),
                  SizedBox(height: 16.h),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  List<InlineSpan> _buildAyahSpans(
    BuildContext context,
    QuranAyah? pressedAyah,
  ) {
    final spans = <InlineSpan>[];
    for (final ayah in widget.ayahs) {
      if (widget.surah.number == 1 && ayah.verse == 1) {
        continue;
      }
      final isPressed =
          pressedAyah?.verse == ayah.verse &&
          pressedAyah?.chapter == ayah.chapter;

      spans.add(
        TextSpan(
          text: '${ayah.text} ',
          style: TextStyle(color: isPressed ? AppColors.goldAccent : null),
          recognizer:
              LongPressGestureRecognizer(
                  duration: const Duration(milliseconds: 800),
                )
                ..onLongPress = () {
                  HapticFeedback.mediumImpact();
                  widget.onAyahLongPress(ayah);
                },
        ),
      );

      final ayahKey = widget.ayahKeys[ayah.verse];

      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: GestureDetector(
            key: ayahKey,
            onLongPress: () {
              HapticFeedback.mediumImpact();
              widget.onAyahLongPress(ayah);
            },
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
    required this.isKhatmaSession,
    required this.onInterpretation,
    required this.onCopy,
    required this.onSave,
    this.onUpdateKhatma,
  });

  final QuranSurah surah;
  final QuranAyah ayah;
  final String interpretation;
  final bool isKhatmaSession;
  final VoidCallback onInterpretation;
  final VoidCallback onCopy;
  final VoidCallback onSave;
  final VoidCallback? onUpdateKhatma;

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
          if (isKhatmaSession) ...[
            SizedBox(height: 12.h),
            SizedBox(
              width: double.infinity,
              height: 48.h,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                onPressed: onUpdateKhatma,
                icon: const Icon(
                  Icons.bookmark_added_rounded,
                  color: Colors.white,
                ),
                label: Text(
                  'تحديث موضع الختمة',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Cairo',
                  ),
                ),
              ),
            ),
          ],
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
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h),
        decoration: BoxDecoration(
          color: const Color(0xFFF5F7F6),
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        ),
        child: Column(
          children: [
            Icon(icon, color: const Color(0xFF1A6B58), size: 22.sp),
            SizedBox(height: 6.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.sp,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A1710),
                fontFamily: 'Cairo',
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
    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      builder: (_, controller) {
        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(16.r)),
          ),
          child: Column(
            children: [
              SizedBox(height: 10.h),
              Container(
                width: 44.w,
                height: 4.h,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20.r),
                ),
              ),
              SizedBox(height: 16.h),
              Text(
                'تفسير الميسر',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                  color: const Color(0xFF1A6B58),
                ),
              ),
              SizedBox(height: 16.h),
              Expanded(
                child: ListView(
                  controller: controller,
                  padding: EdgeInsets.symmetric(horizontal: 20.w),
                  children: [
                    Container(
                      padding: EdgeInsets.all(16.w),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F9F9),
                        borderRadius: BorderRadius.circular(12.r),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Text(
                        ayah.text,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18.sp,
                          height: 1.8,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A1710),
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      interpretation.isEmpty
                          ? 'التفسير غير متوفر'
                          : interpretation,
                      style: TextStyle(
                        fontSize: 15.sp,
                        height: 1.8,
                        fontWeight: FontWeight.w500,
                        fontFamily: 'Cairo',
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: 40.h),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _NavigationCard extends StatelessWidget {
  const _NavigationCard({
    required this.title,
    required this.surahName,
    required this.isNext,
    required this.onTap,
  });

  final String title;
  final String surahName;
  final bool isNext;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12.r),
          border: Border.all(
            color: const Color(0xFF1E1A12).withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isNext)
              Icon(
                Icons.keyboard_arrow_right_rounded,
                color: const Color(0xFF1A6B58),
                size: 20.sp,
              ),
            SizedBox(width: 4.w),
            Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10.sp,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Cairo',
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  surahName,
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: const Color(0xFF1E1A12),
                    fontWeight: FontWeight.w800,
                    fontFamily: 'Amiri',
                  ),
                ),
              ],
            ),
            SizedBox(width: 4.w),
            if (!isNext)
              Icon(
                Icons.keyboard_arrow_left_rounded,
                color: const Color(0xFF1A6B58),
                size: 20.sp,
              ),
          ],
        ),
      ),
    );
  }
}
