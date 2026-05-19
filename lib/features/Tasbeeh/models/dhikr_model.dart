import 'package:hive/hive.dart';

part 'dhikr_model.g.dart';

@HiveType(typeId: 0)
class DhikrModel extends HiveObject {
  @HiveField(0)
  String text;

  @HiveField(1)
  int targetCount;

  @HiveField(2)
  int currentCount;

  @HiveField(3)
  final DateTime createdAt;

  @HiveField(4)
  DateTime lastUpdated;

  @HiveField(5)
  bool isReminderEnabled;

  @HiveField(6)
  int reminderHour;

  @HiveField(7)
  int reminderMinute;

  DhikrModel({
    required this.text,
    required this.targetCount,
    required this.currentCount,
    required this.createdAt,
    required this.lastUpdated,
    this.isReminderEnabled = false,
    this.reminderHour = 9,
    this.reminderMinute = 0,
  });
}
