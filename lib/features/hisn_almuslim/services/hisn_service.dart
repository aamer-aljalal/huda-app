import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huda/Model/AccessListModel.dart';
import 'package:huda/features/hisn_almuslim/model/hisn_category.dart';
import 'package:huda/routes/AppRoutes.dart';

class HisnService {
  static Future<List<HisnCategory>> loadHisn() async {
    final String jsonString = await rootBundle.loadString('assets/json/hisn_almuslim.json');
    final Map<String, dynamic> data = jsonDecode(jsonString);
    
    List<HisnCategory> categories = [];
    data.forEach((key, value) {
      categories.add(HisnCategory.fromJson(key, value as Map<String, dynamic>));
    });
    
    return categories;
  }

  static Future<List<AccessListModel>> loadHisnAsActions() async {
    final categories = await loadHisn();
    return categories.map((category) {
      return AccessListModel(
        icon: getHisnIcon(category.title),
        title: category.title,
        route: AppRoutes.hisnDetails,
        arguments: category,
      );
    }).toList();
  }

  static IconData getHisnIcon(String title) {
    if (title.contains('الوضوء')) return Icons.water_drop_outlined;
    if (title.contains('المسجد')) return Icons.mosque_outlined;
    if (title.contains('البيت') || title.contains('المنزل')) return Icons.home_outlined;
    if (title.contains('الثوب') || title.contains('لبس')) return Icons.checkroom_outlined;
    if (title.contains('الموت') || title.contains('الميت') || title.contains('القبور') || title.contains('الجنازة') || title.contains('التعزية') || title.contains('إغماض')) return Icons.co_present_outlined;
    if (title.contains('المطر') || title.contains('الريح') || title.contains('الرعد') || title.contains('الهلال') || title.contains('الاستسقاء')) return Icons.thunderstorm_outlined;
    if (title.contains('الصباح') || title.contains('المساء')) return Icons.wb_sunny_outlined;
    if (title.contains('النوم') || title.contains('الاستيقاظ') || title.contains('تقلب')) return Icons.alarm_on_outlined;
    if (title.contains('الطعام') || title.contains('إفطار')) return Icons.restaurant_menu_outlined;
    if (title.contains('العدو') || title.contains('السلطان') || title.contains('خاف') || title.contains('طرد')) return Icons.shield_outlined;
    if (title.contains('الهم') || title.contains('الحزن') || title.contains('الكرب') || title.contains('مصيبة')) return Icons.mood_bad_outlined;
    if (title.contains('الذكر')) return Icons.star_outline_rounded;
    if (title.contains('المقدمة')) return Icons.info_outline;
    if (title.contains('الخلاء')) return Icons.door_sliding_outlined;
    if (title.contains('الأذان')) return Icons.volume_up_outlined;
    if (title.contains('الركوع') || title.contains('السجود') || title.contains('الرفع') || title.contains('التشهد') || title.contains('قنوت') || title.contains('الوتر') || title.contains('الصلاة')) return Icons.accessibility_new_outlined;
    if (title.contains('الاستخارة')) return Icons.psychology_outlined;
    if (title.contains('الدين')) return Icons.monetization_on_outlined;
    
    return Icons.menu_book_outlined; // Default icon
  }
}
