import 'package:flutter/material.dart';

class TasbeehApp extends StatelessWidget {
  const TasbeehApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Tasbeeh UI',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        fontFamily: 'Cairo', // Optional: you can add a custom font
        useMaterial3: true,
      ),
      home: const TasbeehScreen(),
    );
  }
}

/// UI ONLY — No logic, no state management, no data persistence.
/// All values are static and for visual demonstration only.
class TasbeehScreen extends StatefulWidget {
  const TasbeehScreen({super.key});

  @override
  State<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen>
    with SingleTickerProviderStateMixin {
  // ==================== VISUAL-ONLY ANIMATION ====================
  // This scale animation is purely for visual feedback.
  // It does NOT affect any counter value or business logic.
  double _counterScale = 1.0;

  void _animateTap() {
    setState(() {
      _counterScale = 1.1;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _counterScale = 1.0;
        });
      }
    });
  }

  // ==================== STATIC DUMMY VALUES ====================
  // These values are hardcoded for UI demonstration only.
  // They never change, and no logic updates them.
  final String _currentZekr = 'سبحان الله';
  final int _staticCount = 45;
  final int _target = 100;
  final int _todayCount = 120;
  final int _weekCount = 850;

  double get _progress => _staticCount / _target;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F9F0), // Soft light green background
      appBar: AppBar(
        title: const Text(
          'التسبيح',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // UI ONLY: No navigation logic
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              // UI ONLY: No action
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        child: Column(
          children: [
            // 1. Current Zekr Display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.9),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.shade100,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                _currentZekr,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E5C2E),
                ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 40),

            // 2. Main Counter Circle (Center Focus)
            GestureDetector(
              onTap: _animateTap, // Only visual scale animation, no increment
              child: AnimatedScale(
                scale: _counterScale,
                duration: const Duration(milliseconds: 100),
                curve: Curves.easeOutBack,
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [Color(0xFF4CAF50), Color(0xFF2E7D32)],
                      center: Alignment.center,
                      radius: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.shade300.withOpacity(0.5),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$_staticCount', // Static number, never changes
                      style: const TextStyle(
                        fontSize: 64,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),

            // 3. Progress Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$_staticCount / $_target',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: Colors.green.shade800,
                        ),
                      ),
                      const Text(
                        'التقدم',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      value: _progress.clamp(0.0, 1.0),
                      minHeight: 12,
                      backgroundColor: Colors.green.shade100,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.green.shade600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),

            // 4. Control Buttons Section
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: Icons.refresh,
                  label: 'إعادة تعيين',
                  color: Colors.orange.shade700,
                ),
                _buildControlButton(
                  icon: Icons.edit_note,
                  label: 'تغيير الذكر',
                  color: Colors.blue.shade700,
                ),
                _buildControlButton(
                  icon: Icons.track_changes,
                  label: 'الهدف',
                  color: Colors.purple.shade700,
                ),
              ],
            ),
            const SizedBox(height: 40),

            // 5. Small Stats Section (UI only)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade200,
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard(
                    'اليوم',
                    _todayCount,
                    Icons.today,
                    Colors.green,
                  ),
                  Container(height: 40, width: 1, color: Colors.grey.shade300),
                  _buildStatCard(
                    'هذا الأسبوع',
                    _weekCount,
                    Icons.calendar_view_week,
                    Colors.teal,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Hint text (UI only)
            Text(
              '👆 اضغط على العداد (تأثير بصري فقط) | لا توجد وظائف تفاعلية',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // Helper: visual-only button with empty onPressed
  Widget _buildControlButton({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Material(
          elevation: 4,
          shape: const CircleBorder(),
          color: color.withOpacity(0.1),
          child: InkWell(
            onTap: () {}, // No logic
            customBorder: const CircleBorder(),
            child: Container(
              width: 60,
              height: 60,
              decoration: const BoxDecoration(shape: BoxShape.circle),
              child: Icon(icon, color: color, size: 32),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(
    String title,
    int value,
    IconData icon,
    MaterialColor color,
  ) {
    return Column(
      children: [
        Icon(icon, color: color.shade600, size: 28),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: color.shade800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(fontSize: 14, color: Colors.grey.shade600),
        ),
      ],
    );
  }
}
