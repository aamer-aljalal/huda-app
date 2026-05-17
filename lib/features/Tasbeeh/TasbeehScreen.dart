import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:huda/core/widgets/appbars/huda_app_bar.dart';
import 'package:huda/core/theme/app_theme.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:huda/features/Tasbeeh/models/dhikr_model.dart';

/// UI ONLY — No real logic, no persistence.
/// All values are static for visual demonstration.
class TasbeehScreen extends StatefulWidget {
  const TasbeehScreen({super.key});

  @override
  State<TasbeehScreen> createState() => _TasbeehScreenState();
}

class _TasbeehScreenState extends State<TasbeehScreen>
    with SingleTickerProviderStateMixin {
  late Box<DhikrModel> dhikrBox;

  // Static dummy data (UI only)
  String _currentZekr = 'سبحان الله';
  int _currentCount = 45;
  int _target = 100;

  // Visual animation
  double _buttonScale = 1.0;

  // Dummy lists for demonstration
  Future<void> _addDefaultAzkar() async {
    if (dhikrBox.isNotEmpty) return;

    final defaultAzkar = [
      DhikrModel(
        text: 'سبحان الله',
        targetCount: 33,
        currentCount: 0,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      ),

      DhikrModel(
        text: 'الحمد لله',
        targetCount: 33,
        currentCount: 0,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      ),

      DhikrModel(
        text: 'الله أكبر',
        targetCount: 34,
        currentCount: 0,
        createdAt: DateTime.now(),
        lastUpdated: DateTime.now(),
      ),
    ];

    await dhikrBox.addAll(defaultAzkar);
  }

  void _onCounterTap() {
    // Visual feedback only – no actual increment
    setState(() {
      _buttonScale = 0.9;
    });
    Future.delayed(const Duration(milliseconds: 100), () {
      if (mounted) {
        setState(() {
          _buttonScale = 1.0;
        });
      }
    });
    // No real count change
  }

  void _showZekrSelector() {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20.r)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Container(
              padding: EdgeInsets.all(16.w),
              height: 400.h,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'اختر الذكر',
                    style: TextStyle(fontSize: 20.sp, fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 16.h),
                  Expanded(
                    child: ListView(
                      children: [
                        const Divider(),
                        Text(
                          'أذكار مخصصة',
                          style: TextStyle(
                            fontSize: 16.sp,
                            fontWeight: FontWeight.w500,
                            color: Colors.grey,
                          ),
                        ),
                        ...dhikrBox.values.map(
                          (custom) => ListTile(
                            title: Text(
                              custom.text,
                              textAlign: TextAlign.right,
                            ),
                            subtitle: Text(
                              'الهدف: ${custom.targetCount}',
                              textAlign: TextAlign.right,
                            ),
                            onTap: () {
                              setState(() {
                                _currentZekr = custom.text;
                                _target = custom.targetCount;
                                _currentCount = 0;
                              });
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _loadFirstDhikr() {
    if (dhikrBox.isEmpty) return;

    final firstDhikr = dhikrBox.values.first;

    setState(() {
      _currentZekr = firstDhikr.text;
      _currentCount = firstDhikr.currentCount;
      _target = firstDhikr.targetCount;
    });
  }

  void _showAddZekrDialog() {
    final TextEditingController textController = TextEditingController();
    final TextEditingController targetController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('إضافة ذكر جديد'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: textController,
              decoration: const InputDecoration(
                labelText: 'نص الذكر',
                border: OutlineInputBorder(),
              ),
              textAlign: TextAlign.right,
            ),
            SizedBox(height: 12.h),
            TextField(
              controller: targetController,
              decoration: const InputDecoration(
                labelText: 'العدد المستهدف',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              textAlign: TextAlign.right,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              _saveDhikr(
                text: textController.text,
                target: targetController.text,
              );
            },
            child: Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveDhikr({
    required String text,
    required String target,
  }) async {
    if (text.trim().isEmpty) return;

    final newDhikr = DhikrModel(
      text: text,
      targetCount: int.tryParse(target) ?? 33,
      currentCount: 0,
      createdAt: DateTime.now(),
      lastUpdated: DateTime.now(),
    );

    await dhikrBox.add(newDhikr);

    Navigator.pop(context);

    _showDummyMessage('تم حفظ الذكر بنجاح');
  }

  void _showDummyMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), duration: const Duration(seconds: 1)),
    );
  }

  Future<void> _showGoalSelector() async {
    setState(() {
      _currentCount++;
    });

    final selectedDhikr = dhikrBox.values.firstWhere(
      (dhikr) => dhikr.text == _currentZekr,
    );

    final updatedDhikr = DhikrModel(
      text: selectedDhikr.text,
      targetCount: selectedDhikr.targetCount,
      currentCount: _currentCount,
      createdAt: selectedDhikr.createdAt,
      lastUpdated: DateTime.now(),
    );

    final key = selectedDhikr.key;

    await dhikrBox.put(key, updatedDhikr);
  }

  void _resetCounter() {
    setState(() {
      _currentCount = 0;
    });
    _showDummyMessage('تم إعادة تعيين العداد');
  }

  @override
  @override
  void initState() {
    super.initState();

    dhikrBox = Hive.box<DhikrModel>('dhikrBox');

    _initializeDhikr();
  }

  Future<void> _initializeDhikr() async {
    await _addDefaultAzkar();

    _loadFirstDhikr();
  }

  double get _progress => _currentCount / _target;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,

      appBar: HudaAppBar(
        titleText: 'التسبيح',
        // We already listen to the controller in initState, so onSearchChanged is optional
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            onPressed: _showAddZekrDialog,
            tooltip: 'إضافة ذكر جديد',
          ),
        ],
      ),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 20.h),
        child: Column(
          children: [
            // Current Zekr Display
            Container(
              width: double.infinity,
              padding: EdgeInsets.symmetric(vertical: 20.h, horizontal: 16.w),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(30.r),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.subtleShadow,
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Text(
                _currentZekr,
                style: TextStyle(
                  fontSize: 32.sp,
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.goldAccent : AppColors.primary,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(height: 40.h),

            // Main Counter Circle
            GestureDetector(
              onTap: _onCounterTap,
              child: AnimatedScale(
                scale: _buttonScale,
                duration: const Duration(milliseconds: 100),
                child: Container(
                  width: 220.w,
                  height: 220.h,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [AppColors.primary, AppColors.secondary],
                      center: Alignment.center,
                      radius: 0.8,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withOpacity(0.28),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$_currentCount',
                      style: TextStyle(
                        fontSize: 56.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(height: 30.h),

            // Progress Section
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.w),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '$_currentCount / $_target',
                        style: TextStyle(
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary,
                        ),
                      ),
                      Text(
                        'التقدم',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                  SizedBox(height: 8.h),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12.r),
                    child: LinearProgressIndicator(
                      value: _progress.clamp(0.0, 1.0),
                      minHeight: 12,
                      backgroundColor: AppColors.primary.withOpacity(0.12),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 40.h),

            // Buttons Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _buildControlButton(
                  icon: Icons.refresh,
                  label: 'إعادة تعيين',
                  color: Colors.red,
                  onPressed: _resetCounter,
                ),
                _buildControlButton(
                  icon: Icons.edit_note,
                  label: 'تغيير الذكر',
                  color: Colors.blue.shade700,
                  onPressed: _showZekrSelector,
                ),
                _buildControlButton(
                  icon: Icons.track_changes,
                  label: 'الهدف',
                  color: AppColors.primarySoft,
                  onPressed: _showGoalSelector,
                ),
              ],
            ),
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }
}

Widget _buildControlButton({
  required IconData icon,
  required String label,
  required Color color,
  VoidCallback? onPressed,
}) {
  return Column(
    children: [
      Material(
        elevation: 4,
        shape: const CircleBorder(),
        color: color.withOpacity(0.1),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(100.r),

          splashColor: color.withOpacity(0.15),
          highlightColor: Colors.transparent,

          child: Container(
            width: 70.w,
            height: 70.h,
            decoration: BoxDecoration(shape: BoxShape.circle),

            child: Icon(icon, color: color, size: 32.sp),
          ),
        ),
      ),
      SizedBox(height: 8.h),
      Text(
        label,
        style: TextStyle(
          fontSize: 12.sp,
          fontWeight: FontWeight.w500,
          color: color,
        ),
      ),
    ],
  );
}
