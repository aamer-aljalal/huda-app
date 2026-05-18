import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:huda/core/theme/app_theme.dart';
import 'package:huda/core/widgets/Text/Auto_text.dart';
import 'dart:math' as math;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:huda/core/services/recent_actions_service.dart';

import 'package:huda/core/widgets/appbars/huda_app_bar.dart';
import 'package:huda/features/azkar/model/zekr_category.dart';

class AzkarDetailsScreen extends StatefulWidget {
  final ZekrCategory category;
  const AzkarDetailsScreen({super.key, required this.category});

  @override
  State<AzkarDetailsScreen> createState() => _AzkarDetailsScreenState();
}

class _AzkarDetailsScreenState extends State<AzkarDetailsScreen>
    with SingleTickerProviderStateMixin {
  double _buttonScale = 1.0;
  int currentZekrIndex = 0;
  get currentZekr => widget.category.azkar[currentZekrIndex];
  int get _totalRepeat => int.tryParse(currentZekr.count) ?? 1;
  double get _progress => currentZekr.currentCount / _totalRepeat;

  void _onCounterTap() {
    setState(() {
      if (currentZekr.currentCount < _totalRepeat) {
        currentZekr.currentCount++;
      }

      if (currentZekr.currentCount == _totalRepeat) {
        if (currentZekrIndex < widget.category.azkar.length - 1) {
          currentZekrIndex++;

          _pageController.animateToPage(
            currentZekrIndex,
            duration: const Duration(milliseconds: 400),
            curve: Curves.easeInOut,
          );
        }
      }

      _buttonScale = 0.92;
    });

    Future.delayed(const Duration(milliseconds: 120), () {
      if (mounted) {
        setState(() {
          _buttonScale = 1.0;
        });
      }
    });
  }

  void _onZoomIn() {}

  void _onZoomOut() {}

  void _onCopy() {}

  late final PageController _pageController;
  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _loadSavedIndex();
  }

  Future<void> _loadSavedIndex() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedIndex =
          prefs.getInt('zekr_index_${widget.category.title}') ?? 0;
      if (savedIndex > 0 && savedIndex < widget.category.azkar.length) {
        setState(() {
          currentZekrIndex = savedIndex;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (_pageController.hasClients) {
            _pageController.jumpToPage(savedIndex);
          }
        });
      }
    } catch (_) {}

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _saveRecentAzkarAction();
    });
  }

  Future<void> _saveRecentAzkarAction() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(
        'zekr_index_${widget.category.title}',
        currentZekrIndex,
      );
      await RecentActionsManager.addAction(
        category: 'azkar',
        title: widget.category.title,
        subtitle: 'ذكر ${currentZekrIndex + 1}/${widget.category.azkar.length}',
        extraData: {'category_title': widget.category.title},
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: HudaAppBar(titleText: widget.category.title, elevation: 0),

      body: Container(
        height: double.infinity,
        child: Column(
          children: [
            SizedBox(height: 24.h),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 18.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 300.h,
                      child: PageView.builder(
                        controller: _pageController,
                        itemCount: widget.category.azkar.length,

                        onPageChanged: (index) {
                          setState(() {
                            currentZekrIndex = index;
                          });
                          _saveRecentAzkarAction();
                        },

                        itemBuilder: (context, index) {
                          final zekr = widget.category.azkar[index];

                          return AnimatedPadding(
                            duration: const Duration(milliseconds: 200),
                            padding: EdgeInsets.symmetric(horizontal: 4.w),
                            child: _buildZekrCard(zekr),
                          );
                        },
                      ),
                    ),

                    SizedBox(height: 48.h),
                    _buildCounterButton(),
                    SizedBox(height: 24.h),
                    Text(
                      'اضغط على الزر)',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildZekrCard(dynamic zekr) {
    return Card(
      shadowColor: AppColors.darkSecondaryText.withOpacity(1),

      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20.r)),
      color: Colors.white,
      child: Padding(
        padding: EdgeInsets.all(15.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Top row: Zoom in / Zoom out buttons
            _textSoom(),

            Expanded(
              child: AutoText(
                content: zekr.content,
                color: const Color(0xFF2E5C2E),
              ),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildActionButton(
                  icon: Icons.copy,
                  onTap: _copyHadith,
                  color: Colors.blue,
                ),
                _buildActionButton(
                  icon: Icons.share,
                  onTap: _shareHadith,
                  color: Colors.green,
                ),

                SizedBox(width: 15.w),

                Container(
                  width: 120.w,
                  padding: EdgeInsets.symmetric(vertical: 6.h),
                  decoration: BoxDecoration(
                    color: const Color(0xFF4A6A4A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12.r),
                  ),

                  child: AutoText(
                    content:
                        'التكرار: ${int.tryParse(zekr.count) ?? 0} / ${zekr.currentCount}',
                    color: Color(0xFF4A6A4A),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _textSoom() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 100.w,
          alignment: Alignment.topRight,
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: const Color(0xFF4A6A4A).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _iconSoom(Icons.zoom_in, _onZoomIn, 'تكبير'),
              _iconSoom(Icons.zoom_out, _onZoomOut, 'تصغير'),
            ],
          ),
        ),
      ],
    );
  }

  IconButton _iconSoom(IconData? icon, VoidCallback? onTap, String? content) {
    return IconButton(
      icon: Icon(icon, size: 28.sp),
      onPressed: onTap,
      tooltip: content,
      splashRadius: 24,
      color: Colors.grey.shade700,
    );
  }

  void _copyHadith() {
    _showMessage('تم نسخ الحديث (تجريبي)');
  }

  void _shareHadith() {
    _showMessage('تم فتح المشاركة (تجريبي)');
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(milliseconds: 800)),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required VoidCallback onTap,
    required Color color,
  }) {
    return Column(
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(40.r),
          child: Container(
            padding: EdgeInsets.all(12.w),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 20.sp),
          ),
        ),
        // SizedBox(height: 6.h),
        // Text(
        //   label,
        //   style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700),
        // ),
      ],
    );
  }

  Widget _buildCounterButton() {
    return GestureDetector(
      onTap: _onCounterTap,
      child: AnimatedScale(
        scale: _buttonScale,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOutBack,
        child: SizedBox(
          width: 140.w,
          height: 140.h,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 140.w,
                height: 140.h,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.green.shade200,
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
              ),
              CustomPaint(
                size: const Size(140, 140),
                painter: CircularProgressPainter(
                  progress: _progress,
                  strokeWidth: 8.0,
                  backgroundColor: Colors.grey.shade300,
                  progressColor: Colors.green.shade600,
                ),
              ),
              // Center content: current count
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.touch_app, size: 20.sp, color: Color(0xFF2E7D32)),
                  SizedBox(height: 8.h),
                  Text(
                    '${currentZekr.currentCount}',
                    style: TextStyle(
                      fontSize: 44.sp,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2E7D32),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Custom painter that draws a circular progress arc around the button.
/// Starts at top (12 o'clock) and sweeps clockwise.
class CircularProgressPainter extends CustomPainter {
  final double progress; // 0.0 to 1.0
  final double strokeWidth;
  final Color backgroundColor;
  final Color progressColor;

  CircularProgressPainter({
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
    required this.progressColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;
    final rect = Rect.fromCircle(center: center, radius: radius);

    // Background circle (full track)
    final backgroundPaint = Paint()
      ..color = backgroundColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(center, radius, backgroundPaint);

    // Progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    // Start from top (-π/2) and sweep clockwise
    final startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * progress.clamp(0.0, 1.0);

    canvas.drawArc(rect, startAngle, sweepAngle, false, progressPaint);
  }

  @override
  bool shouldRepaint(covariant CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.progressColor != progressColor;
  }
}
