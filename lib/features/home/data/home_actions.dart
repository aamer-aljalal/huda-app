import 'package:flutter/material.dart';

import 'package:huda/Model/AccessListModel.dart';

import 'package:huda/routes/AppRoutes.dart';

class HomeActions {
  // ========================= الوصول السريع =========================

  static List<AccessListModel> quickActionsList = [
    AccessListModel(
      icon: Icons.menu_book_outlined,
      route: AppRoutes.quran,
      title: 'القرآن',
    ),

    AccessListModel(
      icon: Icons.bookmark_outline,
      route: AppRoutes.azkarCategories,
      title: 'الأذكار',
    ),

    AccessListModel(
      icon: Icons.timer_outlined,
      route: AppRoutes.tasbeeh,
      title: 'التسبيح',
    ),

    AccessListModel(
      icon: Icons.format_quote_outlined,
      route: AppRoutes.hadith,
      title: 'الأحاديث',
    ),

    AccessListModel(
      icon: Icons.explore_outlined,
      route: AppRoutes.qibla,
      title: 'البوصلة',
    ),

    AccessListModel(
      icon: Icons.settings_outlined,
      route: AppRoutes.settings,
      title: 'الإعدادات',
    ),
  ];
}
