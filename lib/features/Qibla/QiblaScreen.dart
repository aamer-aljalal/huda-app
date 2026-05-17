import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:ui' as ui;

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen>
    with SingleTickerProviderStateMixin {
  static const double _qiblaAngle = 135.0; // درجة افتراضية
  static const String _location = 'صنعاء، اليمن';
  static const String _accuracy = 'دقيق جداً';

  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
    );
    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.easeOutCubic,
          ),
        );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(32.r),
        ),
        backgroundColor: Colors.white.withOpacity(0.9),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
          child: Container(
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(32.r),
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, const Color(0xFFF0F7F0)],
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: EdgeInsets.all(12.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        Theme.of(context).colorScheme.primary,
                        Theme.of(context).colorScheme.secondary,
                      ],
                    ),
                  ),
                  child: Icon(Icons.explore, color: Colors.white, size: 28.sp),
                ),
                SizedBox(height: 20.h),
                Text(
                  'كيف تستخدم البوصلة؟',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                SizedBox(height: 16.h),
                Text(
                  '• حرك هاتفك بشكل الرقم 8 لمعايرة البوصلة.\n'
                  '• السهم الأخضر يشير إلى اتجاه القبلة.\n'
                  '• تأكد من إبعاد الهاتف عن المعادن.',
                  style: TextStyle(fontSize: 16.sp, height: 1.5.h),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 24.h),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30.r),
                    ),
                    padding: EdgeInsets.symmetric(
                      horizontal: 32.w,
                      vertical: 14.h,
                    ),
                  ),
                  child: Text('فهمت', style: TextStyle(fontSize: 18.sp)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text(
          'اتجاه القبلة',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22.sp),
        ),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: colorScheme.onPrimary,
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                colorScheme.primary,
                colorScheme.secondary.withOpacity(0.8),
              ],
            ),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline_rounded),
            onPressed: () => _showHelpDialog(context),
            tooltip: 'مساعدة',
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.topCenter,
            radius: 1.5,
            colors: [
              colorScheme.secondary.withOpacity(0.15),
              colorScheme.primary.withOpacity(0.05),
              Colors.white,
            ],
          ),
        ),
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: SlideTransition(
            position: _slideAnimation,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(top: 120, bottom: 40),
              child: Column(
                children: [
                  // بطاقة البوصلة الرئيسية
                  _buildCompassCard(context),
                  SizedBox(height: 30.h),
                  // بطاقة المعلومات (الزاوية والحالة)
                  _buildInfoCard(context),
                  SizedBox(height: 20.h),
                  // رسالة المعايرة
                  _buildCalibrationChip(context),
                  SizedBox(height: 20.h),
                  // بطاقة الموقع
                  _buildLocationCard(context),
                  SizedBox(height: 30.h),
                  // ملاحظة تجريبية
                  _buildDemoNote(context),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // محاكاة معايرة
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('جاري معايرة البوصلة...'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30.r),
              ),
              backgroundColor: colorScheme.primary,
            ),
          );
        },
        icon: Icon(Icons.refresh_rounded),
        label: Text('معايرة'),
        backgroundColor: colorScheme.secondary,
        foregroundColor: colorScheme.onSecondary,
      ),
    );
  }

  Widget _buildCompassCard(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.8, end: 1.0),
      duration: const Duration(milliseconds: 800),
      curve: Curves.elasticOut,
      builder: (context, scale, child) {
        return Transform.scale(scale: scale, child: child);
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 20.w),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(50.r),
          boxShadow: [
            BoxShadow(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
              blurRadius: 30,
              spreadRadius: 5,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
              blurRadius: 20,
              spreadRadius: -5,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(50.r),
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              padding: EdgeInsets.all(20.w),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.7),
                    Colors.white.withOpacity(0.4),
                  ],
                ),
                borderRadius: BorderRadius.circular(50.r),
                border: Border.all(
                  color: Colors.white.withOpacity(0.5),
                  width: 1.5.w,
                ),
              ),
              child: SizedBox(
                width: 320.w,
                height: 320.h,
                child: LegendaryCompass(qiblaAngle: _qiblaAngle),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      child: GlassCard(
        borderRadius: 40,
        padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 28.w),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'اتجاه القبلة',
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        '${_qiblaAngle.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 42.sp,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                          shadows: [
                            Shadow(
                              color: colorScheme.secondary.withOpacity(0.3),
                              offset: const Offset(2, 2),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 4.w),
                      Text(
                        '°',
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.bold,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Container(
              width: 1.5.w,
              height: 55.h,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.transparent,
                    colorScheme.secondary,
                    Colors.transparent,
                  ],
                ),
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'الحالة',
                    style: TextStyle(
                      fontSize: 15.sp,
                      color: colorScheme.onSurface.withOpacity(0.7),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 8.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 16.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          colorScheme.primary.withOpacity(0.2),
                          colorScheme.secondary.withOpacity(0.2),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(30.r),
                      border: Border.all(
                        color: colorScheme.primary.withOpacity(0.3),
                        width: 1.w,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.check_circle_rounded,
                          size: 18.sp,
                          color: colorScheme.primary,
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          _accuracy,
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalibrationChip(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 24.w),
      child: GlassCard(
        borderRadius: 40,
        padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 14.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(6.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [Colors.amber.shade400, Colors.amber.shade700],
                ),
              ),
              child: Icon(
                Icons.sensors_rounded,
                size: 20.sp,
                color: Colors.white,
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              'حرك الهاتف بشكل الرقم 8 للمعايرة',
              style: TextStyle(
                fontSize: 15.sp,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24.w),
      child: GlassCard(
        borderRadius: 40,
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 16.h),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(8.w),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: colorScheme.primary.withOpacity(0.1),
              ),
              child: Icon(
                Icons.location_on_rounded,
                color: colorScheme.primary,
                size: 24.sp,
              ),
            ),
            SizedBox(width: 12.w),
            Text(
              _location,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.w600,
                color: colorScheme.onSurface,
              ),
            ),
            SizedBox(width: 8.w),
            Icon(
              Icons.verified_rounded,
              size: 20.sp,
              color: colorScheme.secondary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDemoNote(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 40.w),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(30.r),
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
          width: 1.w,
        ),
      ),
      child: Text(
        '⚠️ هذا العرض تجريبي — لا توجد بوصلة حقيقية',
        style: TextStyle(
          fontSize: 13.sp,
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          fontWeight: FontWeight.w500,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}

/// بطاقة زجاجية قابلة لإعادة الاستخدام
class GlassCard extends StatelessWidget {
  final Widget child;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final Color? backgroundColor;
  final double blur;

  const GlassCard({
    super.key,
    required this.child,
    this.borderRadius = 30,
    this.padding,
    this.backgroundColor,
    this.blur = 8,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding ?? EdgeInsets.all(16.w),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (backgroundColor ?? Colors.white).withOpacity(0.6),
                (backgroundColor ?? Colors.white).withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(
              color: Colors.white.withOpacity(0.4),
              width: 1.2.w,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }
}

/// بوصلة أسطورية بتصميم فاخر
class LegendaryCompass extends StatelessWidget {
  final double qiblaAngle;

  const LegendaryCompass({super.key, required this.qiblaAngle});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: qiblaAngle),
      duration: const Duration(milliseconds: 1500),
      curve: Curves.elasticOut,
      builder: (context, animatedAngle, child) {
        return CustomPaint(
          painter: LegendaryCompassPainter(qiblaAngle: animatedAngle),
          child: const Center(),
        );
      },
    );
  }
}

class LegendaryCompassPainter extends CustomPainter {
  final double qiblaAngle;

  LegendaryCompassPainter({required this.qiblaAngle});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 4;

    // طبقة ظل خارجي
    _drawShadow(canvas, center, radius);

    // حلقة خارجية ذهبية
    _drawOuterRing(canvas, center, radius);

    // خلفية داخلية متدرجة
    _drawInnerBackground(canvas, center, radius);

    // علامات الدرجات (كل 5 درجات) وأرقام كل 30 درجة
    _drawDegreeTicks(canvas, center, radius);

    // الاتجاهات الأساسية
    _drawCardinalDirections(canvas, center, radius);

    // حلقات زخرفية داخلية
    _drawDecorativeRings(canvas, center, radius);

    // إبرة القبلة بتصميم مضيء
    _drawQiblaNeedle(canvas, center, radius);

    // رسم الكعبة في المركز
    _drawKaabaIcon(canvas, center);
  }

  void _drawShadow(Canvas canvas, Offset center, double radius) {
    final shadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.15)
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 20);
    canvas.drawCircle(center, radius + 2, shadowPaint);
  }

  void _drawOuterRing(Canvas canvas, Offset center, double radius) {
    final gradient = SweepGradient(
      center: Alignment.center,
      colors: [
        const Color(0xFFD4AF37),
        const Color(0xFFB8860B),
        const Color(0xFFD4AF37),
      ],
      stops: [0.0, 0.5, 1.0],
    );
    final ringPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8;
    canvas.drawCircle(center, radius, ringPaint);

    // حلقة داخلية رفيعة
    final innerRingPaint = Paint()
      ..color = const Color(0xFFD4AF37).withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(center, radius - 10, innerRingPaint);
  }

  void _drawInnerBackground(Canvas canvas, Offset center, double radius) {
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 0.8,
      colors: [const Color(0xFFFDFBF7), const Color(0xFFF0EDE5)],
    );
    final bgPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius - 4, bgPaint);
  }

  void _drawDegreeTicks(Canvas canvas, Offset center, double radius) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final numberStyle = TextStyle(
      color: const Color(0xFF3E2723),
      fontSize: 14.sp,
      fontWeight: FontWeight.w600,
    );

    for (int i = 0; i < 360; i += 5) {
      final rad = i * math.pi / 180;
      final isMain = i % 30 == 0;
      final isSecondary = i % 10 == 0;

      double startOffset, endOffset;
      Color color;
      double strokeWidth;

      if (isMain) {
        startOffset = radius - 22;
        endOffset = radius - 8;
        color = const Color(0xFF5D4037);
        strokeWidth = 2.5;
      } else if (isSecondary) {
        startOffset = radius - 18;
        endOffset = radius - 10;
        color = Colors.grey.shade600;
        strokeWidth = 1.5;
      } else {
        startOffset = radius - 14;
        endOffset = radius - 12;
        color = Colors.grey.shade400;
        strokeWidth = 1;
      }

      final start = Offset(
        center.dx + startOffset * math.cos(rad),
        center.dy + startOffset * math.sin(rad),
      );
      final end = Offset(
        center.dx + endOffset * math.cos(rad),
        center.dy + endOffset * math.sin(rad),
      );

      canvas.drawLine(
        start,
        end,
        Paint()
          ..color = color
          ..strokeWidth = strokeWidth,
      );

      // أرقام كل 30 درجة
      if (isMain) {
        String label;
        if (i == 0)
          label = '0';
        else if (i == 90)
          label = '90';
        else if (i == 180)
          label = '180';
        else if (i == 270)
          label = '270';
        else
          label = i.toString();

        final textSpan = TextSpan(text: label, style: numberStyle);
        textPainter.text = textSpan;
        textPainter.layout();
        final textRadius = radius - 40;
        final dx =
            center.dx + textRadius * math.cos(rad) - textPainter.width / 2;
        final dy =
            center.dy + textRadius * math.sin(rad) - textPainter.height / 2;
        textPainter.paint(canvas, Offset(dx, dy));
      }
    }
  }

  void _drawCardinalDirections(Canvas canvas, Offset center, double radius) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);
    final style = TextStyle(
      color: const Color(0xFF2E7D32),
      fontSize: 20.sp,
      fontWeight: FontWeight.bold,
      shadows: [
        Shadow(color: Colors.black12, offset: Offset(1, 1), blurRadius: 2),
      ],
    );

    final directions = {
      'شمال': 0.0,
      'شرق': math.pi / 2,
      'جنوب': math.pi,
      'غرب': 3 * math.pi / 2,
    };

    directions.forEach((text, angle) {
      final textSpan = TextSpan(text: text, style: style);
      textPainter.text = textSpan;
      textPainter.layout();
      final textRadius = radius - 70;
      final dx =
          center.dx + textRadius * math.cos(angle) - textPainter.width / 2;
      final dy =
          center.dy + textRadius * math.sin(angle) - textPainter.height / 2;
      textPainter.paint(canvas, Offset(dx, dy));
    });
  }

  void _drawDecorativeRings(Canvas canvas, Offset center, double radius) {
    // حلقة داخلية مزخرفة
    final dashPaint = Paint()
      ..color = const Color(0xFFD4AF37).withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    final dashRadius = radius - 30;
    final dashPath = Path();
    for (int i = 0; i < 360; i += 10) {
      final rad = i * math.pi / 180;
      final start = Offset(
        center.dx + (dashRadius - 2) * math.cos(rad),
        center.dy + (dashRadius - 2) * math.sin(rad),
      );
      final end = Offset(
        center.dx + (dashRadius + 2) * math.cos(rad),
        center.dy + (dashRadius + 2) * math.sin(rad),
      );
      dashPath.moveTo(start.dx, start.dy);
      dashPath.lineTo(end.dx, end.dy);
    }
    canvas.drawPath(dashPath, dashPaint);

    // حلقة داخلية صلبة
    final solidRingPaint = Paint()
      ..color = const Color(0xFFD4AF37).withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    canvas.drawCircle(center, radius - 50, solidRingPaint);
  }

  void _drawQiblaNeedle(Canvas canvas, Offset center, double radius) {
    final qiblaRad = qiblaAngle * math.pi / 180;
    final needleLength = radius - 55;
    final arrowTip = Offset(
      center.dx + needleLength * math.cos(qiblaRad),
      center.dy + needleLength * math.sin(qiblaRad),
    );

    // توهج حول الإبرة
    final glowPaint = Paint()
      ..color = const Color(0xFF2E7D32).withOpacity(0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12);
    canvas.drawLine(center, arrowTip, glowPaint..strokeWidth = 10);

    // الإبرة الرئيسية
    final needlePaint = Paint()
      ..shader = LinearGradient(
        colors: [const Color(0xFF1B5E20), const Color(0xFF4CAF50)],
      ).createShader(Rect.fromPoints(center, arrowTip))
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(center, arrowTip, needlePaint);

    // خط رفيع للتألق
    final highlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 2.5;
    canvas.drawLine(center, arrowTip, highlightPaint);

    // رأس السهم
    final arrowHeadPaint = Paint()..color = const Color(0xFF1B5E20);
    final angleOffset = 0.6;
    final headSize = 18.0;
    final left = Offset(
      arrowTip.dx - headSize * math.cos(qiblaRad + angleOffset),
      arrowTip.dy - headSize * math.sin(qiblaRad + angleOffset),
    );
    final right = Offset(
      arrowTip.dx - headSize * math.cos(qiblaRad - angleOffset),
      arrowTip.dy - headSize * math.sin(qiblaRad - angleOffset),
    );
    final arrowPath = Path()
      ..moveTo(arrowTip.dx, arrowTip.dy)
      ..lineTo(left.dx, left.dy)
      ..lineTo(right.dx, right.dy)
      ..close();
    canvas.drawPath(arrowPath, arrowHeadPaint);
    canvas.drawPath(
      arrowPath,
      Paint()
        ..color = const Color(0xFF4CAF50)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    // حلقة صغيرة عند بداية الإبرة
    canvas.drawCircle(
      center,
      10,
      Paint()..color = const Color(0xFF1B5E20).withOpacity(0.2),
    );
  }

  void _drawKaabaIcon(Canvas canvas, Offset center) {
    // رسم مبسط للكعبة في المركز
    final kaabaPaint = Paint()..color = const Color(0xFF2E2E2E);
    final kaabaRect = RRect.fromRectAndRadius(
      Rect.fromCenter(center: center, width: 24.w, height: 24.h),
      Radius.circular(4.r),
    );
    canvas.drawRRect(kaabaRect, kaabaPaint);

    // الحزام الأسود
    final beltPaint = Paint()..color = const Color(0xFFD4AF37);
    canvas.drawRect(
      Rect.fromCenter(
        center: Offset(center.dx, center.dy),
        width: 24.w,
        height: 6.h,
      ),
      beltPaint,
    );

    // باب الكعبة
    final doorPaint = Paint()..color = const Color(0xFFD4AF37);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(center.dx, center.dy - 6),
          width: 6.w,
          height: 8.h,
        ),
        Radius.circular(2.r),
      ),
      doorPaint,
    );

    // نقطة بيضاء في المنتصف
    canvas.drawCircle(center, 2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(covariant LegendaryCompassPainter oldDelegate) {
    return oldDelegate.qiblaAngle != qiblaAngle;
  }
}
