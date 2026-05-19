import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final savedTheme = prefs.getString('app_theme_mode') ?? 'تلقائي';
    _themeMode = _themeModeFromArabicString(savedTheme);
    notifyListeners();
  }

  Future<void> updateTheme(String themeString) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('app_theme_mode', themeString);
    _themeMode = _themeModeFromArabicString(themeString);
    notifyListeners();
  }

  ThemeMode _themeModeFromArabicString(String value) {
    switch (value) {
      case 'نهاري':
        return ThemeMode.light;
      case 'ليلي':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}
