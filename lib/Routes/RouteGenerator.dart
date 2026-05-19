import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter/material.dart';
import 'package:huda/features/azkar/model/zekr_category.dart';
import 'package:huda/Routes/AppRoutes.dart';
import 'package:huda/features/home/HomePage.dart';
import 'package:huda/features/azkar/AzkarCategories.dart';
import 'package:huda/features/azkar/zkar_details.dart';
import 'package:huda/features/Hadith/HadithScreen.dart';
import 'package:huda/features/Qibla/QiblaScreen.dart';
import 'package:huda/features/Settings/Settings.dart';
import 'package:huda/features/adhan/adhan_muezzin_screen.dart';
import 'package:huda/features/quran/views/SurahListPage.dart';
import 'package:huda/features/Tasbeeh/TasbeehScreen.dart';
import 'package:huda/features/Dashbord/Stats.dart';
import 'package:huda/features/names_of_allah/views/names_of_allah_screen.dart';
import 'package:huda/features/bookmarks/views/bookmarks_page.dart';
import 'package:huda/features/hisn_almuslim/hisn_categories_screen.dart';
import 'package:huda/features/hisn_almuslim/hisn_details_screen.dart';
import 'package:huda/features/hisn_almuslim/model/hisn_category.dart';
import 'package:huda/features/quran/views/khatma_planner_screen.dart';

class RouteGenerator {
  static Route<dynamic> generate(RouteSettings settings) {
    switch (settings.name) {
      // ========================= الرئيسية =========================

      case AppRoutes.splash:
      case AppRoutes.homePage:
        return MaterialPageRoute(builder: (_) => const HomePage());

      // ========================= القرآن =========================

      case AppRoutes.quran:
        return MaterialPageRoute(builder: (_) => const SurahListPage());

      // ========================= الأذكار =========================

      case AppRoutes.azkarCategories:
        return MaterialPageRoute(builder: (_) => const AzkarCategoriesScreen());

      case AppRoutes.zkarDetails:
        final category = settings.arguments as ZekrCategory;
        return MaterialPageRoute(
          builder: (_) => AzkarDetailsScreen(category: category),
        );

      // ========================= التسبيح =========================

      case AppRoutes.tasbeeh:
        return MaterialPageRoute(builder: (_) => const TasbeehScreen());

      // case AppRoutes.tasbeeh:
      //   return MaterialPageRoute(builder: (_) => const TasbeehApp());
      // ========================= الأحاديث =========================

      case AppRoutes.hadith:
        return MaterialPageRoute(builder: (_) => const HadithScreen());

      // ========================= أسماء الله الحسنى =========================

      case AppRoutes.namesOfAllah:
        return MaterialPageRoute(builder: (_) => const NamesOfAllahScreen());

      // ========================= القبلة =========================

      case AppRoutes.qibla:
        return MaterialPageRoute(builder: (_) => const QiblaScreen());

      // ========================= الإعدادات =========================

      case AppRoutes.settings:
        return MaterialPageRoute(builder: (_) => const SettingsScreen());

      case AppRoutes.adhanMuezzin:
        return MaterialPageRoute(builder: (_) => const AdhanMuezzinScreen());

      // ========================= الإحصائيات =========================

      case AppRoutes.stats:
        return MaterialPageRoute(builder: (_) => const StatsScreen());

      case AppRoutes.khatmaPlanner:
        return MaterialPageRoute(builder: (_) => const KhatmaPlannerScreen());

      // ========================= المحفوظات =========================

      case AppRoutes.bookmarks:
        return MaterialPageRoute(builder: (_) => const BookmarksPage());

      // ========================= حصن المسلم =========================

      case AppRoutes.hisnCategories:
        return MaterialPageRoute(builder: (_) => const HisnCategoriesScreen());

      case AppRoutes.hisnDetails:
        final category = settings.arguments as HisnCategory;
        return MaterialPageRoute(
          builder: (_) => HisnDetailsScreen(category: category),
        );

      // ========================= صفحة غير موجودة =========================

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text(
                'Page Not Found',
                style: TextStyle(fontSize: 18.sp, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        );
    }
  }
}
