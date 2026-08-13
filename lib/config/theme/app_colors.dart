import 'package:flutter/material.dart';

/// Palette de l'application, alignée sur celle de l'app cliente `supplies_apk`
/// pour la cohérence de marque 01Supplies.
class AppColors {
  AppColors._();

  // ── Light ─────────────────────────────────────────────────────────────────
  static const Color primaryColorLight = Color(0xFF6F52ED);
  static const Color secondaryColorLight = Color(0xFFFF7D28);
  static const Color tertiaryColorLight = Color(0xFFFF7D28);
  static const Color backgroundColorLight = Color(0xFFF2F2F0);
  static const Color appBarColorLight = Colors.white;
  static const Color containerColorLight = Color(0xFFD9D8D7);
  static const Color surfaceColorLight = Color(0xFFE8E8E6);
  static const Color onSurfaceColorLight = Color(0xFF1A1A19);
  static const Color textColorLight = Color(0xFF030302);
  static const Color subTextColorLight = Color(0xFF4D4D4C);

  // ── Dark ──────────────────────────────────────────────────────────────────
  static const Color primaryColorDark = Color(0xFF8F7AFF);
  static const Color secondaryColorDark = Color(0xFFFF9E5E);
  static const Color tertiaryColorDark = Color(0xFFFF9E5E);
  static const Color backgroundColorDark = Color(0xFF1C1C1A);
  static const Color appBarColorDark = Color(0xFF2C2C2A);
  static const Color containerColorDark = Color(0xFF2D2D2B);
  static const Color surfaceColorDark = Color(0xFF252523);
  static const Color onSurfaceColorDark = Color(0xFFE6E6E4);
  static const Color textColorDark = Color(0xFFF2F2F0);
  static const Color subTextColorDark = Color(0xFFB3B3B0);

  // ── Statuts ───────────────────────────────────────────────────────────────
  static const Color verifiedStatusColor = Colors.green;
  static const Color pendingStatusColor = Colors.orange;
  static const Color notVerifiedStatusColor = Colors.red;
  static const Color verifiedStatusBackgroundColor = Color(0xFFE8F5E9);
  static const Color pendingStatusBackgroundColor = Color(0xFFFFF3E0);
  static const Color notVerifiedStatusBackgroundColor = Color(0xFFFFEBEE);

  // ── Flat design : bordures & séparateurs ──────────────────────────────────
  static Color borderColorLight = Colors.black.withValues(alpha: 0.08);
  static Color borderColorDark = Colors.white.withValues(alpha: 0.1);
  static const Color borderFocusColorLight = Color(0xFF6F52ED);
  static const Color borderFocusColorDark = Color(0xFF8F7AFF);
  static Color dividerColorLight = Colors.black.withValues(alpha: 0.06);
  static Color dividerColorDark = Colors.white.withValues(alpha: 0.08);
  static Color inputBorderColorLight = Colors.black.withValues(alpha: 0.12);
  static Color inputBorderColorDark = Colors.white.withValues(alpha: 0.15);

  static Color getBorderColor(bool isDarkMode) =>
      isDarkMode ? borderColorDark : borderColorLight;
  static Color getFocusBorderColor(bool isDarkMode) =>
      isDarkMode ? borderFocusColorDark : borderFocusColorLight;
  static Color getDividerColor(bool isDarkMode) =>
      isDarkMode ? dividerColorDark : dividerColorLight;
  static Color getInputBorderColor(bool isDarkMode) =>
      isDarkMode ? inputBorderColorDark : inputBorderColorLight;

  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderWidthThin = 1.0;
  static const double borderWidthMedium = 1.5;
  static const double borderWidthThick = 2.0;
}
