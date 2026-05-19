import 'dart:async';
import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_compass/flutter_compass.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:huda/core/widgets/appbars/huda_app_bar.dart';
import 'package:permission_handler/permission_handler.dart';

class QiblaScreen extends StatefulWidget {
  const QiblaScreen({super.key});

  @override
  State<QiblaScreen> createState() => _QiblaScreenState();
}

class _QiblaScreenState extends State<QiblaScreen>
    with SingleTickerProviderStateMixin {
  // إحداثيات الكعبة المشرفة
  static const double _kaabaLat = 21.4225;
  static const double _kaabaLng = 39.8262;

  double? _heading; // اتجاه البوصلة الحالي
  double? _qiblaAngle; // زاوية القبلة من الشمال
  double? _deviceQiblaAngle; // زاوية القبلة نسبة لاتجاه الجهاز
  String _statusMessage = 'جاري تحديد موقعك...';
  bool _isLoading = true;
  bool _hasError = false;
  bool _isAligned = false;
  String _locationName = '';

  StreamSubscription<CompassEvent>? _compassSub;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
    _initialize();
  }

  Future<void> _initialize() async {
    await _requestPermissionsAndLocate();
  }

  Future<void> _requestPermissionsAndLocate() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _statusMessage = 'جاري طلب الصلاحيات...';
    });

    // طلب صلاحية الموقع
    final locStatus = await Permission.location.request();
    if (!locStatus.isGranted) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _statusMessage = 'يتطلب تحديد القبلة إذن الموقع.\nيُرجى تفعيله من الإعدادات.';
      });
      return;
    }

    setState(() => _statusMessage = 'جاري تحديد موقعك...');

    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      ).timeout(const Duration(seconds: 15));

      final qibla = _calculateQiblaAngle(pos.latitude, pos.longitude);

      setState(() {
        _qiblaAngle = qibla;
        _isLoading = false;
        _statusMessage = 'البوصلة نشطة';
        _locationName =
            '${pos.latitude.toStringAsFixed(4)}°N, ${pos.longitude.toStringAsFixed(4)}°E';
      });

      _startCompass();
    } catch (e) {
      setState(() {
        _isLoading = false;
        _hasError = true;
        _statusMessage = 'تعذّر تحديد الموقع. تحقق من خدمة GPS.';
      });
    }
  }

  /// حساب زاوية القبلة باستخدام الصيغة الكروية
  double _calculateQiblaAngle(double lat, double lng) {
    final dLng = (_kaabaLng - lng) * math.pi / 180;
    final lat1 = lat * math.pi / 180;
    final lat2 = _kaabaLat * math.pi / 180;

    final y = math.sin(dLng) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLng);

    final bearing = math.atan2(y, x) * 180 / math.pi;
    return (bearing + 360) % 360;
  }

  void _startCompass() {
    _compassSub = FlutterCompass.events?.listen((event) {
      if (!mounted) return;
      final h = event.heading;
      if (h == null) return;

      final deviceAngle = (_qiblaAngle! - h + 360) % 360;
      final aligned = deviceAngle < 3 || deviceAngle > 357;

      setState(() {
        _heading = h;
        _deviceQiblaAngle = deviceAngle;
        _isAligned = aligned;
      });
    });
  }

  @override
  void dispose() {
    _compassSub?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = Theme.of(context).colorScheme.primary;
    final secondary = Theme.of(context).colorScheme.secondary;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: HudaAppBar(
        titleText: 'اتجاه القبلة',
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            onPressed: () => _showHelpDialog(context),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: isDark
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF0D1B0F), Color(0xFF111111)],
                )
              : LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primary.withValues(alpha: 0.08),
                    Colors.white,
                  ],
                ),
        ),
        child: SafeArea(
          child: _isLoading
              ? _buildLoadingState(primary)
              : _hasError
                  ? _buildErrorState(primary)
                  : _buildCompassView(context, isDark, primary, secondary),
        ),
      ),
    );
  }

  Widget _buildLoadingState(Color primary) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 60.w,
            height: 60.w,
            child: CircularProgressIndicator(
              color: primary,
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 24.h),
          Text(
            _statusMessage,
            style: TextStyle(fontSize: 16.sp, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Color primary) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.location_off_rounded, size: 64.sp, color: primary),
            SizedBox(height: 16.h),
            Text(
              _statusMessage,
              style: TextStyle(fontSize: 15.sp, height: 1.6),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24.h),
            ElevatedButton.icon(
              onPressed: _requestPermissionsAndLocate,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('إعادة المحاولة'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding:
                    EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30.r),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCompassView(
      BuildContext context, bool isDark, Color primary, Color secondary) {
    final angle = _deviceQiblaAngle ?? 0.0;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.symmetric(vertical: 16.h),
      child: Column(
        children: [
          // حالة المحاذاة
          _buildAlignmentBanner(isDark),
          SizedBox(height: 20.h),

          // البوصلة الرئيسية
          _buildCompassWidget(angle, primary, secondary, isDark),
          SizedBox(height: 24.h),

          // معلومات الزاوية
          _buildInfoRow(primary, secondary, isDark),
          SizedBox(height: 16.h),

          // تعليمات المعايرة
          _buildCalibrationTip(isDark),
          SizedBox(height: 16.h),

          // الموقع الحالي
          _buildLocationCard(primary, isDark),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildAlignmentBanner(bool isDark) {
    final aligned = _isAligned;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      margin: EdgeInsets.symmetric(horizontal: 20.w),
      padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 12.h),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: aligned
              ? [const Color(0xFF1B5E20), const Color(0xFF4CAF50)]
              : [const Color(0xFF4E342E), const Color(0xFF8D6E63)],
        ),
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: (aligned ? Colors.green : Colors.brown).withValues(alpha: 0.4),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            aligned ? Icons.check_circle_rounded : Icons.explore_rounded,
            color: Colors.white,
            size: 22.sp,
          ),
          SizedBox(width: 10.w),
          Text(
            aligned ? '🕋 أنت متجه نحو القبلة!' : 'وجّه الهاتف حتى يُحاذي السهم',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 14.sp,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompassWidget(
      double angle, Color primary, Color secondary, bool isDark) {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          // هالة خارجية
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (_, __) => Transform.scale(
              scale: _isAligned ? _pulseAnimation.value : 1.0,
              child: Container(
                width: 310.w,
                height: 310.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: _isAligned
                        ? [
                            Colors.green.withValues(alpha: 0.15),
                            Colors.transparent,
                          ]
                        : [
                            primary.withValues(alpha: 0.08),
                            Colors.transparent,
                          ],
                  ),
                ),
              ),
            ),
          ),

          // البوصلة
          Container(
            width: 280.w,
            height: 280.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: primary.withValues(alpha: 0.25),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipOval(
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: isDark
                          ? [const Color(0xFF1C2B1E), const Color(0xFF0D1A0F)]
                          : [Colors.white, const Color(0xFFF0F7F0)],
                    ),
                    border: Border.all(
                      color: const Color(0xFFD4AF37),
                      width: 3,
                    ),
                  ),
                  child: Transform.rotate(
                    angle: -angle * math.pi / 180,
                    child: CustomPaint(
                      painter: _CompassRingPainter(isDark: isDark),
                      child: Center(
                        child: Transform.rotate(
                          angle: angle * math.pi / 180,
                          child: _buildQiblaArrow(),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // مؤشر الشمال
          Positioned(
            top: 0,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 4.h),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(20.r),
              ),
              child: Text(
                'ش',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 12.sp,
                    fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQiblaArrow() {
    return CustomPaint(
      size: Size(280.w, 280.w),
      painter: _QiblaArrowPainter(isAligned: _isAligned),
    );
  }

  Widget _buildInfoRow(Color primary, Color secondary, bool isDark) {
    final cardBg =
        isDark ? const Color(0xFF1A2B1C) : Colors.white;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Row(
        children: [
          Expanded(
            child: _InfoCard(
              label: 'زاوية القبلة',
              value: '${_qiblaAngle?.toStringAsFixed(1) ?? '--'}°',
              icon: Icons.explore_rounded,
              color: primary,
              bg: cardBg,
              isDark: isDark,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _InfoCard(
              label: 'اتجاه الجهاز',
              value: '${_heading?.toStringAsFixed(0) ?? '--'}°',
              icon: Icons.navigation_rounded,
              color: secondary,
              bg: cardBg,
              isDark: isDark,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: _InfoCard(
              label: 'الحالة',
              value: _isAligned ? 'محاذي ✓' : 'غير محاذي',
              icon: _isAligned
                  ? Icons.check_circle_rounded
                  : Icons.radio_button_unchecked,
              color: _isAligned ? Colors.green : Colors.orange,
              bg: cardBg,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCalibrationTip(bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isDark
              ? Colors.amber.withValues(alpha: 0.1)
              : Colors.amber.shade50,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: Colors.amber.shade300),
        ),
        child: Row(
          children: [
            Icon(Icons.sensors_rounded, color: Colors.amber.shade700, size: 20.sp),
            SizedBox(width: 10.w),
            Expanded(
              child: Text(
                'حرّك الهاتف بشكل رقم 8 لمعايرة البوصلة وتحسين الدقة',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isDark ? Colors.amber.shade200 : Colors.amber.shade900,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationCard(Color primary, bool isDark) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 20.w),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A2B1C) : Colors.white,
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: primary.withValues(alpha: 0.2)),
        ),
        child: Row(
          children: [
            Icon(Icons.location_on_rounded, color: primary, size: 20.sp),
            SizedBox(width: 8.w),
            Expanded(
              child: Text(
                'موقعك: $_locationName',
                style: TextStyle(
                  fontSize: 12.sp,
                  color: isDark ? Colors.white70 : Colors.grey.shade700,
                ),
              ),
            ),
            IconButton(
              icon: Icon(Icons.refresh_rounded, size: 18.sp, color: primary),
              onPressed: _requestPermissionsAndLocate,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24.r)),
        title: Row(
          children: [
            Icon(Icons.explore_rounded,
                color: Theme.of(context).colorScheme.primary),
            SizedBox(width: 8.w),
            const Text('كيف تستخدم القبلة؟'),
          ],
        ),
        content: Text(
          '• السهم الأخضر يشير دائماً نحو القبلة.\n'
          '• دوّر الهاتف حتى يتجه السهم للأعلى (نحو الشاشة).\n'
          '• سيتحول اللون للأخضر عند الاستقامة نحو القبلة.\n'
          '• حرّك الهاتف بشكل 8 لمعايرة البوصلة.\n'
          '• تأكد من إبعاد الهاتف عن الأجسام المعدنية.',
          style: TextStyle(fontSize: 14.sp, height: 1.7),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('فهمت',
                style:
                    TextStyle(color: Theme.of(context).colorScheme.primary)),
          ),
        ],
      ),
    );
  }
}

// ======= رسام حلقة البوصلة =======
class _CompassRingPainter extends CustomPainter {
  final bool isDark;
  _CompassRingPainter({required this.isDark});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 10;

    final directions = {'ش': 0.0, 'ق': math.pi / 2, 'ج': math.pi, 'غ': 3 * math.pi / 2};
    final textColor = isDark ? Colors.white60 : const Color(0xFF3E2723);

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < 360; i += 5) {
      final rad = i * math.pi / 180 - math.pi / 2;
      final isMain = i % 90 == 0;
      final isSub = i % 30 == 0;
      final len = isMain ? 16.0 : isSub ? 10.0 : 6.0;
      final sw = isMain ? 2.5 : 1.0;
      final color = isMain
          ? const Color(0xFFD4AF37)
          : (isDark ? Colors.white30 : Colors.grey.shade400);

      final start = Offset(
        center.dx + (radius - len) * math.cos(rad),
        center.dy + (radius - len) * math.sin(rad),
      );
      final end = Offset(
        center.dx + radius * math.cos(rad),
        center.dy + radius * math.sin(rad),
      );
      canvas.drawLine(start, end, Paint()..color = color..strokeWidth = sw);
    }

    directions.forEach((label, angle) {
      final rad = angle - math.pi / 2;
      final tr = radius - 35;
      final span = TextSpan(
        text: label,
        style: TextStyle(
          color: label == 'ش' ? Colors.red.shade600 : textColor,
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.text = span;
      textPainter.layout();
      final dx = center.dx + tr * math.cos(rad) - textPainter.width / 2;
      final dy = center.dy + tr * math.sin(rad) - textPainter.height / 2;
      textPainter.paint(canvas, Offset(dx, dy));
    });
  }

  @override
  bool shouldRepaint(covariant _CompassRingPainter old) =>
      old.isDark != isDark;
}

// ======= رسام سهم القبلة =======
class _QiblaArrowPainter extends CustomPainter {
  final bool isAligned;
  _QiblaArrowPainter({required this.isAligned});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final arrowLen = size.width / 2 - 30;

    // السهم يشير دائماً للأعلى (الشمال في إطار الرسم)
    final tip = Offset(center.dx, center.dy - arrowLen);
    final tail = Offset(center.dx, center.dy + arrowLen * 0.6);

    final color1 = isAligned ? const Color(0xFF1B5E20) : const Color(0xFF1B5E20);
    final color2 = isAligned ? const Color(0xFF69F0AE) : const Color(0xFF4CAF50);

    // توهج
    canvas.drawLine(
      center,
      tip,
      Paint()
        ..color = color2.withValues(alpha: 0.3)
        ..strokeWidth = 14
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8),
    );

    // الإبرة الرئيسية (للأعلى = القبلة)
    canvas.drawLine(
      center,
      tip,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [color1, color2],
        ).createShader(Rect.fromPoints(center, tip))
        ..strokeWidth = 7
        ..strokeCap = StrokeCap.round,
    );

    // رأس السهم
    const ao = 0.5;
    const hs = 20.0;
    final left = Offset(
        tip.dx - hs * math.cos(math.pi / 2 + ao),
        tip.dy + hs * math.sin(math.pi / 2 + ao));
    final right = Offset(
        tip.dx - hs * math.cos(math.pi / 2 - ao),
        tip.dy + hs * math.sin(math.pi / 2 - ao));
    canvas.drawPath(
      Path()
        ..moveTo(tip.dx, tip.dy)
        ..lineTo(left.dx, left.dy)
        ..lineTo(right.dx, right.dy)
        ..close(),
      Paint()..color = color2,
    );

    // الذيل (أحمر)
    canvas.drawLine(
      center,
      tail,
      Paint()
        ..color = Colors.red.shade700
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );

    // دائرة مركزية
    canvas.drawCircle(
      center,
      12,
      Paint()..color = const Color(0xFFD4AF37),
    );
    canvas.drawCircle(
      center,
      8,
      Paint()..color = Colors.white,
    );

    // أيقونة الكعبة الصغيرة
    final kaabaPaint = Paint()..color = const Color(0xFF2E2E2E);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(center: center, width: 10, height: 10),
        const Radius.circular(2),
      ),
      kaabaPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _QiblaArrowPainter old) =>
      old.isAligned != isAligned;
}

// ======= بطاقة معلومات صغيرة =======
class _InfoCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;
  final bool isDark;

  const _InfoCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.h, horizontal: 8.w),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: color.withValues(alpha: 0.2)),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black26 : Colors.grey.shade100,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20.sp),
          SizedBox(height: 6.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 2.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 10.sp,
              color: isDark ? Colors.white54 : Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
