import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:huda/core/widgets/appbars/huda_app_bar.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Visual-only state for UI demonstration (no actual functionality)
  bool _soundEnabled = true;
  bool _notificationsPrayer = true;
  bool _notificationsAzkar = false;
  bool _notificationsCustom = false;
  bool _smartAudioEnabled = false;
  int _smartAudioInterval = 2; // hours
  String _selectedReciter = 'مشاري راشد';
  double _volume = 0.7;
  String _themeMode = 'تلقائي';

  final List<String> _reciters = [
    'مشاري راشد',
    'عبد الرحمن السديس',
    'سعد الغامدي',
    'محمود خليل الحصري',
  ];
  final List<int> _intervals = [1, 2, 3, 4, 6];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: HudaAppBar(titleText: 'الإعدادات', elevation: 0),

      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.all(16.w),
        child: Column(
          children: [
            // 1. Sound Section
            _buildSection(
              title: '🎵 الصوت',
              children: [
                _buildSwitchTile(
                  title: 'تشغيل الصوت',
                  value: _soundEnabled,
                  onChanged: (_) => _visualOnlyToggle(),
                ),
                if (_soundEnabled) ...[
                  Divider(height: 1.h, indent: 16, endIndent: 16),
                  _buildDropdownTile(
                    title: 'اختيار القارئ',
                    value: _selectedReciter,
                    items: _reciters,
                    onChanged: (_) => _visualOnlyToggle(),
                  ),
                  _buildSliderTile(
                    title: 'مستوى الصوت',
                    value: _volume,
                    onChanged: (_) => _visualOnlyToggle(),
                  ),
                ],
              ],
            ),
            SizedBox(height: 16.h),

            // 2. Notifications Section
            _buildSection(
              title: '🔔 الإشعارات',
              children: [
                _buildSwitchTile(
                  title: 'إشعارات الصلاة',
                  value: _notificationsPrayer,
                  onChanged: (_) => _visualOnlyToggle(),
                ),
                _buildSwitchTile(
                  title: 'أذكار الصباح والمساء',
                  value: _notificationsAzkar,
                  onChanged: (_) => _visualOnlyToggle(),
                ),
                _buildSwitchTile(
                  title: 'التذكير المخصص',
                  value: _notificationsCustom,
                  onChanged: (_) => _visualOnlyToggle(),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // 3. Smart Audio Section
            _buildSection(
              title: '🧠 الصوت الذكي',
              children: [
                _buildSwitchTile(
                  title: 'تشغيل الصوت الذكي',
                  value: _smartAudioEnabled,
                  onChanged: (_) => _visualOnlyToggle(),
                ),
                if (_smartAudioEnabled) ...[
                  Divider(height: 1.h, indent: 16, endIndent: 16),
                  _buildDropdownTile<int>(
                    title: 'كل كم ساعة',
                    value: _smartAudioInterval,
                    items: _intervals,
                    itemLabelBuilder: (v) => '$v ساعات',
                    onChanged: (_) => _visualOnlyToggle(),
                  ),
                  _buildTextInputTile(
                    title: 'النص',
                    hint: 'أدخل نص التذكير',
                    value: '',
                  ),
                ],
              ],
            ),
            SizedBox(height: 16.h),

            // 4. Theme Section
            _buildSection(
              title: '🎨 المظهر',
              children: [
                _buildRadioTile(
                  title: 'نهاري',
                  groupValue: _themeMode,
                  value: 'نهاري',
                  onChanged: (_) => _visualOnlyToggle(),
                ),
                _buildRadioTile(
                  title: 'ليلي',
                  groupValue: _themeMode,
                  value: 'ليلي',
                  onChanged: (_) => _visualOnlyToggle(),
                ),
                _buildRadioTile(
                  title: 'تلقائي',
                  groupValue: _themeMode,
                  value: 'تلقائي',
                  onChanged: (_) => _visualOnlyToggle(),
                ),
              ],
            ),
            SizedBox(height: 16.h),

            // 5. Backup Section
            _buildSection(
              title: '💾 النسخ الاحتياطي',
              children: [
                _buildActionTile(
                  icon: Icons.upload_file,
                  title: 'تصدير البيانات',
                  onTap: () => _showDummyDialog('تصدير البيانات'),
                ),
                _buildActionTile(
                  icon: Icons.download,
                  title: 'استيراد البيانات',
                  onTap: () => _showDummyDialog('استيراد البيانات'),
                ),
              ],
            ),
            SizedBox(height: 24.h),

            // Hint text
            Text(
              '⚠️ هذه الواجهة للعرض فقط — لا توجد وظائف حقيقية',
              style: TextStyle(fontSize: 12.sp, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }

  // Visual-only feedback
  void _visualOnlyToggle() {
    setState(() {});
  }

  void _showDummyDialog(String action) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(action),
        content: Text('هذا عرض تجريبي فقط. لا توجد وظائف حقيقية.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إغلاق'),
          ),
        ],
      ),
    );
  }

  // UI Helpers
  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade200,
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.teal.shade800,
              ),
            ),
          ),
          ...children,
          SizedBox(height: 8.h),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return SwitchListTile(
      title: Text(title, style: TextStyle(fontSize: 16.sp)),
      value: value,
      onChanged: onChanged,
      activeColor: Colors.teal.shade600,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
    );
  }

  Widget _buildDropdownTile<T>({
    required String title,
    required T value,
    required List<T> items,
    required Function(T?) onChanged,
    String Function(T)? itemLabelBuilder,
  }) {
    return ListTile(
      title: Text(title, style: TextStyle(fontSize: 16.sp)),
      trailing: DropdownButton<T>(
        value: value,
        items: items.map((item) {
          return DropdownMenuItem<T>(
            value: item,
            child: Text(
              itemLabelBuilder != null
                  ? itemLabelBuilder(item)
                  : item.toString(),
            ),
          );
        }).toList(),
        onChanged: onChanged,
        underline: SizedBox(),
        icon: Icon(Icons.arrow_drop_down),
        style: TextStyle(color: Colors.teal.shade800, fontSize: 16.sp),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
    );
  }

  Widget _buildSliderTile({
    required String title,
    required double value,
    required Function(double) onChanged,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16.sp)),
          Row(
            children: [
              Icon(Icons.volume_down, size: 20.sp, color: Colors.grey.shade600),
              Expanded(
                child: Slider(
                  value: value,
                  onChanged: onChanged,
                  activeColor: Colors.teal.shade600,
                ),
              ),
              Icon(Icons.volume_up, size: 20.sp, color: Colors.grey.shade600),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRadioTile({
    required String title,
    required String groupValue,
    required String value,
    required Function(String?) onChanged,
  }) {
    return RadioListTile<String>(
      title: Text(title),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: Colors.teal.shade600,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
    );
  }

  Widget _buildActionTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.teal.shade700),
      title: Text(title, style: TextStyle(fontSize: 16.sp)),
      trailing: Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.w),
    );
  }

  Widget _buildTextInputTile({
    required String title,
    required String hint,
    required String value,
  }) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: TextStyle(fontSize: 16.sp)),
          SizedBox(height: 6.h),
          TextField(
            decoration: InputDecoration(
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide(color: Colors.grey.shade300),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: 12.w,
                vertical: 10.h,
              ),
            ),
            textAlign: TextAlign.right,
            onChanged: (_) => _visualOnlyToggle(),
          ),
        ],
      ),
    );
  }
}
