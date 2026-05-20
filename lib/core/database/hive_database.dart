import 'package:hive_flutter/hive_flutter.dart';
import 'package:tarteel/features/Tasbeeh/models/dhikr_model.dart';

class HiveDatabase {
  static Future<void> init() async {
    await Hive.initFlutter();

    Hive.registerAdapter(DhikrModelAdapter());

    await Hive.openBox<DhikrModel>('dhikrBox');
  }
}