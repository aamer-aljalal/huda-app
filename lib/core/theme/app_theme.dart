import 'package:flutter/material.dart';
import 'light_theme.dart';
import 'dark_theme.dart';
export 'app_colors.dart';

/// AppTheme
///
/// Central entrypoint for the app's theme system. Use `AppTheme.light` and
/// `AppTheme.dark` when wiring `MaterialApp` or for quick access to ThemeData.
class AppTheme {
  AppTheme._();

  /// Production-ready light ThemeData
  static ThemeData get light => lightTheme;

  /// Production-ready dark ThemeData
  static ThemeData get dark => darkTheme;

  /// Default app-wide ThemeMode (set to system for best UX)
  static const ThemeMode defaultMode = ThemeMode.system;

  /// Example small helper to create ThemeMode from a string value.
  static ThemeMode modeFromString(String value) {
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }
}

