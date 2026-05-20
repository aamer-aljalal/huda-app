import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:tarteel/core/providers/prayer_provider.dart';
import 'package:tarteel/core/services/adhan_notification_service.dart';
import 'package:tarteel/core/widgets/appbars/tarteel_app_bar.dart';
import 'package:just_audio/just_audio.dart';
import 'package:provider/provider.dart';

class AdhanMuezzinScreen extends StatefulWidget {
  const AdhanMuezzinScreen({super.key});

  @override
  State<AdhanMuezzinScreen> createState() => _AdhanMuezzinScreenState();
}

class _AdhanMuezzinScreenState extends State<AdhanMuezzinScreen> {
  final AudioPlayer _player = AudioPlayer();

  AdhanMuezzin _selectedMuezzin = AdhanNotificationService.defaultMuezzin;
  String? _playingMuezzinId;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadSelectedMuezzin();
    _player.playerStateStream.listen((state) {
      if (!mounted) return;
      if (state.processingState == ProcessingState.completed) {
        setState(() => _playingMuezzinId = null);
      }
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _loadSelectedMuezzin() async {
    final selected = await AdhanNotificationService.selectedMuezzin();
    if (!mounted) return;
    setState(() => _selectedMuezzin = selected);
  }

  Future<void> _togglePreview(AdhanMuezzin muezzin) async {
    if (_playingMuezzinId == muezzin.id) {
      await _player.stop();
      if (!mounted) return;
      setState(() => _playingMuezzinId = null);
      return;
    }

    setState(() => _playingMuezzinId = muezzin.id);
    try {
      await _player.stop();
      await _player.setAsset(muezzin.assetPath);
      await _player.play();
    } catch (_) {
      if (!mounted) return;
      setState(() => _playingMuezzinId = null);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('تعذر تشغيل صوت المؤذن')));
    }
  }

  Future<void> _selectMuezzin(AdhanMuezzin muezzin) async {
    setState(() {
      _selectedMuezzin = muezzin;
      _isSaving = true;
    });

    await AdhanNotificationService.setSelectedMuezzin(muezzin);

    if (!mounted) return;
    await context.read<PrayerProvider>().scheduleAdhanNotifications();

    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('تم اختيار ${muezzin.name} للأذان')));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: tarteelAppBar(
          titleText: 'اختيار المؤذن',
          elevation: 0,
          toolbarHeight: 90,
        ),
        body: ListView.separated(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.all(16.w),
          itemCount: AdhanNotificationService.muezzins.length,
          separatorBuilder: (_, __) => SizedBox(height: 12.h),
          itemBuilder: (context, index) {
            final muezzin = AdhanNotificationService.muezzins[index];
            final isSelected = _selectedMuezzin.id == muezzin.id;
            final isPlaying = _playingMuezzinId == muezzin.id;

            return _MuezzinCard(
              muezzin: muezzin,
              isSelected: isSelected,
              isPlaying: isPlaying,
              isSaving: _isSaving && isSelected,
              onPreview: () => _togglePreview(muezzin),
              onSelect: () => _selectMuezzin(muezzin),
            );
          },
        ),
      ),
    );
  }
}

class _MuezzinCard extends StatelessWidget {
  const _MuezzinCard({
    required this.muezzin,
    required this.isSelected,
    required this.isPlaying,
    required this.isSaving,
    required this.onPreview,
    required this.onSelect,
  });

  final AdhanMuezzin muezzin;
  final bool isSelected;
  final bool isPlaying;
  final bool isSaving;
  final VoidCallback onPreview;
  final VoidCallback onSelect;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(8.r),
        border: Border.all(
          color: isSelected
              ? colorScheme.primary
              : colorScheme.outline.withValues(alpha: 0.18),
          width: isSelected ? 1.6 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44.w,
            height: 44.w,
            decoration: BoxDecoration(
              color: isSelected
                  ? colorScheme.primary.withValues(alpha: 0.12)
                  : colorScheme.surfaceContainerHighest.withValues(alpha: 0.6),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isSelected ? Icons.check : Icons.record_voice_over_outlined,
              color: isSelected ? colorScheme.primary : colorScheme.onSurface,
              size: 23.sp,
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Text(
              muezzin.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          SizedBox(width: 8.w),
          IconButton.filledTonal(
            tooltip: isPlaying ? 'إيقاف' : 'استماع',
            onPressed: onPreview,
            icon: Icon(isPlaying ? Icons.stop : Icons.play_arrow),
          ),
          SizedBox(width: 6.w),
          FilledButton(
            onPressed: isSelected || isSaving ? null : onSelect,
            child: isSaving
                ? SizedBox(
                    width: 16.w,
                    height: 16.w,
                    child: const CircularProgressIndicator(strokeWidth: 2),
                  )
                : Text(isSelected ? 'مختار' : 'اختيار'),
          ),
        ],
      ),
    );
  }
}
