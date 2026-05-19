import 'package:shared_preferences/shared_preferences.dart';

class StatsService {
  static const String _keyStreak = 'stats_streak_count';
  static const String _keyLastActionDate = 'stats_last_action_date';
  static const String _keyCompletedKhatmas = 'stats_completed_khatmas_count';

  // Format date helper: yyyy-MM-dd
  static String _getDateString(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  // Record an action (e.g., 'tasbeeh', 'azkar', 'quran', 'hadith')
  static Future<void> recordAction(String metric, {int amount = 1}) async {
    if (amount <= 0) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final todayStr = _getDateString(DateTime.now());
      final key = 'stats_${metric}_$todayStr';

      // 1. Update daily count
      final current = prefs.getInt(key) ?? 0;
      await prefs.setInt(key, current + amount);

      // 2. Update streak
      await _updateStreak(prefs, todayStr);
    } catch (_) {}
  }

  // Update streak dynamically
  static Future<void> _updateStreak(SharedPreferences prefs, String todayStr) async {
    final lastAction = prefs.getString(_keyLastActionDate);
    final currentStreak = prefs.getInt(_keyStreak) ?? 0;

    if (lastAction == null) {
      // First action ever
      await prefs.setInt(_keyStreak, 1);
      await prefs.setString(_keyLastActionDate, todayStr);
    } else if (lastAction == todayStr) {
      // Already active today, streak stays same
    } else {
      final lastDate = DateTime.parse(lastAction);
      final todayDate = DateTime.parse(todayStr);
      final difference = todayDate.difference(lastDate).inDays;

      if (difference == 1) {
        // Consecutive day
        await prefs.setInt(_keyStreak, currentStreak + 1);
      } else if (difference > 1) {
        // Streak broken
        await prefs.setInt(_keyStreak, 1);
      }
      await prefs.setString(_keyLastActionDate, todayStr);
    }
  }

  // Increment completed khatmas
  static Future<void> incrementCompletedKhatmas() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final current = prefs.getInt(_keyCompletedKhatmas) ?? 0;
      await prefs.setInt(_keyCompletedKhatmas, current + 1);
    } catch (_) {}
  }

  // Get dynamic statistics data for today, week, month, year
  static Future<Map<String, DynamicStats>> getFullStats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final now = DateTime.now();

      // Load streak and completed khatmas
      final streak = prefs.getInt(_keyStreak) ?? 0;
      final khatmas = prefs.getInt(_keyCompletedKhatmas) ?? 0;

      // Helper to sum metrics over a range of days
      Future<int> sumMetric(String metric, int daysLimit) async {
        int sum = 0;
        for (int i = 0; i < daysLimit; i++) {
          final targetDate = now.subtract(Duration(days: i));
          final key = 'stats_${metric}_${_getDateString(targetDate)}';
          sum += prefs.getInt(key) ?? 0;
        }
        return sum;
      }

      // Helper to get chart values (last 7 days normalized)
      Future<List<double>> getChartValues(int daysLimit) async {
        final List<double> values = [];
        double maxVal = 0.0;
        
        // Fetch raw sum of all activities per day for the last 7 days
        final List<double> rawDaysValues = [];
        for (int i = 6; i >= 0; i--) {
          final targetDate = now.subtract(Duration(days: i));
          final dateStr = _getDateString(targetDate);
          
          double daySum = 0;
          for (final metric in ['tasbeeh', 'azkar', 'quran', 'hadith', 'hisn_almuslim']) {
            daySum += (prefs.getInt('stats_${metric}_$dateStr') ?? 0).toDouble();
          }
          rawDaysValues.add(daySum);
          if (daySum > maxVal) {
            maxVal = daySum;
          }
        }

        // Normalize between 0.1 and 1.0 (or 0.0 if all are 0)
        for (final val in rawDaysValues) {
          if (maxVal == 0.0) {
            values.add(0.0);
          } else {
            // scale between 0.15 and 1.0 for better visual representation
            values.add(0.15 + (val / maxVal) * 0.85);
          }
        }
        return values;
      }

      // Calculate daily stats
      final todayAzkar = prefs.getInt('stats_azkar_${_getDateString(now)}') ?? 0;
      final todayTasbeeh = prefs.getInt('stats_tasbeeh_${_getDateString(now)}') ?? 0;
      final todayQuran = prefs.getInt('stats_quran_${_getDateString(now)}') ?? 0;
      final todayHadith = prefs.getInt('stats_hadith_${_getDateString(now)}') ?? 0;
      final todayCompletedAzkarSingle = prefs.getInt('stats_completed_azkar_single_${_getDateString(now)}') ?? 0;
      final todayCompletedAzkarCategory = prefs.getInt('stats_completed_azkar_category_${_getDateString(now)}') ?? 0;
      final todayHisn = prefs.getInt('stats_hisn_almuslim_${_getDateString(now)}') ?? 0;

      // Sum for weekly, monthly, yearly
      final weekAzkar = await sumMetric('azkar', 7);
      final weekTasbeeh = await sumMetric('tasbeeh', 7);
      final weekQuran = await sumMetric('quran', 7);
      final weekHadith = await sumMetric('hadith', 7);
      final weekCompletedAzkarSingle = await sumMetric('completed_azkar_single', 7);
      final weekCompletedAzkarCategory = await sumMetric('completed_azkar_category', 7);
      final weekHisn = await sumMetric('hisn_almuslim', 7);

      final monthAzkar = await sumMetric('azkar', 30);
      final monthTasbeeh = await sumMetric('tasbeeh', 30);
      final monthQuran = await sumMetric('quran', 30);
      final monthHadith = await sumMetric('hadith', 30);
      final monthCompletedAzkarSingle = await sumMetric('completed_azkar_single', 30);
      final monthCompletedAzkarCategory = await sumMetric('completed_azkar_category', 30);
      final monthHisn = await sumMetric('hisn_almuslim', 30);

      final yearAzkar = await sumMetric('azkar', 365);
      final yearTasbeeh = await sumMetric('tasbeeh', 365);
      final yearQuran = await sumMetric('quran', 365);
      final yearHadith = await sumMetric('hadith', 365);
      final yearCompletedAzkarSingle = await sumMetric('completed_azkar_single', 365);
      final yearCompletedAzkarCategory = await sumMetric('completed_azkar_category', 365);
      final yearHisn = await sumMetric('hisn_almuslim', 365);

      final chartVals = await getChartValues(7);

      // Determine progress goals dynamically
      // For Today: e.g. 50 Tasbeeh, 20 Azkar, 2 Quran pages, 1 Hadith, 10 Hisn al-Muslim
      double todayProgress = 0.0;
      if (todayTasbeeh > 0 || todayAzkar > 0 || todayQuran > 0 || todayHadith > 0 || todayHisn > 0) {
        double tasbeehProgress = (todayTasbeeh / 50).clamp(0.0, 1.0);
        double azkarProgress = (todayAzkar / 20).clamp(0.0, 1.0);
        double quranProgress = (todayQuran / 2).clamp(0.0, 1.0);
        double hadithProgress = (todayHadith / 1).clamp(0.0, 1.0);
        double hisnProgress = (todayHisn / 10).clamp(0.0, 1.0);
        todayProgress = (tasbeehProgress + azkarProgress + quranProgress + hadithProgress + hisnProgress) / 5.0;
      }

      double weekProgress = 0.0;
      if (weekTasbeeh > 0 || weekAzkar > 0 || weekQuran > 0 || weekHadith > 0 || weekHisn > 0) {
        double tasbeehProgress = (weekTasbeeh / 350).clamp(0.0, 1.0);
        double azkarProgress = (weekAzkar / 140).clamp(0.0, 1.0);
        double quranProgress = (weekQuran / 14).clamp(0.0, 1.0);
        double hadithProgress = (weekHadith / 7).clamp(0.0, 1.0);
        double hisnProgress = (weekHisn / 70).clamp(0.0, 1.0);
        weekProgress = (tasbeehProgress + azkarProgress + quranProgress + hadithProgress + hisnProgress) / 5.0;
      }

      double monthProgress = 0.0;
      if (monthTasbeeh > 0 || monthAzkar > 0 || monthQuran > 0 || monthHadith > 0 || monthHisn > 0) {
        double tasbeehProgress = (monthTasbeeh / 1500).clamp(0.0, 1.0);
        double azkarProgress = (monthAzkar / 600).clamp(0.0, 1.0);
        double quranProgress = (monthQuran / 60).clamp(0.0, 1.0);
        double hadithProgress = (monthHadith / 30).clamp(0.0, 1.0);
        double hisnProgress = (monthHisn / 300).clamp(0.0, 1.0);
        monthProgress = (tasbeehProgress + azkarProgress + quranProgress + hadithProgress + hisnProgress) / 5.0;
      }

      double yearProgress = 0.0;
      if (yearTasbeeh > 0 || yearAzkar > 0 || yearQuran > 0 || yearHadith > 0 || yearHisn > 0) {
        double tasbeehProgress = (yearTasbeeh / 18000).clamp(0.0, 1.0);
        double azkarProgress = (yearAzkar / 7200).clamp(0.0, 1.0);
        double quranProgress = (yearQuran / 720).clamp(0.0, 1.0);
        double hadithProgress = (yearHadith / 365).clamp(0.0, 1.0);
        double hisnProgress = (yearHisn / 3650).clamp(0.0, 1.0);
        yearProgress = (tasbeehProgress + azkarProgress + quranProgress + hadithProgress + hisnProgress) / 5.0;
      }

      return {
        'اليوم': DynamicStats(
          azkar: todayAzkar,
          readingPages: todayQuran,
          tasbeeh: todayTasbeeh,
          hadith: todayHadith,
          khatma: khatmas,
          completedAzkarSingle: todayCompletedAzkarSingle,
          completedAzkarCategory: todayCompletedAzkarCategory,
          hisnAlmuslim: todayHisn,
          progress: todayProgress,
          streak: streak,
          chartValues: chartVals,
        ),
        'الأسبوع': DynamicStats(
          azkar: weekAzkar,
          readingPages: weekQuran,
          tasbeeh: weekTasbeeh,
          hadith: weekHadith,
          khatma: khatmas,
          completedAzkarSingle: weekCompletedAzkarSingle,
          completedAzkarCategory: weekCompletedAzkarCategory,
          hisnAlmuslim: weekHisn,
          progress: weekProgress,
          streak: streak,
          chartValues: chartVals,
        ),
        'الشهر': DynamicStats(
          azkar: monthAzkar,
          readingPages: monthQuran,
          tasbeeh: monthTasbeeh,
          hadith: monthHadith,
          khatma: khatmas,
          completedAzkarSingle: monthCompletedAzkarSingle,
          completedAzkarCategory: monthCompletedAzkarCategory,
          hisnAlmuslim: monthHisn,
          progress: monthProgress,
          streak: streak,
          chartValues: chartVals,
        ),
        'السنة': DynamicStats(
          azkar: yearAzkar,
          readingPages: yearQuran,
          tasbeeh: yearTasbeeh,
          hadith: yearHadith,
          khatma: khatmas,
          completedAzkarSingle: yearCompletedAzkarSingle,
          completedAzkarCategory: yearCompletedAzkarCategory,
          hisnAlmuslim: yearHisn,
          progress: yearProgress,
          streak: streak,
          chartValues: chartVals,
        ),
      };
    } catch (_) {
      // Fallback in case of error
      return {
        'اليوم': DynamicStats.empty(),
        'الأسبوع': DynamicStats.empty(),
        'الشهر': DynamicStats.empty(),
        'السنة': DynamicStats.empty(),
      };
    }
  }

  // Get Arabic short weekday names for the last 7 days ending today
  static List<String> getLast7DaysLabels() {
    final daysOfWeek = ['ن', 'ث', 'ر', 'خ', 'ج', 'س', 'ح']; // Mon, Tue, Wed, Thu, Fri, Sat, Sun
    final now = DateTime.now();
    final List<String> labels = [];
    for (int i = 6; i >= 0; i--) {
      final date = now.subtract(Duration(days: i));
      // weekday is 1-indexed (1 = Monday, 7 = Sunday)
      labels.add(daysOfWeek[date.weekday - 1]);
    }
    return labels;
  }
}

class DynamicStats {
  final int azkar;
  final int readingPages;
  final int tasbeeh;
  final int hadith;
  final int khatma;
  final int completedAzkarSingle;
  final int completedAzkarCategory;
  final int hisnAlmuslim;
  final double progress;
  final int streak;
  final List<double> chartValues;

  const DynamicStats({
    required this.azkar,
    required this.readingPages,
    required this.tasbeeh,
    required this.hadith,
    required this.khatma,
    required this.completedAzkarSingle,
    required this.completedAzkarCategory,
    required this.hisnAlmuslim,
    required this.progress,
    required this.streak,
    required this.chartValues,
  });

  factory DynamicStats.empty() => const DynamicStats(
        azkar: 0,
        readingPages: 0,
        tasbeeh: 0,
        hadith: 0,
        khatma: 0,
        completedAzkarSingle: 0,
        completedAzkarCategory: 0,
        hisnAlmuslim: 0,
        progress: 0.0,
        streak: 0,
        chartValues: [0, 0, 0, 0, 0, 0, 0],
      );
}
