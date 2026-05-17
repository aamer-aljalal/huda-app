import 'package:hive/hive.dart';

part 'dhikr_model.g.dart';

@HiveType(typeId: 0)
class DhikrModel extends HiveObject {
  @HiveField(0)
  final String text;

  @HiveField(1)
  final int targetCount;

  @HiveField(2)
  int currentCount;

  @HiveField(3)
  final DateTime createdAt;
  @HiveField(4)
  final DateTime lastUpdated;
  DhikrModel({
    required this.text,
    required this.targetCount,
    required this.currentCount,
    required this.createdAt,
    required this.lastUpdated,
  });
}
