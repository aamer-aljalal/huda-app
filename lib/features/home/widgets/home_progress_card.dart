import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:huda/Routes/AppRoutes.dart';
import 'package:huda/core/theme/app_colors.dart';

class HomeProgressCard extends StatefulWidget {
  const HomeProgressCard({super.key});

  @override
  State<HomeProgressCard> createState() => _HomeProgressCardState();
}

class _HomeProgressCardState extends State<HomeProgressCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _adhkarAnimation;
  late Animation<double> _readingAnimation;

  int adhkarCount = 120;
  int adhkarTarget = 300;
  int pagesRead = 5;
  int pagesTarget = 20;

  double get adhkarProgress => adhkarCount / adhkarTarget;
  double get readingProgress => pagesRead / pagesTarget;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _adhkarAnimation = Tween<double>(begin: 0, end: adhkarProgress).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );

    _readingAnimation = Tween<double>(begin: 0, end: readingProgress).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final brightness = MediaQuery.platformBrightnessOf(context);

    return Card(
      margin: EdgeInsets.zero,
      child: InkWell(
        onTap: () {
          Navigator.pushNamed(context, AppRoutes.stats);
        },

        borderRadius: BorderRadius.circular(24.r),
        child: Padding(
          padding: EdgeInsets.all(20.w),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8.w),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A6B58).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16.r),
                    ),
                    child: Icon(
                      Icons.bar_chart_rounded,
                      color: Color(0xFF1A6B58),
                      size: 28.sp,
                    ),
                  ),

                  SizedBox(width: 12.w),
                  Text(
                    'إنجازات اليوم',
                    style: TextStyle(
                      fontSize: 18.sp,
                      fontWeight: FontWeight.bold,
                      color: brightness == Brightness.dark
                          ? AppColors.white
                          : AppColors.primary,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 20.h),
              // الأذكار
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.auto_awesome,
                        size: 18.sp,
                        color: Color(0xFF4CAF50),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'الأذكار',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$adhkarCount / $adhkarTarget',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF4CAF50),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              AnimatedBuilder(
                animation: _adhkarAnimation,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: _adhkarAnimation.value,
                    backgroundColor: Colors.grey.shade100,
                    color: const Color(0xFF4CAF50),
                    borderRadius: BorderRadius.circular(12.r),
                    minHeight: 10,
                  );
                },
              ),
              SizedBox(height: 18.h),
              // القراءة
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.menu_book,
                        size: 18.sp,
                        color: Color(0xFF2196F3),
                      ),
                      SizedBox(width: 6.w),
                      Text(
                        'قراءة القرآن',
                        style: TextStyle(
                          fontSize: 14.sp,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '$pagesRead صفحات / $pagesTarget',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2196F3),
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8.h),
              AnimatedBuilder(
                animation: _readingAnimation,
                builder: (context, child) {
                  return LinearProgressIndicator(
                    value: _readingAnimation.value,
                    backgroundColor: Colors.grey.shade100,
                    color: const Color(0xFF2196F3),
                    borderRadius: BorderRadius.circular(12.r),
                    minHeight: 10,
                  );
                },
              ),
              SizedBox(height: 16.h),
              Center(
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 12.w,
                    vertical: 6.h,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A6B58).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20.r),
                  ),
                  child: AnimatedBuilder(
                    animation: _adhkarAnimation,
                    builder: (context, child) {
                      final totalProgress =
                          (_adhkarAnimation.value + _readingAnimation.value) /
                          2;
                      return Text(
                        '${(totalProgress * 100).toInt()}% إنجاز إجمالي',
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF1A6B58),
                        ),
                      );
                    },
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
