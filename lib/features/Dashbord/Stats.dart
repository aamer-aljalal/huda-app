import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
// import 'dart:math' as math;

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Static dummy data for each tab (UI only)
  final Map<String, StatsData> _statsData = {
    'اليوم': StatsData(azkar: 42, readingPages: 3, khatma: 0, progress: 0.12),
    'الأسبوع': StatsData(
      azkar: 287,
      readingPages: 21,
      khatma: 0,
      progress: 0.35,
    ),
    'الشهر': StatsData(
      azkar: 1150,
      readingPages: 87,
      khatma: 1,
      progress: 0.68,
    ),
    'السنة': StatsData(
      azkar: 12480,
      readingPages: 945,
      khatma: 12,
      progress: 0.82,
    ),
  };

  // For chart animation (visual only)
  double _chartAnimationValue = 0.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    // Simulate chart load animation
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _chartAnimationValue = 1.0;
        });
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F0),
      appBar: AppBar(
        title: Text(
          'الإحصائيات',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      
      body: Column(
        children: [
          // Tabs
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(40.r),
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.shade200,
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: Colors.green.shade600,
                borderRadius: BorderRadius.circular(40.r),
              ),
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey.shade700,
              dividerColor: Colors.transparent,
              tabs: [
                Tab(text: 'اليوم'),
                Tab(text: 'الأسبوع'),
                Tab(text: 'الشهر'),
                Tab(text: 'السنة'),
              ],
            ),
          ),
          // Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildStatsContent(_statsData['اليوم']!),
                _buildStatsContent(_statsData['الأسبوع']!),
                _buildStatsContent(_statsData['الشهر']!),
                _buildStatsContent(_statsData['السنة']!),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsContent(StatsData data) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(20.w),
      child: Column(
        children: [
          // Stats cards row
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'الأذكار',
                  data.azkar,
                  Icons.bookmark,
                  Colors.green,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildStatCard(
                  'القراءة (صفحة)',
                  data.readingPages,
                  Icons.menu_book,
                  Colors.blue,
                ),
              ),
              SizedBox(width: 16.w),
              Expanded(
                child: _buildStatCard(
                  'الختمات',
                  data.khatma,
                  Icons.star,
                  Colors.amber,
                ),
              ),
            ],
          ),
          SizedBox(height: 24.h),

          // Progress section
          _buildProgressSection(data.progress),
          SizedBox(height: 24.h),

          // Chart (visual only)
          _buildChart(),
          SizedBox(height: 16.h),

          // Tap hint
          Text(
            '👆 اضغط على أي بطاقة لرؤية التفاصيل (تأثير بصري فقط)',
            style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
    String title,
    int value,
    IconData icon,
    MaterialColor color,
  ) {
    return GestureDetector(
      onTap: () {
        // Visual only: show dummy dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text('إجمالي $title: $value\n(هذا عرض تجريبي فقط)'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('إغلاق'),
              ),
            ],
          ),
        );
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 12.w),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24.r),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 36.sp, color: color.shade600),
            SizedBox(height: 12.h),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.0, end: value.toDouble()),
              duration: const Duration(milliseconds: 800),
              curve: Curves.easeOutCubic,
              builder: (context, animatedValue, child) {
                return Text(
                  animatedValue.toInt().toString(),
                  style: TextStyle(
                    fontSize: 28.sp,
                    fontWeight: FontWeight.bold,
                    color: color.shade800,
                  ),
                );
              },
            ),
            SizedBox(height: 8.h),
            Text(
              title,
              style: TextStyle(fontSize: 14.sp, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressSection(double progress) {
    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'التقدم العام',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
              Text(
                '${(progress * 100).toInt()}%',
                style: TextStyle(
                  fontSize: 18.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade800,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(12.r),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 12,
              backgroundColor: Colors.green.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.green.shade600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChart() {
    // Dummy data for 7 days
    final List<double> dailyValues = [0.3, 0.45, 0.5, 0.7, 0.65, 0.8, 0.9];
    final List<String> days = ['س', 'م', 'ت', 'أ', 'خ', 'ج', 'س'];

    return Container(
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.show_chart, size: 24.sp, color: Colors.green.shade700),
              SizedBox(width: 8.w),
              Text(
                'النشاط اليومي',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade700,
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          SizedBox(
            height: 160.h,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (index) {
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 500),
                        curve: Curves.easeOutCubic,
                        height: 120.h * dailyValues[index] * _chartAnimationValue,
                        width: 30.w,
                        decoration: BoxDecoration(
                          color: Colors.green.shade400,
                          borderRadius: BorderRadius.circular(12.r),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.green.shade200,
                              blurRadius: 4,
                              offset: const Offset(0, -2),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        days[index],
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

/// Simple data class for static stats
class StatsData {
  final int azkar;
  final int readingPages;
  final int khatma;
  final double progress;

  StatsData({
    required this.azkar,
    required this.readingPages,
    required this.khatma,
    required this.progress,
  });
}
