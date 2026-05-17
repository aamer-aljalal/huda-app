import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:huda/core/widgets/appbars/huda_app_bar.dart';

class HadithScreen extends StatefulWidget {
  const HadithScreen({super.key});
  @override
  State<HadithScreen> createState() => _HadithScreenState();
}

class _HadithScreenState extends State<HadithScreen>
    with SingleTickerProviderStateMixin {
  // Static dummy hadith list (UI only)
  final List<Hadith> _hadiths = [
    Hadith(
      text: 'إنما الأعمال بالنيات، وإنما لكل امرئ ما نوى',
      source: 'رواه البخاري ومسلم',
    ),
    Hadith(
      text: 'لا يؤمن أحدكم حتى يحب لأخيه ما يحب لنفسه',
      source: 'رواه البخاري ومسلم',
    ),
    Hadith(
      text:
          'الدين النصيحة، قلنا: لمن؟ قال: لله، ولكتابه، ولرسوله، ولأئمة المسلمين وعامتهم',
      source: 'رواه مسلم',
    ),
    Hadith(
      text:
          'اتق الله حيثما كنت، وأتبع السيئة الحسنة تمحها، وخالق الناس بخلق حسن',
      source: 'رواه الترمذي',
    ),
    Hadith(text: 'من حسن إسلام المرء تركه ما لا يعنيه', source: 'رواه الترمذي'),
  ];

  int _currentIndex = 0;
  bool _isFavorite = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _changeHadith({bool next = true}) {
    setState(() {
      _animationController.reset();
      if (next) {
        _currentIndex = (_currentIndex + 1) % _hadiths.length;
      } else {
        _currentIndex = (_currentIndex - 1 + _hadiths.length) % _hadiths.length;
      }
      _animationController.forward();
    });
  }

  void _refreshRandom() {
    // Simulate random (just go to next for demo)
    _changeHadith(next: true);
    _showMessage('حديث جديد (عرض تجريبي)');
  }

  void _toggleFavorite() {
    setState(() {
      _isFavorite = !_isFavorite;
    });
    _showMessage(_isFavorite ? 'أضيف إلى المفضلة' : 'أزيل من المفضلة');
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

  @override
  Widget build(BuildContext context) {
    final currentHadith = _hadiths[_currentIndex];

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,

      appBar: HudaAppBar(
        titleText: 'الأحاديث',
        elevation: 0,

        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: _refreshRandom,
            tooltip: 'حديث عشوائي',
          ),
          IconButton(
            icon: Icon(
              _isFavorite ? Icons.star : Icons.star_border,
              color: _isFavorite ? Colors.amber : Colors.white,
            ),
            onPressed: _toggleFavorite,
            tooltip: 'المفضلة',
          ),
        ],
      ),

      body: GestureDetector(
        onHorizontalDragEnd: (details) {
          if (details.primaryVelocity! > 0) {
            _changeHadith(next: false); // swipe right -> previous
          } else if (details.primaryVelocity! < 0) {
            _changeHadith(next: true); // swipe left -> next
          }
        },
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24.0.w),
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Card(
                elevation: 8,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(32.r),
                ),
                color: Colors.white,
                child: Padding(
                  padding: EdgeInsets.all(24.w),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Hadith text
                      Text(
                        currentHadith.text,
                        style: TextStyle(
                          fontSize: 24.sp,
                          fontWeight: FontWeight.w500,
                          height: 1.5.h,
                          color: Color(0xFF2C3E50),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 24.h),
                      // Source
                      Text(
                        currentHadith.source,
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 32.h),
                      // Action buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          _buildActionButton(
                            icon: Icons.star_border,
                            label: 'المفضلة',
                            onTap: _toggleFavorite,
                            color: Colors.amber,
                          ),
                          _buildActionButton(
                            icon: Icons.copy,
                            label: 'نسخ',
                            onTap: _copyHadith,
                            color: Colors.blue,
                          ),
                          _buildActionButton(
                            icon: Icons.share,
                            label: 'مشاركة',
                            onTap: _shareHadith,
                            color: Colors.green,
                          ),
                        ],
                      ),
                      SizedBox(height: 16.h),
                      // Hint for swipe
                      Text(
                        '👈 اسحب لليمين أو اليسار لتغيير الحديث 👉',
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.grey.shade500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
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
            child: Icon(icon, color: color, size: 28.sp),
          ),
        ),
        SizedBox(height: 6.h),
        Text(
          label,
          style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade700),
        ),
      ],
    );
  }
}

/// Simple data class for UI demonstration
class Hadith {
  final String text;
  final String source;

  Hadith({required this.text, required this.source});
}
