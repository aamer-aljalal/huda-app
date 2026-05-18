import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/widgets/appbars/huda_app_bar.dart';
import 'package:huda/features/Hadith/hadith_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HadithScreen extends StatefulWidget {
  const HadithScreen({super.key});

  @override
  State<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends State<HadithScreen> {
  static const String _favoritesKey = 'favorite_hadith_numbers';

  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<HadithModel> _allHadiths = [];
  List<HadithModel> _filteredHadiths = [];
  Set<int> _favoriteNumbers = {};
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadHadiths();
    _searchController.addListener(_filterHadiths);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadHadiths() async {
    try {
      final results = await Future.wait([
        HadithService.loadHadiths(),
        SharedPreferences.getInstance(),
      ]);

      final hadiths = results[0] as List<HadithModel>;
      final prefs = results[1] as SharedPreferences;
      final favoriteNumbers = prefs.getStringList(_favoritesKey) ?? [];

      if (!mounted) return;
      setState(() {
        _allHadiths = hadiths;
        _filteredHadiths = hadiths;
        _favoriteNumbers = favoriteNumbers
            .map((number) => int.tryParse(number))
            .whereType<int>()
            .toSet();
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'تعذر تحميل ملف الأحاديث';
        _isLoading = false;
      });
    }
  }

  void _filterHadiths() {
    final query = _searchController.text;
    setState(() {
      _filteredHadiths = _allHadiths
          .where((hadith) => hadith.matches(query))
          .toList(growable: false);
    });
  }

  Future<void> _toggleFavorite(HadithModel hadith) async {
    setState(() {
      if (_favoriteNumbers.contains(hadith.number)) {
        _favoriteNumbers.remove(hadith.number);
      } else {
        _favoriteNumbers.add(hadith.number);
      }
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _favoritesKey,
      _favoriteNumbers.map((number) => number.toString()).toList(),
    );
  }

  Future<void> _copyHadith(HadithModel hadith) async {
    await Clipboard.setData(
      ClipboardData(text: 'حديث رقم ${hadith.number}\n\n${hadith.hadith}'),
    );

    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تم نسخ الحديث')));
  }

  void _openRandomHadith() {
    if (_allHadiths.isEmpty) return;
    final random = _allHadiths[math.Random().nextInt(_allHadiths.length)];
    _showHadithDetails(random);
  }

  void _showFavoritesOnly() {
    setState(() {
      _searchController.clear();
      _filteredHadiths = _allHadiths
          .where((hadith) => _favoriteNumbers.contains(hadith.number))
          .toList(growable: false);
    });

    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    }
  }

  void _showHadithDetails(HadithModel hadith) {
    final isFavorite = _favoriteNumbers.contains(hadith.number);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: DraggableScrollableSheet(
            initialChildSize: 0.82,
            minChildSize: 0.45,
            maxChildSize: 0.94,
            builder: (context, controller) {
              return _HadithDetailsSheet(
                hadith: hadith,
                isFavorite: isFavorite,
                controller: controller,
                onCopy: () => _copyHadith(hadith),
                onFavorite: () {
                  Navigator.pop(context);
                  _toggleFavorite(hadith);
                },
              );
            },
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: HudaAppBar(
          titleText: 'الأحاديث',
          showSearch: true,
          searchController: _searchController,
          searchHint: 'ابحث في الأحاديث...',
          actions: [
            IconButton(
              tooltip: 'حديث عشوائي',
              icon: const Icon(Icons.shuffle),
              onPressed: _isLoading ? null : _openRandomHadith,
            ),
            IconButton(
              tooltip: 'المفضلة',
              icon: const Icon(Icons.star_border),
              onPressed: _isLoading ? null : _showFavoritesOnly,
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
        child: Text(
          _errorMessage!,
          style: TextStyle(fontSize: 16.sp, color: Colors.red.shade700),
        ),
      );
    }

    return Column(
      children: [
        _HadithSummaryBar(
          total: _allHadiths.length,
          visible: _filteredHadiths.length,
          favorites: _favoriteNumbers.length,
        ),
        Expanded(
          child: _filteredHadiths.isEmpty
              ? _EmptyHadithState(
                  onReset: () {
                    setState(() {
                      _searchController.clear();
                      _filteredHadiths = _allHadiths;
                    });
                  },
                )
              : ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 105.h),
                  itemCount: _filteredHadiths.length,
                  itemBuilder: (context, index) {
                    final hadith = _filteredHadiths[index];
                    return _HadithCard(
                      hadith: hadith,
                      isFavorite: _favoriteNumbers.contains(hadith.number),
                      onTap: () => _showHadithDetails(hadith),
                      onCopy: () => _copyHadith(hadith),
                      onFavorite: () => _toggleFavorite(hadith),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

class _HadithSummaryBar extends StatelessWidget {
  const _HadithSummaryBar({
    required this.total,
    required this.visible,
    required this.favorites,
  });

  final int total;
  final int visible;
  final int favorites;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 8.h),
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        children: [
          Icon(Icons.auto_stories_outlined, color: Colors.white, size: 22.sp),
          SizedBox(width: 10.w),
          Expanded(
            child: Text(
              'الأحاديث المتاحة: $visible من $total',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13.sp,
              ),
            ),
          ),
          Icon(Icons.star, color: Colors.amber.shade200, size: 18.sp),
          SizedBox(width: 4.w),
          Text(
            '$favorites',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _HadithCard extends StatelessWidget {
  const _HadithCard({
    required this.hadith,
    required this.isFavorite,
    required this.onTap,
    required this.onCopy,
    required this.onFavorite,
  });

  final HadithModel hadith;
  final bool isFavorite;
  final VoidCallback onTap;
  final VoidCallback onCopy;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Padding(
      padding: EdgeInsets.only(bottom: 10.h),
      child: Material(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8.r),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8.r),
          child: Container(
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(
                color: colorScheme.outline.withValues(alpha: 0.12),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _HadithNumber(number: hadith.number),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        'حديث رقم ${hadith.number}',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          color: colorScheme.primary,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'نسخ',
                      onPressed: onCopy,
                      icon: Icon(Icons.copy, size: 20.sp),
                      color: colorScheme.onSurfaceVariant,
                    ),
                    IconButton(
                      tooltip: 'المفضلة',
                      onPressed: onFavorite,
                      icon: Icon(
                        isFavorite ? Icons.star : Icons.star_border,
                        size: 21.sp,
                      ),
                      color: isFavorite
                          ? Colors.amber.shade700
                          : colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                SizedBox(height: 8.h),
                Text(
                  hadith.hadith,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.right,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    fontSize: 16.sp,
                    height: 1.7,
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w500,
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

class _HadithNumber extends StatelessWidget {
  const _HadithNumber({required this.number});

  final int number;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: 34.w,
      height: 34.w,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: colorScheme.primary.withValues(alpha: 0.1),
      ),
      child: Text(
        '$number',
        style: TextStyle(
          color: colorScheme.primary,
          fontSize: 11.sp,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

class _HadithDetailsSheet extends StatelessWidget {
  const _HadithDetailsSheet({
    required this.hadith,
    required this.isFavorite,
    required this.controller,
    required this.onCopy,
    required this.onFavorite,
  });

  final HadithModel hadith;
  final bool isFavorite;
  final ScrollController controller;
  final VoidCallback onCopy;
  final VoidCallback onFavorite;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(8.r)),
      ),
      child: ListView(
        controller: controller,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(18.w, 10.h, 18.w, 28.h),
        children: [
          Center(
            child: Container(
              width: 46.w,
              height: 4.h,
              decoration: BoxDecoration(
                color: colorScheme.outline.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(20.r),
              ),
            ),
          ),
          SizedBox(height: 18.h),
          Row(
            children: [
              _HadithNumber(number: hadith.number),
              SizedBox(width: 10.w),
              Expanded(
                child: Text(
                  'حديث رقم ${hadith.number}',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: colorScheme.primary,
                  ),
                ),
              ),
              IconButton(
                onPressed: onCopy,
                icon: const Icon(Icons.copy),
                tooltip: 'نسخ الحديث',
              ),
              IconButton(
                onPressed: onFavorite,
                icon: Icon(isFavorite ? Icons.star : Icons.star_border),
                color: isFavorite ? Colors.amber.shade700 : null,
                tooltip: 'المفضلة',
              ),
            ],
          ),
          SizedBox(height: 14.h),
          Text(
            hadith.hadith,
            textAlign: TextAlign.right,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontSize: 18.sp,
              height: 1.9,
              fontWeight: FontWeight.w500,
              color: colorScheme.onSurface,
            ),
          ),
          if (hadith.description.isNotEmpty) ...[
            SizedBox(height: 18.h),
            Container(
              padding: EdgeInsets.all(12.w),
              decoration: BoxDecoration(
                color: colorScheme.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Text(
                hadith.description,
                style: theme.textTheme.bodyMedium?.copyWith(
                  height: 1.6,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _EmptyHadithState extends StatelessWidget {
  const _EmptyHadithState({required this.onReset});

  final VoidCallback onReset;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: EdgeInsets.all(24.w),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.search_off,
              size: 46.sp,
              color: colorScheme.onSurfaceVariant,
            ),
            SizedBox(height: 10.h),
            Text(
              'لا توجد أحاديث مطابقة',
              style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w700),
            ),
            SizedBox(height: 6.h),
            TextButton(
              onPressed: onReset,
              child: const Text('عرض كل الأحاديث'),
            ),
          ],
        ),
      ),
    );
  }
}
