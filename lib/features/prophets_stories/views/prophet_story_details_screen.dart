import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tarteel/core/services/recent_actions_service.dart';
import 'package:tarteel/core/services/stats_service.dart';
import '../models/prophet_story_model.dart';
import '../services/prophets_stories_service.dart';

class ProphetStoryDetailsScreen extends StatefulWidget {
  final ProphetStoryModel story;

  const ProphetStoryDetailsScreen({
    super.key,
    required this.story,
  });

  @override
  State<ProphetStoryDetailsScreen> createState() => _ProphetStoryDetailsScreenState();
}

class _ProphetStoryDetailsScreenState extends State<ProphetStoryDetailsScreen> {
  static const String _fontSizeKey = 'prophet_story_font_size';
  
  double _fontSize = 18.0;
  bool _isFavorite = false;
  final ScrollController _scrollController = ScrollController();
  double _scrollProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _loadSettingsAndState();
    _scrollController.addListener(_updateScrollProgress);
    
    // Save to recent actions and record statistics
    _saveRecentAction();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_updateScrollProgress);
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadSettingsAndState() async {
    final prefs = await SharedPreferences.getInstance();
    final favorites = await ProphetsStoriesService.getFavorites();
    
    if (mounted) {
      setState(() {
        _fontSize = prefs.getDouble(_fontSizeKey) ?? 18.0;
        _isFavorite = favorites.contains(widget.story.id);
      });
    }
  }

  void _updateScrollProgress() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    
    if (maxScroll <= 0) return;
    
    setState(() {
      _scrollProgress = (currentScroll / maxScroll).clamp(0.0, 1.0);
    });
  }

  Future<void> _changeFontSize(double delta) async {
    final newSize = (_fontSize + delta).clamp(14.0, 32.0);
    setState(() {
      _fontSize = newSize;
    });
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_fontSizeKey, newSize);
  }

  Future<void> _toggleFavorite() async {
    final added = await ProphetsStoriesService.toggleFavorite(widget.story.id);
    setState(() {
      _isFavorite = added;
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added ? 'تم الحفظ في المفضلة' : 'تمت الإزالة من المفضلة',
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        duration: const Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _copyStory() async {
    // Clean story text a bit for copying
    final cleanText = widget.story.story.replaceAll('            نبذة:\n\n', '').trim();
    await Clipboard.setData(
      ClipboardData(
        text: '$cleanText\n\n[قصص الأنبياء - ${widget.story.name}]',
      ),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'تم نسخ قصة النبي الكريم إلى الحافظة',
          style: TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _shareStory() async {
    final cleanText = widget.story.story.replaceAll('            نبذة:\n\n', '').trim();
    await Share.share(
      '$cleanText\n\n[قصص الأنبياء - ${widget.story.name}]',
      subject: 'قصة ${widget.story.name}',
    );
  }

  Future<void> _saveRecentAction() async {
    try {
      await RecentActionsManager.addAction(
        category: 'prophets_stories',
        title: 'قصص الأنبياء - ${widget.story.name}',
        subtitle: 'تابع قراءة قصص الأنبياء عليهم السلام والدروس المستفادة منها',
        extraData: {'story_id': widget.story.id},
      );

      // Record statistics
      await StatsService.recordAction('prophets_stories');
    } catch (_) {}
  }

  /// Genius method that splits story text and styles Quranic verses / parentheses beautifully
  List<InlineSpan> _buildStorySpans(String text, double baseFontSize, bool isDark) {
    final List<InlineSpan> spans = [];
    
    // Regular expression to catch parentheses (e.g. (آية أو اسم سورة))
    // We match any text enclosed in standard parentheses
    final regex = RegExp(r'\(([^)]+)\)');
    
    int lastMatchEnd = 0;
    final matches = regex.allMatches(text);
    
    final TextStyle normalStyle = TextStyle(
      fontSize: baseFontSize.sp,
      height: 1.8,
      fontFamily: 'Amiri',
      color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
      fontWeight: FontWeight.w400,
    );
    
    final TextStyle verseStyle = TextStyle(
      fontSize: (baseFontSize + 2.0).sp,
      height: 1.8,
      fontFamily: 'Amiri',
      color: isDark ? AppColors.goldAccent : AppColors.primary,
      fontWeight: FontWeight.bold,
    );

    for (final match in matches) {
      // Add text before match
      if (match.start > lastMatchEnd) {
        final precedingText = text.substring(lastMatchEnd, match.start);
        spans.add(TextSpan(text: precedingText, style: normalStyle));
      }
      
      // Add matching parenthesis text styled differently
      final parenthesizedText = match.group(0)!; // Includes the parentheses
      spans.add(TextSpan(text: parenthesizedText, style: verseStyle));
      
      lastMatchEnd = match.end;
    }
    
    // Add remaining text
    if (lastMatchEnd < text.length) {
      final remainingText = text.substring(lastMatchEnd);
      spans.add(TextSpan(text: remainingText, style: normalStyle));
    }
    
    return spans;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.darkSurface : Colors.white;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: tarteelAppBar(
          titleText: widget.story.name,
          actions: [
            IconButton(
              tooltip: 'نسخ القصة',
              icon: Icon(Icons.copy_rounded, size: 20.sp),
              onPressed: _copyStory,
            ),
            IconButton(
              tooltip: 'مشاركة',
              icon: Icon(Icons.share_rounded, size: 20.sp),
              onPressed: _shareStory,
            ),
            IconButton(
              tooltip: 'حفظ للمفضلة',
              icon: Icon(
                _isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                color: _isFavorite ? Colors.amber : null,
                size: 24.sp,
              ),
              onPressed: _toggleFavorite,
            ),
          ],
        ),
        body: Column(
          children: [
            // Reading scroll progress indicator line
            if (_scrollProgress > 0)
              LinearProgressIndicator(
                value: _scrollProgress,
                backgroundColor: Colors.transparent,
                valueColor: const AlwaysStoppedAnimation<Color>(AppColors.goldAccent),
                minHeight: 3.5.h,
              ),
            
            // Story Content
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(16.w, 16.h, 16.w, 32.h),
                child: Container(
                  width: double.infinity,
                  padding: EdgeInsets.all(18.w),
                  decoration: BoxDecoration(
                    color: cardBg,
                    borderRadius: BorderRadius.circular(20.r),
                    boxShadow: isDark 
                        ? [] 
                        : [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.03),
                              blurRadius: 15,
                              offset: const Offset(0, 5),
                            )
                          ],
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header introduction card
                      _IntroductionHeader(prophetName: widget.story.name),
                      
                      const Divider(height: 30, thickness: 1),
                      
                      // Story Text
                      RichText(
                        textAlign: TextAlign.justify,
                        text: TextSpan(
                          children: _buildStorySpans(widget.story.story, _fontSize, isDark),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Premium control bar (Font size + progress percentage)
            _ControlsBar(
              fontSize: _fontSize,
              scrollProgress: _scrollProgress,
              onIncreaseFont: () => _changeFontSize(2.0),
              onDecreaseFont: () => _changeFontSize(-2.0),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroductionHeader extends StatelessWidget {
  const _IntroductionHeader({required this.prophetName});

  final String prophetName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(10.w),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.08),
            shape: BoxShape.circle,
            border: Border.all(
              color: AppColors.goldAccent.withOpacity(0.4),
              width: 1,
            ),
          ),
          child: Icon(
            Icons.menu_book_rounded,
            color: AppColors.primary,
            size: 24.sp,
          ),
        ),
        SizedBox(width: 12.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'قصة النبي الكريم',
                style: TextStyle(
                  color: AppColors.goldAccent,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
              Text(
                prophetName,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w900,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ControlsBar extends StatelessWidget {
  const _ControlsBar({
    required this.fontSize,
    required this.scrollProgress,
    required this.onIncreaseFont,
    required this.onDecreaseFont,
  });

  final double fontSize;
  final double scrollProgress;
  final VoidCallback onIncreaseFont;
  final VoidCallback onDecreaseFont;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final barBg = isDark ? AppColors.darkSurface : Colors.white;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: barBg,
        border: Border(
          top: BorderSide(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
            width: 1,
          ),
        ),
        boxShadow: isDark 
            ? [] 
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, -4),
                )
              ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Font scale title
            Text(
              'حجم الخط:',
              style: TextStyle(
                fontSize: 11.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              ),
            ),
            SizedBox(width: 8.w),
            
            // Decrease button
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(Icons.remove_circle_outline_rounded, size: 22.sp, color: AppColors.primary),
              onPressed: onDecreaseFont,
            ),
            SizedBox(width: 8.w),
            
            // Size number label
            Text(
              '${fontSize.toInt()}',
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
                color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
              ),
            ),
            SizedBox(width: 8.w),
            
            // Increase button
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              icon: Icon(Icons.add_circle_outline_rounded, size: 22.sp, color: AppColors.primary),
              onPressed: onIncreaseFont,
            ),
            
            const Spacer(),
            
            // Progress percentage
            Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.08),
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Text(
                'قرأت ${(scrollProgress * 100).toInt()}%',
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 10.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
