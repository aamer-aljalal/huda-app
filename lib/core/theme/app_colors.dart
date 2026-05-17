import 'package:flutter/material.dart';

/// AppColors
///
/// Centralized immutable color palette for the Huda app.
/// - All colors are defined as `static const` so they're easy to reuse and change.
/// - Avoids using Material predefined colors; uses explicit hex values.
class AppColors {
  AppColors._(); // prevent instantiation

  // --- Primary branding colors ---
  static const Color primary = Color(0xFF14532D); // Primary Green
  static const Color secondary = Color(0xFF0F3D3A); // Secondary Green
  static const Color goldAccent = Color.fromARGB(
    255,
    240,
    174,
    43,
  ); // Accent (use sparingly)

  // --- Light mode ---
  static const Color lightBackground = Color(0xFFF8F7F3);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightPrimaryText = Color(0xFF1E293B);
  static const Color lightSecondaryText = Color(0xFF64748B);
  static const Color lightBorder = Color(0xFFE7E5E4);

  // --- Dark mode ---
  static const Color darkBackground = Color(
    0xFF081311,
  ); // AMOLED-friendly near black
  static const Color darkSurface = Color(0xFF10201D);
  static const Color darkPrimaryText = Color(0xFFF8FAFC);
  static const Color darkSecondaryText = Color(0xFF94A3B8);
  static const Color darkBorder = Color(0xFF1F3A37);

  // --- Neutral / Utility colors ---
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color transparent = Color(0x00000000);

  // Very light shadow color for subtle elevation (16% black)
  static const Color subtleShadow = Color(0x29000000);

  // Disabled / hint color (derived for convenience)
  static const Color disabled = Color(0xFF94A3B8);

  // Divider fallback (use semantic ones above when possible)
  static const Color divider = lightBorder;

  static const Color primaryLight = Color(0xFF1F7A4D);

  static const Color primarySoft = Color(0xFF2FA36B);

  static const Color greenBorder = Color(0xFF3E8E63);

  static const Color greenGlow = Color(0xFF56B67C);
}
