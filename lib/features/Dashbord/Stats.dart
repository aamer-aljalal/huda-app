import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/widgets/appbars/huda_app_bar.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  final Map<String, StatsData> _statsData = {
    'اليوم': const StatsData(
      azkar: 42,
      readingPages: 3,
      tasbeeh: 120,
      khatma: 0,
      progress: 0.38,
      streak: 4,
      chartValues: [0.2, 0.5, 0.35, 0.7, 0.6, 0.85, 0.45],
    ),
    'الأسبوع': const StatsData(
      azkar: 287,
      readingPages: 21,
      tasbeeh: 760,
      khatma: 0,
      progress: 0.56,
      streak: 6,
      chartValues: [0.4, 0.55, 0.62, 0.48, 0.78, 0.66, 0.9],
    ),
    'الشهر': const StatsData(
      azkar: 1150,
      readingPages: 87,
      tasbeeh: 3240,
      khatma: 1,
      progress: 0.71,
      streak: 18,
      chartValues: [0.5, 0.64, 0.58, 0.72, 0.81, 0.76, 0.92],
    ),
    'السنة': const StatsData(
      azkar: 12480,
      readingPages: 945,
      tasbeeh: 35100,
      khatma: 12,
      progress: 0.82,
      streak: 41,
      chartValues: [0.52, 0.6, 0.7, 0.68, 0.78, 0.83, 0.88],
    ),
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _statsData.length, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: const HudaAppBar(titleText: 'الإحصائيات', elevation: 0),
        body: Column(
          children: [
            _StatsTabs(controller: _tabController, tabs: _statsData.keys),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: _statsData.values.map((data) {
                  return _StatsContent(data: data);
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsTabs extends StatelessWidget {
  const _StatsTabs({required this.controller, required this.tabs});

  final TabController controller;
  final Iterable<String> tabs;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      margin: EdgeInsets.fromLTRB(16.w, 14.h, 16.w, 4.h),
      padding: EdgeInsets.all(4.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: TabBar(
        controller: controller,
        indicatorSize: TabBarIndicatorSize.tab,
        indicator: BoxDecoration(
          color: colorScheme.primary,
          borderRadius: BorderRadius.circular(7.r),
        ),
        labelColor: Colors.white,
        unselectedLabelColor: colorScheme.onSurfaceVariant,
        dividerColor: Colors.transparent,
        labelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700),
        unselectedLabelStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
        ),
        tabs: tabs.map((label) => Tab(text: label)).toList(),
      ),
    );
  }
}

class _StatsContent extends StatelessWidget {
  const _StatsContent({required this.data});

  final StatsData data;

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(16.w),
      children: [
        _OverviewCard(data: data),
        SizedBox(height: 14.h),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          crossAxisSpacing: 10.w,
          mainAxisSpacing: 10.h,
          childAspectRatio: 1.55,
          children: [
            _MetricCard(
              title: 'الأذكار',
              value: data.azkar.toString(),
              icon: Icons.bookmark_border,
              color: const Color(0xFF1A8C6E),
            ),
            _MetricCard(
              title: 'صفحات القرآن',
              value: data.readingPages.toString(),
              icon: Icons.menu_book_outlined,
              color: const Color(0xFF3D6FB6),
            ),
            _MetricCard(
              title: 'التسبيح',
              value: data.tasbeeh.toString(),
              icon: Icons.radio_button_checked,
              color: const Color(0xFF8B6FC6),
            ),
            _MetricCard(
              title: 'الختمات',
              value: data.khatma.toString(),
              icon: Icons.workspace_premium_outlined,
              color: const Color(0xFFB7791F),
            ),
          ],
        ),
        SizedBox(height: 14.h),
        _ChartCard(values: data.chartValues),
        SizedBox(height: 105.h),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.data});

  final StatsData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final percent = (data.progress * 100).round();

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colorScheme.primary,
        borderRadius: BorderRadius.circular(8.r),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.12),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_outlined, color: Colors.white, size: 24.sp),
              SizedBox(width: 8.w),
              Expanded(
                child: Text(
                  'ملخص نشاطك',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16.sp,
                  ),
                ),
              ),
              Text(
                '$percent%',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(20.r),
            child: LinearProgressIndicator(
              value: data.progress,
              minHeight: 9.h,
              backgroundColor: Colors.white.withValues(alpha: 0.22),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            children: [
              Icon(
                Icons.local_fire_department_outlined,
                color: Colors.white,
                size: 20.sp,
              ),
              SizedBox(width: 6.w),
              Text(
                'سلسلة الالتزام: ${data.streak} أيام',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.9),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(12.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Row(
        children: [
          Container(
            width: 38.w,
            height: 38.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 21.sp),
          ),
          SizedBox(width: 10.w),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 20.sp,
                  ),
                ),
                SizedBox(height: 2.h),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 11.sp,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  const _ChartCard({required this.values});

  final List<double> values;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final days = ['س', 'ح', 'ن', 'ث', 'ر', 'خ', 'ج'];

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart, color: colorScheme.primary, size: 22.sp),
              SizedBox(width: 8.w),
              Text(
                'النشاط خلال الفترة',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  fontSize: 15.sp,
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          SizedBox(
            height: 150.h,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(values.length, (index) {
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: values[index]),
                        duration: Duration(milliseconds: 500 + index * 70),
                        curve: Curves.easeOutCubic,
                        builder: (context, value, child) {
                          return Container(
                            width: 24.w,
                            height: 112.h * value,
                            decoration: BoxDecoration(
                              color: colorScheme.primary,
                              borderRadius: BorderRadius.circular(6.r),
                            ),
                          );
                        },
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        days[index],
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
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

class StatsData {
  const StatsData({
    required this.azkar,
    required this.readingPages,
    required this.tasbeeh,
    required this.khatma,
    required this.progress,
    required this.streak,
    required this.chartValues,
  });

  final int azkar;
  final int readingPages;
  final int tasbeeh;
  final int khatma;
  final double progress;
  final int streak;
  final List<double> chartValues;
}
