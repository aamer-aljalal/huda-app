import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/theme/app_colors.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'package:tarteel/features/names_of_allah/models/name_model.dart';

class NamesOfAllahDetailScreen extends StatefulWidget {
  final List<AllahName> names;
  final int initialIndex;

  const NamesOfAllahDetailScreen({
    super.key,
    required this.names,
    required this.initialIndex,
  });

  @override
  State<NamesOfAllahDetailScreen> createState() =>
      _NamesOfAllahDetailScreenState();
}

class _NamesOfAllahDetailScreenState extends State<NamesOfAllahDetailScreen> {
  late PageController _pageController;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _pageController = PageController(initialPage: widget.initialIndex);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _copyToClipboard(AllahName item) {
    Clipboard.setData(ClipboardData(text: '${item.name}: ${item.text}'));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'تم نسخ الاسم والوصف بنجاح',
          style: TextStyle(fontFamily: 'Cairo'),
          textAlign: TextAlign.center,
        ),
        backgroundColor: AppColors.primary,
        duration: const Duration(seconds: 2),
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
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: tarteelAppBar(
          titleText: 'أسماء الله الحسنى',
          centerTitle: true,
          elevation: 0,
        ),
        body: SafeArea(
          child: Column(
            children: [
              // Progress Indicator / Counter
              Padding(
                padding: EdgeInsets.only(top: 16.h, bottom: 8.h),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: (isDark
                        ? AppColors.darkSurface
                        : AppColors.lightSurface),
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isDark
                          ? AppColors.darkBorder
                          : AppColors.lightBorder,
                    ),
                  ),
                  child: Text(
                    '${_currentIndex + 1} من ${widget.names.length}',
                    style: TextStyle(
                      fontSize: 14.sp,
                      fontWeight: FontWeight.bold,
                      color: isDark ? AppColors.goldAccent : AppColors.primary,
                    ),
                  ),
                ),
              ),

              // Swipeable Card Area
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (index) {
                    setState(() {
                      _currentIndex = index;
                    });
                  },
                  itemCount: widget.names.length,
                  itemBuilder: (context, index) {
                    final item = widget.names[index];
                    return AnimatedBuilder(
                      animation: _pageController,
                      builder: (context, child) {
                        double value = 1.0;
                        if (_pageController.position.haveDimensions) {
                          value = _pageController.page! - index;
                          value = (1 - (value.abs() * 0.15)).clamp(0.0, 1.0);
                        }
                        return Center(
                          child: SizedBox(
                            height: 480.h,
                            child: Transform.scale(scale: value, child: child),
                          ),
                        );
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20.w),
                        child: Card(
                          elevation: 6,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(24.r),
                            side: BorderSide(
                              color: isDark
                                  ? AppColors.goldAccent.withValues(alpha: 0.2)
                                  : AppColors.primary.withValues(alpha: 0.1),
                              width: 1.5,
                            ),
                          ),
                          color: isDark ? AppColors.darkSurface : Colors.white,
                          child: Padding(
                            padding: EdgeInsets.all(24.w),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                // Circular Badge containing the beautiful Name
                                Container(
                                  width: 130.w,
                                  height: 130.w,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: isDark
                                          ? [
                                              AppColors.secondary,
                                              AppColors.primary,
                                            ]
                                          : [
                                              AppColors.primary,
                                              AppColors.primaryLight,
                                            ],
                                      begin: Alignment.topRight,
                                      end: Alignment.bottomLeft,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: AppColors.primary.withValues(
                                          alpha: 0.2,
                                        ),
                                        blurRadius: 10,
                                        offset: const Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Text(
                                    item.name,
                                    style: TextStyle(
                                      fontSize: 34.sp,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? AppColors.goldAccent
                                          : Colors.white,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                                SizedBox(height: 32.h),

                                // Meaning & Details Section
                                Expanded(
                                  child: SingleChildScrollView(
                                    physics: const BouncingScrollPhysics(),
                                    child: Column(
                                      children: [
                                        Text(
                                          'التفسير والمعنى:',
                                          style: TextStyle(
                                            fontSize: 16.sp,
                                            fontWeight: FontWeight.bold,
                                            color: isDark
                                                ? AppColors.goldAccent
                                                : AppColors.primary,
                                          ),
                                        ),
                                        SizedBox(height: 12.h),
                                        Text(
                                          item.text,
                                          style: TextStyle(
                                            fontSize: 18.sp,
                                            fontWeight: FontWeight.w500,
                                            height: 1.7.h,
                                            color: isDark
                                                ? Colors.white70
                                                : AppColors.lightPrimaryText,
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
                      ),
                    );
                  },
                ),
              ),

              // Bottom Actions Panel
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Previous Button
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back_ios_rounded,
                        color: _currentIndex > 0
                            ? (isDark
                                  ? AppColors.goldAccent
                                  : AppColors.primary)
                            : Colors.grey,
                      ),
                      onPressed: _currentIndex > 0
                          ? () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          : null,
                      tooltip: 'السابق',
                    ),

                    // Copy / Share Button
                    ElevatedButton.icon(
                      onPressed: () =>
                          _copyToClipboard(widget.names[_currentIndex]),
                      icon: const Icon(Icons.copy_rounded),
                      label: const Text(
                        'نسخ الاسم والوصف',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: isDark
                            ? AppColors.darkBackground
                            : Colors.white,
                        backgroundColor: isDark
                            ? AppColors.goldAccent
                            : AppColors.primary,
                        padding: EdgeInsets.symmetric(
                          horizontal: 24.w,
                          vertical: 12.h,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30.r),
                        ),
                      ),
                    ),

                    // Next Button
                    IconButton(
                      icon: Icon(
                        Icons.arrow_forward_ios_rounded,
                        color: _currentIndex < widget.names.length - 1
                            ? (isDark
                                  ? AppColors.goldAccent
                                  : AppColors.primary)
                            : Colors.grey,
                      ),
                      onPressed: _currentIndex < widget.names.length - 1
                          ? () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          : null,
                      tooltip: 'التالي',
                    ),
                  ],
                ),
              ),

              // Swipe Guide Hint
              Padding(
                padding: EdgeInsets.only(bottom: 16.h),
                child: Text(
                  'اسحب لليمين أو اليسار للتنقل بين الأسماء',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: isDark ? Colors.white38 : Colors.grey.shade500,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
