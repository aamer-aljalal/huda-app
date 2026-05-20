import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'package:tarteel/features/names_of_allah/models/name_model.dart';
import 'package:tarteel/features/names_of_allah/services/names_of_allah_service.dart';
import 'package:tarteel/features/names_of_allah/views/names_of_allah_detail_screen.dart';

class NamesOfAllahScreen extends StatefulWidget {
  const NamesOfAllahScreen({super.key});

  @override
  State<NamesOfAllahScreen> createState() => _NamesOfAllahScreenState();
}

class _NamesOfAllahScreenState extends State<NamesOfAllahScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<AllahName> _allNames = [];
  List<AllahName> _filteredNames = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadNames();
    _searchController.addListener(_filterNames);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadNames() async {
    try {
      final names = await NamesOfAllahService.loadNames();
      if (!mounted) return;
      setState(() {
        _allNames = names;
        _filteredNames = names;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'تعذر تحميل أسماء الله الحسنى';
        _isLoading = false;
      });
    }
  }

  void _filterNames() {
    final query = _searchController.text.trim().toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredNames = _allNames;
      } else {
        _filteredNames = _allNames.where((item) {
          return item.name.contains(query) ||
              item.text.contains(query) ||
              item.id.toString().contains(query);
        }).toList();
      }
    });
  }

  void _navigateToDetail(AllahName nameItem) {
    // Find the original index of the selected item in the unfiltered list
    final originalIndex = _allNames.indexOf(nameItem);
    if (originalIndex != -1) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => NamesOfAllahDetailScreen(
            names: _allNames,
            initialIndex: originalIndex,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: tarteelAppBar(
          titleText: 'أسماء الله الحسنى',
          showSearch: true,
          searchController: _searchController,
          searchHint: 'ابحث عن اسم من أسماء الله...',
          centerTitle: true,
          elevation: 0,
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(
            Theme.of(context).brightness == Brightness.dark
                ? AppColors.goldAccent
                : AppColors.primary,
          ),
        ),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Text(
          _errorMessage!,
          style: TextStyle(
            fontSize: 16.sp,
            color: Colors.red.shade700,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    if (_filteredNames.isEmpty) {
      return Center(
        child: Text(
          'لا توجد نتائج مطابقة لبحثك',
          style: TextStyle(
            fontSize: 16.sp,
            color: Colors.grey,
            fontWeight: FontWeight.bold,
          ),
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(16.w),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12.w,
        mainAxisSpacing: 12.h,
        childAspectRatio: 1.1,
      ),
      itemCount: _filteredNames.length,
      itemBuilder: (context, index) {
        final item = _filteredNames[index];
        return _NameGridTile(
          nameItem: item,
          onTap: () => _navigateToDetail(item),
        );
      },
    );
  }
}

class _NameGridTile extends StatelessWidget {
  final AllahName nameItem;
  final VoidCallback onTap;

  const _NameGridTile({
    required this.nameItem,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Material(
      color: isDark ? AppColors.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(16.r),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16.r),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.r),
            border: Border.all(
              color: isDark
                  ? AppColors.darkBorder
                  : AppColors.lightBorder,
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Stack(
            children: [
              // Beautiful ornamental ID Circle in the corner
              Positioned(
                top: 8.h,
                right: 8.w,
                child: Container(
                  width: 26.w,
                  height: 26.w,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDark
                        ? AppColors.goldAccent.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.05),
                    border: Border.all(
                      color: isDark
                          ? AppColors.goldAccent.withValues(alpha: 0.3)
                          : AppColors.primary.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    '${nameItem.id}',
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.goldAccent : AppColors.primary,
                    ),
                  ),
                ),
              ),

              // Centered name of Allah
              Center(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 16.h),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        nameItem.name,
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: isDark ? AppColors.goldAccent : AppColors.primary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        nameItem.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.sp,
                          color: isDark
                              ? AppColors.darkSecondaryText
                              : AppColors.lightSecondaryText,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
