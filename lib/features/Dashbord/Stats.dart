import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:huda/core/widgets/appbars/huda_app_bar.dart';
import 'package:huda/core/services/stats_service.dart';
import 'package:huda/core/widgets/Text/Responsive_text.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  Map<String, DynamicStats> _statsData = {};
  List<String> _chartLabels = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _loadStats();
  }

  Future<void> _loadStats() async {
    try {
      final data = await StatsService.getFullStats();
      final labels = StatsService.getLast7DaysLabels();
      if (mounted) {
        setState(() {
          _statsData = data;
          _chartLabels = labels;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
        appBar: const HudaAppBar(
          titleText: 'الإحصائيات والنشاط',
          elevation: 0,
          toolbarHeight: 90,
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(),
              )
            : _statsData.isEmpty
                ? const Center(
                    child: ResponsiveText(
                      content: 'لا توجد بيانات إحصائية متوفرة حالياً',
                      fontSize: 14,
                      fontWeight: FontWeight.normal,
                      fontFamily: 'Cairo',
                    ),
                  )
                : Column(
                    children: [
                      _StatsTabs(controller: _tabController, tabs: _statsData.keys),
                      Expanded(
                        child: TabBarView(
                          controller: _tabController,
                          children: _statsData.values.map((data) {
                            return _StatsContent(
                              data: data,
                              chartLabels: _chartLabels,
                            );
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
        labelStyle: TextStyle(fontSize: 12.sp, fontWeight: FontWeight.w700, fontFamily: 'Cairo'),
        unselectedLabelStyle: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w600,
          fontFamily: 'Cairo',
        ),
        tabs: tabs.map((label) => Tab(text: label)).toList(),
      ),
    );
  }
}

class _StatsContent extends StatelessWidget {
  const _StatsContent({required this.data, required this.chartLabels});

  final DynamicStats data;
  final List<String> chartLabels;

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
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'أدعية حصن المسلم',
                value: data.hisnAlmuslim.toString(),
                icon: Icons.shield_outlined,
                color: const Color(0xFFD32F2F),
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: _MetricCard(
                title: 'الأحاديث المقروءة',
                value: data.hadith.toString(),
                icon: Icons.auto_stories_rounded,
                color: Colors.orange.shade700,
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                title: 'قصص الأنبياء المقروءة',
                value: data.prophetsStories.toString(),
                icon: Icons.import_contacts_outlined,
                color: Colors.teal.shade700,
              ),
            ),
          ],
        ),
        SizedBox(height: 14.h),
        // Detailed Hisn al-Muslim & Azkar Stats Card
        if (data.azkar > 0 || data.hisnAlmuslim > 0 || data.completedAzkarSingle > 0 || data.completedAzkarCategory > 0) ...[
          Container(
            padding: EdgeInsets.all(16.w),
            margin: EdgeInsets.only(bottom: 14.h),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.12)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.shield_outlined, color: const Color(0xFF1A8C6E), size: 22.sp),
                    SizedBox(width: 8.w),
                    ResponsiveText(
                      content: 'نشاط الأذكار وحصن المسلم 🛡️',
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'Cairo',
                    ),
                  ],
                ),
                SizedBox(height: 14.h),
                Row(
                  children: [
                    Expanded(
                      child: _SubMetricCard(
                        title: 'تكرار الأذكار',
                        value: data.azkar.toString(),
                        color: const Color(0xFF1A8C6E),
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: _SubMetricCard(
                        title: 'تكرار حصن المسلم',
                        value: data.hisnAlmuslim.toString(),
                        color: const Color(0xFFD32F2F),
                      ),
                    ),
                  ],
                ),
                if (data.completedAzkarSingle > 0 || data.completedAzkarCategory > 0) ...[
                  SizedBox(height: 10.h),
                  Row(
                    children: [
                      if (data.completedAzkarSingle > 0)
                        Expanded(
                          child: _SubMetricCard(
                            title: 'أذكار مكتملة',
                            value: data.completedAzkarSingle.toString(),
                            color: Colors.amber.shade700,
                          ),
                        ),
                    ],
                  ),
                  if (data.completedAzkarCategory > 0) ...[
                    SizedBox(height: 10.h),
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A8C6E).withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8.r),
                        border: Border.all(color: const Color(0xFF1A8C6E).withValues(alpha: 0.15)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.check_circle_outline_rounded, color: const Color(0xFF1A8C6E), size: 18.sp),
                          SizedBox(width: 8.w),
                          Expanded(
                            child: ResponsiveText(
                              content: 'أتممت قراءة أقسام أذكار كاملة: ${data.completedAzkarCategory} مرّة',
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Cairo',
                              color: const Color(0xFF1A8C6E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
        _ChartCard(
          values: data.chartValues,
          labels: chartLabels,
        ),
        SizedBox(height: 105.h),
      ],
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.data});

  final DynamicStats data;

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
                child: ResponsiveText(
                  content: 'ملخص نشاطك الإيماني',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'Cairo',
                  color: Colors.white,
                ),
              ),
              Text(
                '$percent%',
                style: theme.textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 22.sp,
                  fontFamily: 'Cairo',
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
                color: Colors.amberAccent,
                size: 20.sp,
              ),
              SizedBox(width: 6.w),
              ResponsiveText(
                content: 'سلسلة الالتزام: ${data.streak} أيام متتالية',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                fontFamily: 'Cairo',
                color: Colors.white.withOpacity(0.9),
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
      padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
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
                    fontFamily: 'Cairo',
                  ),
                ),
                SizedBox(height: 2.h),
                ResponsiveText(
                  content: title,
                  maxLines: 1,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'Cairo',
                  color: colorScheme.onSurfaceVariant,
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
  const _ChartCard({required this.values, required this.labels});

  final List<double> values;
  final List<String> labels;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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
              ResponsiveText(
                content: 'النشاط الإجمالي خلال آخر 7 أيام',
                fontSize: 15,
                fontWeight: FontWeight.w800,
                fontFamily: 'Cairo',
                color: colorScheme.onSurface,
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
                        index < labels.length ? labels[index] : '',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'Cairo',
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

class _SubMetricCard extends StatelessWidget {
  const _SubMetricCard({
    required this.title,
    required this.value,
    required this.color,
  });

  final String title;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 10.h),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.08)),
      ),
      child: Row(
        children: [
          Container(
            width: 30.w,
            height: 30.w,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              color == const Color(0xFF1A8C6E) ? Icons.done_all_rounded : Icons.check_circle_outline_rounded,
              color: color,
              size: 16.sp,
            ),
          ),
          SizedBox(width: 8.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w900,
                    fontSize: 16.sp,
                    fontFamily: 'Cairo',
                  ),
                ),
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 9.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'Cairo',
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
