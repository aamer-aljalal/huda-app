// import 'dart:convert';

// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:tarteel/features/quran/services/quran_service.dart';
// import 'package:tarteel/features/quran/widgets/ayah_number.dart';
// import 'package:tarteel/features/quran/widgets/ayah_top_bar.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:tarteel/core/services/recent_actions_service.dart';
// import 'package:tarteel/core/theme/app_colors.dart';
// import 'package:tarteel/core/services/stats_service.dart';

// import 'package:tarteel/core/services/in_app_notification_service.dart';

// class SurahDetailPage extends StatefulWidget {
//   const SurahDetailPage({
//     super.key,
//     required this.surah,
//     required this.ayahs,
//     this.initialPage = 0,
//     this.initialAyah,
//     this.resumeLastPage = false,
//     this.isKhatmaSession = false,
//   });

//   final QuranSurah surah;
//   final List<QuranAyah> ayahs;
//   final int initialPage;
//   final int? initialAyah;
//   final bool resumeLastPage;
//   final bool isKhatmaSession;

//   @override
//   State<SurahDetailPage> createState() => _SurahDetailPageState();
// }

// class _SurahDetailPageState extends State<SurahDetailPage> {
//   static const String _savedAyahsKey = 'saved_quran_ayahs';

//   late final List<List<QuranAyah>> _pages;
//   late final List<GlobalKey> _pageKeys;
//   late final GlobalKey _centerSliverKey;
//   int _currentPage = 0;
//   int _centerPage = 0;
//   bool _isLoading = false;
//   List<QuranSurah> _allSurahs = [];
//   final ValueNotifier<QuranAyah?> _pressedAyahNotifier = ValueNotifier(null);

//   @override
//   void initState() {
//     super.initState();
//     _pages = _splitIntoMushafPages(widget.ayahs);
//     _pageKeys = List.generate(_pages.length, (_) => GlobalKey());
//     _centerSliverKey = GlobalKey();

//     int startPage = widget.initialPage;
//     if (widget.initialAyah != null) {
//       for (int i = 0; i < _pages.length; i++) {
//         if (_pages[i].any((a) => a.verse == widget.initialAyah)) {
//           startPage = i;
//           break;
//         }
//       }
//     }

//     _centerPage = startPage;
//     if (_centerPage >= _pages.length) _centerPage = 0;
//     _currentPage = _centerPage;

//     if (widget.resumeLastPage) {
//       _isLoading = true;
//       _loadSavedPageAsync();
//     } else {
//       _loadSavedPageSync();
//     }

//     _loadAllSurahs();

//     if (widget.surah.number == 18) {
//       InAppNotificationService.markCompleted('surah_kahf');
//     }
//   }

//   Future<void> _loadAllSurahs() async {
//     try {
//       final surahs = await QuranService.loadSurahs();
//       if (mounted) {
//         setState(() {
//           _allSurahs = surahs;
//         });
//       }
//     } catch (_) {}
//   }

//   Future<void> _loadSavedPageAsync() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       final savedPage = prefs.getInt('quran_page_${widget.surah.number}') ?? 0;
//       if (savedPage > 0 && savedPage < _pages.length) {
//         _centerPage = savedPage;
//         _currentPage = savedPage;
//       }
//     } catch (_) {}

//     if (mounted) {
//       setState(() {
//         _isLoading = false;
//       });
//       _postLoadActions();
//     }
//   }

//   void _loadSavedPageSync() {
//     _postLoadActions();
//   }

//   void _postLoadActions() {
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       _saveRecentQuranAction();
//       if (widget.isKhatmaSession) {
//         _updateKhatmaProgress(_currentPage);
//       }
//     });
//   }

//   Future<void> _saveRecentQuranAction() async {
//     try {
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.setInt('quran_page_${widget.surah.number}', _currentPage);
//       await prefs.setInt('quran_last_read_surah_number', widget.surah.number);
//       await RecentActionsManager.addAction(
//         category: 'quran',
//         title: 'سورة ${widget.surah.nameArabic}',
//         subtitle: 'صفحة ${_currentPage + 1}',
//         extraData: {'surah_number': widget.surah.number},
//       );
//     } catch (_) {}
//   }

//   Future<void> _showAyahActions(QuranAyah ayah) async {
//     _pressedAyahNotifier.value = ayah;
//     final interpretation = await QuranService.loadInterpretation(
//       surahNumber: ayah.chapter,
//       ayahNumber: ayah.verse,
//     );

//     if (!mounted) {
//       _pressedAyahNotifier.value = null;
//       return;
//     }
//     await showModalBottomSheet(
//       context: context,
//       backgroundColor: Colors.transparent,
//       builder: (context) {
//         return Directionality(
//           textDirection: TextDirection.rtl,
//           child: _AyahActionsSheet(
//             surah: widget.surah,
//             ayah: ayah,
//             interpretation: interpretation,
//             onCopy: () => _copyAyah(ayah),
//             onSave: () => _saveAyah(ayah, interpretation),
//             onInterpretation: () => _showInterpretation(ayah, interpretation),
//           ),
//         );
//       },
//     );
//     _pressedAyahNotifier.value = null;
//   }

//   Future<void> _copyAyah(QuranAyah ayah) async {
//     await Clipboard.setData(
//       ClipboardData(
//         text:
//             'سورة ${widget.surah.nameArabic} - الآية ${ayah.verse}\n\n${ayah.text}',
//       ),
//     );

//     if (!mounted) return;
//     Navigator.pop(context);
//     ScaffoldMessenger.of(
//       context,
//     ).showSnackBar(const SnackBar(content: Text('تم نسخ الآية')));
//   }

//   Future<void> _saveAyah(QuranAyah ayah, String interpretation) async {
//     final prefs = await SharedPreferences.getInstance();
//     final saved = prefs.getStringList(_savedAyahsKey) ?? [];
//     final key = '${ayah.chapter}:${ayah.verse}';

//     final alreadySaved = saved.any((item) {
//       final decoded = jsonDecode(item) as Map<String, dynamic>;
//       return decoded['key'] == key;
//     });

//     if (!alreadySaved) {
//       saved.add(
//         jsonEncode({
//           'key': key,
//           'surahNumber': ayah.chapter,
//           'surahName': widget.surah.nameArabic,
//           'ayahNumber': ayah.verse,
//           'ayahText': ayah.text,
//           'interpretation': interpretation,
//           'savedAt': DateTime.now().toIso8601String(),
//         }),
//       );
//       await prefs.setStringList(_savedAyahsKey, saved);
//     }

//     if (!mounted) return;
//     Navigator.pop(context);
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(
//         content: Text(alreadySaved ? 'الآية محفوظة سابقاً' : 'تم حفظ الآية'),
//       ),
//     );
//   }

//   void _showInterpretation(QuranAyah ayah, String interpretation) {
//     Navigator.pop(context);
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) {
//         return Directionality(
//           textDirection: TextDirection.rtl,
//           child: _InterpretationSheet(
//             surahName: widget.surah.nameArabic,
//             ayah: ayah,
//             interpretation: interpretation,
//           ),
//         );
//       },
//     );
//   }

//   @override
//   void dispose() {
//     _pressedAyahNotifier.dispose();
//     super.dispose();
//   }

//   void _onScroll() {
//     for (int i = 0; i < _pages.length; i++) {
//       final key = _pageKeys[i];
//       final context = key.currentContext;
//       if (context != null) {
//         final box = context.findRenderObject() as RenderBox?;
//         if (box != null) {
//           final position = box.localToGlobal(Offset.zero).dy;
//           final height = box.size.height;
//           // Use a reasonable center threshold (e.g. 300 logical pixels from top)
//           if (position <= 300 && position + height > 300) {
//             if (_currentPage != i) {
//               setState(() {
//                 _currentPage = i;
//               });
//               _saveRecentQuranAction();
//               if (widget.isKhatmaSession) {
//                 _updateKhatmaProgress(i);
//               }
//             }
//             break;
//           }
//         }
//       }
//     }
//   }

//   Widget _buildPageSliver(int index) {
//     return _MushafPage(
//       key: _pageKeys[index],
//       surah: widget.surah,
//       ayahs: _pages[index],
//       isFirstPage: index == 0,
//       isLastPage: index == _pages.length - 1,
//       pageNumber: index + 1,
//       onAyahLongPress: _showAyahActions,
//       nextSurah: _nextSurah,
//       prevSurah: _prevSurah,
//       onNavigate: _navigateToSurah,
//       pressedAyahNotifier: _pressedAyahNotifier,
//     );
//   }

//   QuranSurah? get _nextSurah {
//     if (_allSurahs.isEmpty) return null;
//     final nextNumber = widget.surah.number + 1;
//     if (nextNumber > 114) return null;
//     return _allSurahs.firstWhere((s) => s.number == nextNumber);
//   }

//   QuranSurah? get _prevSurah {
//     if (_allSurahs.isEmpty) return null;
//     final prevNumber = widget.surah.number - 1;
//     if (prevNumber < 1) return null;
//     return _allSurahs.firstWhere((s) => s.number == prevNumber);
//   }

//   Future<void> _navigateToSurah(int surahNumber) async {
//     try {
//       final surahs = await QuranService.loadSurahs();
//       final targetSurah = surahs.firstWhere((s) => s.number == surahNumber);
//       final ayahs = await QuranService.loadAyahs(surahNumber);
//       if (!mounted) return;
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (context) => SurahDetailPage(
//             surah: targetSurah,
//             ayahs: ayahs,
//             isKhatmaSession: widget.isKhatmaSession,
//           ),
//         ),
//       );
//     } catch (_) {}
//   }

//   Future<void> _updateKhatmaProgress(int newPage) async {
//     if (!widget.isKhatmaSession) return;

//     try {
//       final prefs = await SharedPreferences.getInstance();

//       // Save the current Surah and page in SharedPreferences specifically for Khatma plan
//       await prefs.setInt('khatma_last_read_surah', widget.surah.number);
//       await prefs.setInt('khatma_last_read_page', newPage);

//       // Calculate absolute page
//       final offset = await getAbsolutePageOffset(widget.surah.number);
//       final currentAbsolutePage = offset + newPage;

//       // Load current Khatma progress
//       final previousTotalRead = prefs.getInt('khatma_pages_read') ?? 0;

//       // Let's load the maximum reached absolute page
//       final prevMaxReached = prefs.getInt('khatma_max_reached_page') ?? 0;

//       if (currentAbsolutePage > prevMaxReached) {
//         final difference = currentAbsolutePage - prevMaxReached;
//         await prefs.setInt('khatma_max_reached_page', currentAbsolutePage);

//         // Update Khatma pages read
//         final newTotalRead = (previousTotalRead + difference).clamp(0, 604);
//         await prefs.setInt('khatma_pages_read', newTotalRead);

//         // Update today's read pages
//         final now = DateTime.now();
//         final todayStr = '${now.year}-${now.month}-${now.day}';

//         var readToday = prefs.getInt('khatma_pages_read_today') ?? 0;
//         final lastReadStr = prefs.getString('khatma_last_read_date');
//         if (lastReadStr != null) {
//           final lastReadDate = DateTime.parse(lastReadStr);
//           final lastReadDayStr =
//               '${lastReadDate.year}-${lastReadDate.month}-${lastReadDate.day}';
//           if (todayStr != lastReadDayStr) {
//             readToday = 0;
//           }
//         }

//         final newReadToday = readToday + difference;
//         await prefs.setInt('khatma_pages_read_today', newReadToday);
//         await prefs.setString('khatma_last_read_date', now.toIso8601String());

//         // Also log in the general StatsService
//         await StatsService.recordAction('quran', amount: difference);

//         // Check if completed
//         if (newTotalRead >= 604) {
//           await StatsService.incrementCompletedKhatmas();
//         }
//       }
//     } catch (_) {}
//   }

//   static Future<int> getAbsolutePageOffset(int surahNumber) async {
//     int offset = 0;
//     for (int i = 1; i < surahNumber; i++) {
//       try {
//         final ayahs = await QuranService.loadAyahs(i);
//         final pages = _splitIntoMushafPagesStatic(ayahs);
//         offset += pages.length;
//       } catch (_) {}
//     }
//     return offset;
//   }

//   static List<List<QuranAyah>> _splitIntoMushafPagesStatic(
//     List<QuranAyah> ayahs,
//   ) {
//     final pages = <List<QuranAyah>>[];
//     var current = <QuranAyah>[];
//     var currentLength = 0;

//     for (final ayah in ayahs) {
//       final nextLength = currentLength + ayah.text.length;
//       final maxLength = current.isEmpty ? 980 : 920;

//       if (current.isNotEmpty && nextLength > maxLength) {
//         pages.add(current);
//         current = <QuranAyah>[];
//         currentLength = 0;
//       }

//       current.add(ayah);
//       currentLength += ayah.text.length;
//     }

//     if (current.isNotEmpty) pages.add(current);
//     return pages;
//   }

//   List<List<QuranAyah>> _splitIntoMushafPages(List<QuranAyah> ayahs) {
//     final pages = <List<QuranAyah>>[];
//     var current = <QuranAyah>[];
//     var currentLength = 0;

//     for (final ayah in ayahs) {
//       final nextLength = currentLength + ayah.text.length;
//       final maxLength = current.isEmpty ? 980 : 920;

//       if (current.isNotEmpty && nextLength > maxLength) {
//         pages.add(current);
//         current = <QuranAyah>[];
//         currentLength = 0;
//       }

//       current.add(ayah);
//       currentLength += ayah.text.length;
//     }

//     if (current.isNotEmpty) pages.add(current);
//     return pages;
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Directionality(
//       textDirection: TextDirection.rtl,
//       child: Scaffold(
//         backgroundColor: const Color.fromARGB(255, 255, 255, 255),
//         body: SafeArea(
//           child: Column(
//             children: [
//               MushafTopBar(
//                 surah: widget.surah,
//                 currentPage: _currentPage + 1,
//                 pagesCount: _pages.length,
//               ),
//               Expanded(
//                 child: Container(
//                   padding: EdgeInsets.only(top: 65.h, bottom: 60.h),
//                   decoration: const BoxDecoration(
//                     image: DecorationImage(
//                       image: AssetImage('assets/img/surah_detail_green.png'),
//                       fit: BoxFit.fill,
//                     ),
//                   ),
//                   child: Padding(
//                     padding: EdgeInsets.only(right: 18.w, left: 18.w),
//                     child: _isLoading
//                         ? const Center(child: CircularProgressIndicator())
//                         : NotificationListener<ScrollNotification>(
//                             onNotification: (scrollInfo) {
//                               _onScroll();
//                               return false;
//                             },
//                             child: CustomScrollView(
//                               center: _centerSliverKey,
//                               physics: const BouncingScrollPhysics(),
//                               slivers: [
//                                 if (_centerPage > 0)
//                                   SliverList(
//                                     delegate: SliverChildBuilderDelegate((
//                                       context,
//                                       index,
//                                     ) {
//                                       final actualIndex =
//                                           _centerPage - 1 - index;
//                                       return _buildPageSliver(actualIndex);
//                                     }, childCount: _centerPage),
//                                   ),
//                                 SliverList(
//                                   key: _centerSliverKey,
//                                   delegate: SliverChildBuilderDelegate((
//                                     context,
//                                     index,
//                                   ) {
//                                     final actualIndex = _centerPage + index;
//                                     return _buildPageSliver(actualIndex);
//                                   }, childCount: _pages.length - _centerPage),
//                                 ),
//                               ],
//                             ),
//                           ),
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }

// class _MushafPage extends StatefulWidget {
//   const _MushafPage({
//     super.key,
//     required this.surah,
//     required this.ayahs,
//     required this.isFirstPage,
//     required this.isLastPage,
//     required this.pageNumber,
//     required this.onAyahLongPress,
//     required this.nextSurah,
//     required this.prevSurah,
//     required this.onNavigate,
//     required this.pressedAyahNotifier,
//   });

//   final QuranSurah surah;
//   final List<QuranAyah> ayahs;
//   final bool isFirstPage;
//   final bool isLastPage;
//   final int pageNumber;
//   final ValueChanged<QuranAyah> onAyahLongPress;
//   final QuranSurah? nextSurah;
//   final QuranSurah? prevSurah;
//   final ValueChanged<int> onNavigate;
//   final ValueNotifier<QuranAyah?> pressedAyahNotifier;

//   @override
//   State<_MushafPage> createState() => _MushafPageState();
// }

// class _MushafPageState extends State<_MushafPage> {
//   bool get _showBasmala => widget.isFirstPage && widget.surah.number != 9;

//   @override
//   Widget build(BuildContext context) {
//     final textScale = MediaQuery.textScalerOf(context);

//     return Container(
//       width: double.infinity,
//       color: Colors.transparent,
//       padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 0),
//       child: Column(
//         mainAxisAlignment: MainAxisAlignment.start,
//         children: [
//           Align(
//             alignment: Alignment.topCenter,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.center,
//               children: [
//                 if (widget.isFirstPage) ...[
//                   if (_showBasmala) ...[
//                     Padding(
//                       padding: const EdgeInsets.only(top: 10),
//                       child: Text(
//                         'بِسۡمِ ٱللَّهِ ٱلرَّحۡمَٰنِ ٱلرَّحِيمِ',
//                         textAlign: TextAlign.center,
//                         style: TextStyle(
//                           color: const Color(0xFF1E1A12),
//                           fontSize: textScale.scale(15.sp),
//                           fontWeight: FontWeight.w700,
//                           height: 0.5.h,
//                           fontFamily: 'Amiri',
//                         ),
//                       ),
//                     ),
//                   ],
//                   SizedBox(height: 30.h),
//                 ],
//                 ValueListenableBuilder<QuranAyah?>(
//                   valueListenable: widget.pressedAyahNotifier,
//                   builder: (context, pressedAyah, child) {
//                     return RichText(
//                       textDirection: TextDirection.rtl,
//                       textAlign: TextAlign.justify,
//                       text: TextSpan(
//                         style: TextStyle(
//                           color: const Color(0xFF1A1710),
//                           fontSize: textScale.scale(18.sp),
//                           height: 2.05,
//                           fontWeight: FontWeight.w500,
//                           fontFamily: 'Amiri',
//                         ),
//                         children: _buildAyahSpans(context, pressedAyah),
//                       ),
//                     );
//                   },
//                 ),
//                 if (widget.isLastPage &&
//                     (widget.prevSurah != null || widget.nextSurah != null)) ...[
//                   SizedBox(height: 32.h),
//                   Container(
//                     width: 120.w,
//                     height: 1.h,
//                     color: const Color(0xFF1E1A12).withValues(alpha: 0.15),
//                   ),
//                   SizedBox(height: 24.h),
//                   Row(
//                     mainAxisAlignment: MainAxisAlignment.spaceEvenly,
//                     children: [
//                       if (widget.prevSurah != null)
//                         Expanded(
//                           child: Padding(
//                             padding: EdgeInsets.symmetric(horizontal: 6.w),
//                             child: _NavigationCard(
//                               title: 'السورة السابقة',
//                               surahName: widget.prevSurah!.nameArabic,
//                               isNext: false,
//                               onTap: () =>
//                                   widget.onNavigate(widget.prevSurah!.number),
//                             ),
//                           ),
//                         ),
//                       if (widget.nextSurah != null)
//                         Expanded(
//                           child: Padding(
//                             padding: EdgeInsets.symmetric(horizontal: 6.w),
//                             child: _NavigationCard(
//                               title: 'السورة التالية',
//                               surahName: widget.nextSurah!.nameArabic,
//                               isNext: true,
//                               onTap: () =>
//                                   widget.onNavigate(widget.nextSurah!.number),
//                             ),
//                           ),
//                         ),
//                     ],
//                   ),
//                   SizedBox(height: 16.h),
//                 ],
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   List<InlineSpan> _buildAyahSpans(
//     BuildContext context,
//     QuranAyah? pressedAyah,
//   ) {
//     final spans = <InlineSpan>[];
//     for (final ayah in widget.ayahs) {
//       if (widget.surah.number == 1 && ayah.verse == 1) {
//         continue;
//       }
//       final isPressed =
//           pressedAyah?.verse == ayah.verse &&
//           pressedAyah?.chapter == ayah.chapter;

//       spans.add(
//         TextSpan(
//           text: '${ayah.text} ',
//           style: TextStyle(color: isPressed ? AppColors.goldAccent : null),
//           recognizer:
//               LongPressGestureRecognizer(
//                   duration: const Duration(milliseconds: 800),
//                 )
//                 ..onLongPress = () {
//                   HapticFeedback.mediumImpact();
//                   widget.onAyahLongPress(ayah);
//                 },
//         ),
//       );
//       spans.add(
//         WidgetSpan(
//           alignment: PlaceholderAlignment.middle,
//           child: GestureDetector(
//             onLongPress: () {
//               HapticFeedback.mediumImpact();
//               widget.onAyahLongPress(ayah);
//             },
//             child: AyahNumber(number: ayah.verse),
//           ),
//         ),
//       );
//       spans.add(const TextSpan(text: ' '));
//     }
//     return spans;
//   }
// }

// class _AyahActionsSheet extends StatelessWidget {
//   const _AyahActionsSheet({
//     required this.surah,
//     required this.ayah,
//     required this.interpretation,
//     required this.onInterpretation,
//     required this.onCopy,
//     required this.onSave,
//   });

//   final QuranSurah surah;
//   final QuranAyah ayah;
//   final String interpretation;
//   final VoidCallback onInterpretation;
//   final VoidCallback onCopy;
//   final VoidCallback onSave;

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 22.h),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
//       ),
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Center(
//             child: Container(
//               width: 44.w,
//               height: 4.h,
//               decoration: BoxDecoration(
//                 color: Colors.black.withValues(alpha: 0.18),
//                 borderRadius: BorderRadius.circular(20.r),
//               ),
//             ),
//           ),
//           SizedBox(height: 14.h),
//           Text(
//             'سورة ${surah.nameArabic} - الآية ${ayah.verse}',
//             style: TextStyle(
//               fontSize: 15.sp,
//               fontWeight: FontWeight.w800,
//               color: const Color(0xFF1A6B58),
//             ),
//           ),
//           SizedBox(height: 8.h),
//           Text(
//             ayah.text,
//             maxLines: 3,
//             overflow: TextOverflow.ellipsis,
//             style: TextStyle(
//               fontSize: 16.sp,
//               height: 1.7,
//               color: const Color(0xFF1A1710),
//               fontWeight: FontWeight.w500,
//             ),
//           ),
//           SizedBox(height: 16.h),
//           Row(
//             children: [
//               Expanded(
//                 child: _SheetActionButton(
//                   icon: Icons.menu_book_outlined,
//                   label: 'تفسير الآية',
//                   onTap: onInterpretation,
//                 ),
//               ),
//               SizedBox(width: 8.w),
//               Expanded(
//                 child: _SheetActionButton(
//                   icon: Icons.copy,
//                   label: 'نسخ الآية',
//                   onTap: onCopy,
//                 ),
//               ),
//               SizedBox(width: 8.w),
//               Expanded(
//                 child: _SheetActionButton(
//                   icon: Icons.bookmark_add_outlined,
//                   label: 'حفظ الآية',
//                   onTap: onSave,
//                 ),
//               ),
//             ],
//           ),
//         ],
//       ),
//     );
//   }
// }

// class _SheetActionButton extends StatelessWidget {
//   const _SheetActionButton({
//     required this.icon,
//     required this.label,
//     required this.onTap,
//   });

//   final IconData icon;
//   final String label;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(8.r),
//       child: Container(
//         padding: EdgeInsets.symmetric(vertical: 10.h, horizontal: 6.w),
//         decoration: BoxDecoration(
//           color: const Color(0xFF1A6B58).withValues(alpha: 0.08),
//           borderRadius: BorderRadius.circular(8.r),
//           border: Border.all(
//             color: const Color(0xFF1A6B58).withValues(alpha: 0.16),
//           ),
//         ),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(icon, color: const Color(0xFF1A6B58), size: 22.sp),
//             SizedBox(height: 5.h),
//             Text(
//               label,
//               maxLines: 1,
//               overflow: TextOverflow.ellipsis,
//               style: TextStyle(
//                 color: const Color(0xFF1A6B58),
//                 fontSize: 11.sp,
//                 fontWeight: FontWeight.w800,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }

// class _InterpretationSheet extends StatelessWidget {
//   const _InterpretationSheet({
//     required this.surahName,
//     required this.ayah,
//     required this.interpretation,
//   });

//   final String surahName;
//   final QuranAyah ayah;
//   final String interpretation;

//   @override
//   Widget build(BuildContext context) {
//     final hasInterpretation = interpretation.trim().isNotEmpty;

//     return DraggableScrollableSheet(
//       initialChildSize: 0.55,
//       minChildSize: 0.35,
//       maxChildSize: 0.9,
//       builder: (context, controller) {
//         return Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.vertical(top: Radius.circular(14.r)),
//           ),
//           child: ListView(
//             controller: controller,
//             padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 26.h),
//             children: [
//               Center(
//                 child: Container(
//                   width: 44.w,
//                   height: 4.h,
//                   decoration: BoxDecoration(
//                     color: Colors.black.withValues(alpha: 0.18),
//                     borderRadius: BorderRadius.circular(20.r),
//                   ),
//                 ),
//               ),
//               SizedBox(height: 16.h),
//               Text(
//                 'تفسير سورة $surahName - الآية ${ayah.verse}',
//                 style: TextStyle(
//                   fontSize: 16.sp,
//                   fontWeight: FontWeight.w900,
//                   color: const Color(0xFF1A6B58),
//                 ),
//               ),
//               SizedBox(height: 12.h),
//               Text(
//                 hasInterpretation
//                     ? interpretation
//                     : 'لا يوجد تفسير متاح لهذه الآية في الملف الحالي.',
//                 style: TextStyle(
//                   fontSize: 16.sp,
//                   height: 1.8,
//                   color: const Color(0xFF1A1710),
//                   fontWeight: FontWeight.w500,
//                 ),
//               ),
//             ],
//           ),
//         );
//       },
//     );
//   }
// }

// class _NavigationCard extends StatelessWidget {
//   const _NavigationCard({
//     required this.title,
//     required this.surahName,
//     required this.isNext,
//     required this.onTap,
//   });

//   final String title;
//   final String surahName;
//   final bool isNext;
//   final VoidCallback onTap;

//   @override
//   Widget build(BuildContext context) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(10.r),
//       child: Container(
//         padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 10.w),
//         decoration: BoxDecoration(
//           color: const Color(
//             0xFF14532D,
//           ).withValues(alpha: 0.06), // Subtle brand green background
//           borderRadius: BorderRadius.circular(10.r),
//           border: Border.all(
//             color: const Color(0xFF14532D).withValues(alpha: 0.16),
//             width: 1.w,
//           ),
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withValues(alpha: 0.02),
//               blurRadius: 6,
//               offset: const Offset(0, 2),
//             ),
//           ],
//         ),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             if (!isNext) ...[
//               Icon(
//                 Icons
//                     .arrow_forward_ios_rounded, // Right arrow for "Previous" in RTL Arabic
//                 size: 14.sp,
//                 color: const Color(0xFF14532D),
//               ),
//               SizedBox(width: 6.w),
//             ],
//             Expanded(
//               child: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 crossAxisAlignment: isNext
//                     ? CrossAxisAlignment.start
//                     : CrossAxisAlignment.end,
//                 children: [
//                   Text(
//                     title,
//                     maxLines: 1,
//                     style: TextStyle(
//                       fontSize: 10.sp,
//                       color: const Color(0xFF64748B),
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   SizedBox(height: 2.h),
//                   Text(
//                     'سورة $surahName',
//                     maxLines: 1,
//                     overflow: TextOverflow.ellipsis,
//                     style: TextStyle(
//                       fontSize: 13.sp,
//                       color: const Color(0xFF14532D),
//                       fontWeight: FontWeight.w800,
//                     ),
//                   ),
//                 ],
//               ),
//             ),
//             if (isNext) ...[
//               SizedBox(width: 6.w),
//               Icon(
//                 Icons
//                     .arrow_back_ios_new_rounded, // Left arrow for "Next" in RTL Arabic
//                 size: 14.sp,
//                 color: const Color(0xFF14532D),
//               ),
//             ],
//           ],
//         ),
//       ),
//     );
//   }
// }
