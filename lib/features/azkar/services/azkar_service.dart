import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:huda/Model/AccessListModel.dart';
import 'package:huda/features/azkar/icons/azkar_icons.dart';

import 'package:huda/features/azkar/model/zekr_category.dart';
import 'package:huda/features/azkar/model/zekr_model%20.dart';
import 'package:huda/routes/AppRoutes.dart';

class AzkarService {
  static Future<List<ZekrCategory>> loadAzkar() async {
    // قراءة ملف json
    final String jsonString = await rootBundle.loadString(
      'assets/json/azkar.json',
    );

    // تحويل النص إلى Map
    final Map<String, dynamic> data = jsonDecode(jsonString);

    // القائمة النهائية
    List<ZekrCategory> categories = [];

    // المرور على الأقسام
    data.forEach((key, value) {
      // تحويل الأذكار داخل القسم
      List<ZekrModel> azkar = (value as List)
          .map((e) => ZekrModel.fromJson(e))
          .toList();

      // إضافة القسم للقائمة
      categories.add(ZekrCategory(title: key, azkar: azkar));
    });

    return categories;
  }

  // ================= تحويلها إلى Actions =================

  static Future<List<AccessListModel>> loadAzkarAsActions() async {
    final categories = await loadAzkar();

    return categories.map((category) {
      return AccessListModel(
        icon: AzkarIcons.icons[category.title] ?? Icons.menu_book,

        title: category.title,

        route: AppRoutes.zkarDetails,

        arguments: category,
      );
    }).toList();
  }
}
