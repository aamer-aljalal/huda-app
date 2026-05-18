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
      icon: Icons.auto_awesome_outlined,
      route: AppRoutes.namesOfAllah,
      title: 'أسماء الله',
    ),
    AccessListModel(
      icon: Icons.bookmark_outline,
      route: AppRoutes.azkarCategories,
      title: 'الأذكار',
    ),
    AccessListModel(
      icon: Icons.format_quote_outlined,
      route: AppRoutes.hadith,
      title: 'الأحاديث',
    ),
    AccessListModel(
      icon: Icons.timer_outlined,
      route: AppRoutes.tasbeeh,
      title: 'التسبيح',
    ),

    AccessListModel(
      icon: Icons.record_voice_over_outlined,
      route: AppRoutes.adhanMuezzin,
      title: 'المؤذن',
    ),
    AccessListModel(
      icon: Icons.explore_outlined,
      route: AppRoutes.qibla,
      title: 'البوصلة',
    ),

    AccessListModel(
      icon: Icons.analytics_outlined,
      route: AppRoutes.stats,
      title: 'الإحصائيات',
    ),
  ];
}
