import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/theme/app_colors.dart';
import 'package:huda/core/widgets/appbars/huda_app_bar.dart';
import 'package:huda/core/widgets/Text/Responsive_text.dart';
import '../models/prophet_story_model.dart';
import '../services/prophets_stories_service.dart';
import 'prophet_story_details_screen.dart';

class ProphetsListScreen extends StatefulWidget {
  const ProphetsListScreen({super.key});

  @override
  State<ProphetsListScreen> createState() => _ProphetsListScreenState();
}

class _ProphetsListScreenState extends State<ProphetsListScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late AnimationController _animationController;

  List<ProphetStoryModel> _allStories = [];
  List<ProphetStoryModel> _filteredStories = [];
  Set<int> _favoriteIds = {};
  bool _isLoading = true;
  bool _showOnlyFavorites = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _loadStories();
    _searchController.addListener(_filterStories);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadStories() async {
    try {
      final stories = await ProphetsStoriesService.loadStories();
      final favorites = await ProphetsStoriesService.getFavorites();

      if (!mounted) return;
      setState(() {
        _allStories = stories;
        _filteredStories = stories;
        _favoriteIds = favorites;
        _isLoading = false;
      });
      _animationController.forward();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'تعذر تحميل قصص الأنبياء عليهم السلام';
        _isLoading = false;
      });
    }
  }

  void _filterStories() {
    final query = _searchController.text.trim();
    setState(() {
      _filteredStories = _allStories.where((story) {
        final matchesQuery = story.matches(query);
        final matchesFav = !_showOnlyFavorites || _favoriteIds.contains(story.id);
        return matchesQuery && matchesFav;
      }).toList();
    });
  }

  void _toggleShowFavorites() {
    setState(() {
      _showOnlyFavorites = !_showOnlyFavorites;
      _filterStories();
    });
    
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _toggleFavorite(ProphetStoryModel story) async {
    final added = await ProphetsStoriesService.toggleFavorite(story.id);
    setState(() {
      if (added) {
        _favoriteIds.add(story.id);
      } else {
        _favoriteIds.remove(story.id);
      }
      _filterStories();
    });

    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          added ? 'تمت إضافة قصة ${story.name} إلى المفضلة' : 'تمت إزالة قصة ${story.name} من المفضلة',
          style: const TextStyle(fontFamily: 'Cairo', fontWeight: FontWeight.bold),
        ),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: HudaAppBar(
          titleText: 'قصص الأنبياء',
          showSearch: true,
          searchController: _searchController,
          searchHint: 'ابحث عن اسم نبي أو كلمة بالقصة...',
          actions: [
            IconButton(
              tooltip: _showOnlyFavorites ? 'عرض الكل' : 'عرض المحفوظات',
              icon: Icon(
                _showOnlyFavorites ? Icons.star_rounded : Icons.star_border_rounded,
                color: _showOnlyFavorites ? Colors.amber : (isDark ? AppColors.goldAccent : Colors.white),
                size: 24.sp,
              ),
              onPressed: _isLoading ? null : _toggleShowFavorites,
            ),
          ],
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: EdgeInsets.all(24.w),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 64.sp, color: Colors.red.shade400),
              SizedBox(height: 16.h),
              Text(
                _errorMessage!,
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Cairo',
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        // Summary Bar
        _SummaryBar(
          total: _allStories.length,
          visible: _filteredStories.length,
          favorites: _favoriteIds.length,
          showOnlyFavorites: _showOnlyFavorites,
        ),

        // List
        Expanded(
          child: _filteredStories.isEmpty
              ? _EmptyState(
                  showOnlyFavorites: _showOnlyFavorites,
                  onReset: () {
                    setState(() {
                      _showOnlyFavorites = false;
                      _searchController.clear();
                      _filteredStories = _allStories;
                    });
                  },
                )
              : ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16.w, 4.h, 16.w, 80.h),
                  itemCount: _filteredStories.length,
                  itemBuilder: (context, index) {
                    final story = _filteredStories[index];
                    final isFavorite = _favoriteIds.contains(story.id);

                    // Build entry animation
                    final delay = (index < 8) ? index * 0.08 : 0.0;
                    final animation = Tween<double>(begin: 0.0, end: 1.0).animate(
                      CurvedAnimation(
                        parent: _animationController,
                        curve: Interval(
                          delay,
                          math.min(delay + 0.4, 1.0),
                          curve: Curves.easeOutCubic,
                        ),
                      ),
                    );

                    return AnimatedBuilder(
                      animation: animation,
                      builder: (context, child) {
                        return Opacity(
                          opacity: animation.value,
                          child: Transform.translate(
                            offset: Offset(0, (1.0 - animation.value) * 30),
                            child: child,
                          ),
                        );
                      },
                      child: _ProphetCard(
                        story: story,
                        isFavorite: isFavorite,
                        onTap: () async {
                          // Navigate to details
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProphetStoryDetailsScreen(story: story),
                            ),
                          );
                          // Refresh favorites state upon return
                          final favorites = await ProphetsStoriesService.getFavorites();
                          setState(() {
                            _favoriteIds = favorites;
                            _filterStories();
                          });
                        },
                        onFavorite: () => _toggleFavorite(story),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _SummaryBar extends StatelessWidget {
  const _SummaryBar({
    required this.total,
    required this.visible,
    required this.favorites,
    required this.showOnlyFavorites,
  });

  final int total;
  final int visible;
  final int favorites;
  final bool showOnlyFavorites;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 12.h, 16.w, 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        boxShadow: isDark 
            ? [] 
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ],
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.menu_book_rounded,
            color: AppColors.primary,
            size: 20.sp,
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Text(
              showOnlyFavorites 
                  ? 'المفضلة: $visible قصة' 
                  : 'القصص المتاحة: $visible من $total',
              style: TextStyle(
                color: isDark ? AppColors.darkPrimaryText : AppColors.lightPrimaryText,
                fontWeight: FontWeight.bold,
                fontSize: 12.sp,
                fontFamily: 'Cairo',
              ),
            ),
          ),
          Icon(Icons.star_rounded, color: Colors.amber, size: 18.sp),
          SizedBox(width: 4.w),
          Text(
            '$favorites محفوظ',
            style: TextStyle(
              color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
              fontWeight: FontWeight.bold,
              fontSize: 11.sp,
              fontFamily: 'Cairo',
            ),
          ),
        ],
      ),
    );
  }
}

class _ProphetCard extends StatelessWidget {
  const _ProphetCard({
    required this.story,
    required this.isFavorite,
    required this.onTap,
    required this.onFavorite,
  });

  final ProphetStoryModel story;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: EdgeInsets.only(bottom: 12.h),
      child: Material(
        color: isDark ? AppColors.darkSurface : Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        elevation: isDark ? 0 : 3,
        shadowColor: Colors.black.withOpacity(0.04),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16.r),
          child: Container(
            padding: EdgeInsets.all(16.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isFavorite
                    ? AppColors.primary.withOpacity(0.4)
                    : (isDark ? AppColors.darkBorder : AppColors.lightBorder),
                width: isFavorite ? 1.8 : 1.0,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Star shape with Prophet Number index
                _ProphetNumber(number: story.id),
                SizedBox(width: 14.w),
                
                // Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              story.name,
                              style: TextStyle(
                                fontSize: 14.sp,
                                fontWeight: FontWeight.w900,
                                color: AppColors.primary,
                                fontFamily: 'Cairo',
                              ),
                            ),
                          ),
                          IconButton(
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            icon: Icon(
                              isFavorite ? Icons.star_rounded : Icons.star_border_rounded,
                              size: 22.sp,
                            ),
                            color: isFavorite ? Colors.amber : Colors.grey.shade400,
                            onPressed: onFavorite,
                          ),
                        ],
                      ),
                      SizedBox(height: 6.h),
                      ResponsiveText(
                        content: story.excerpt,
                        maxLines: 2,
                        fontSize: 12,
                        height: 1.6,
                        color: isDark ? AppColors.darkSecondaryText : AppColors.lightSecondaryText,
                        fontFamily: 'Cairo',
                        textAlign: TextAlign.right,
                      ),
                      SizedBox(height: 10.h),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Text(
                            'اقرأ القصة كاملة',
                            style: TextStyle(
                              color: AppColors.goldAccent,
                              fontSize: 10.sp,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Icon(
                            Icons.arrow_back_ios_new_rounded,
                            size: 9.sp,
                            color: AppColors.goldAccent,
                          ),
                        ],
                      ),
                    ],
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

class _ProphetNumber extends StatelessWidget {
  const _ProphetNumber({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Transform.rotate(
          angle: math.pi / 4,
          child: Container(
            width: 32.w,
            height: 32.w,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.08),
              border: Border.all(
                color: AppColors.goldAccent.withOpacity(0.5),
                width: 1.5.w,
              ),
              borderRadius: BorderRadius.circular(6.r),
            ),
          ),
        ),
        Text(
          '$number',
          style: TextStyle(
            color: AppColors.primary,
            fontSize: 12.sp,
            fontWeight: FontWeight.w900,
            fontFamily: 'Cairo',
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.showOnlyFavorites, required this.onReset});

  final bool showOnlyFavorites;
  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              showOnlyFavorites ? Icons.star_outline_rounded : Icons.search_off_rounded,
              size: 56.sp,
              color: Colors.grey.shade400,
            ),
            SizedBox(height: 12.h),
            Text(
              showOnlyFavorites ? 'لم تقم بحفظ أي قصص في المفضلة بعد' : 'لا توجد قصص مطابقة للبحث',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                fontFamily: 'Cairo',
              ),
            ),
            SizedBox(height: 8.h),
            TextButton(
              onPressed: onReset,
              child: Text(
                showOnlyFavorites ? 'عرض جميع قصص الأنبياء' : 'عرض الكل',
                style: const TextStyle(
                  fontFamily: 'Cairo',
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
