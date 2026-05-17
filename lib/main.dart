import 'package:flutter/material.dart';
import 'package:huda/Routes/AppRoutes.dart';
import 'package:huda/Routes/RouteGenerator.dart';
import 'package:huda/core/database/hive_database.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'core/theme/app_theme.dart';

import 'package:provider/provider.dart';
import 'package:huda/core/providers/prayer_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('ar', null);
  await Hive.initFlutter();
  // await Hive.deleteBoxFromDisk('dhikrBox');
  await HiveDatabase.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PrayerProvider()..initializeData()),
      ],
      child: const Huda(),
    ),
  );
}

class Huda extends StatelessWidget {
  const Huda({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(375, 812), // Default design size, can be adjusted according to your UI design (Figma/AdobeXD)
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,

          builder: (context, widget) {
            return ScrollConfiguration(behavior: MyBehavior(), child: widget!);
          },

          // Light Theme
          theme: AppTheme.light,

          // Dark Theme
          darkTheme: AppTheme.dark,

          // System Theme
          themeMode: AppTheme.defaultMode,

          initialRoute: AppRoutes.homePage,
          onGenerateRoute: RouteGenerator.generate,
        );
      },
    );
  }
}

class MyBehavior extends ScrollBehavior {
  @override
  Widget buildOverscrollIndicator(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}
