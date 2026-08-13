import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_colors.dart';

enum TFonts {
  inter('Inter'),
  bricolageGrotesque('Bricolage Grotesque');

  const TFonts(this.value);
  final String value;
}

class TTextTheme {
  TTextTheme._();

  static const defaultFont = TFonts.inter;

  // ── Fournisseurs de police injectables ────────────────────────────────────
  // L'indirection permet de swapper la typographie à chaud ou en test sans
  // toucher au reste du thème.
  static TextStyle Function({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  })
  titleFontProvider = _defaultTitleFont;

  static TextStyle Function({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  })
  bodyFontProvider = _defaultBodyFont;

  static TextStyle _defaultTitleFont({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) => GoogleFonts.bricolageGrotesque(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
  );

  /// Corps de texte en Inter.
  ///
  /// `GoogleFonts` est utilisé plutôt qu'un `fontFamily` système car l'app cible
  /// aussi Windows, où les polices d'Apple ('SF Pro') n'existent pas. Les `.ttf`
  /// déposés dans `assets/google_fonts/` sont pris en priorité par le package,
  /// ce qui évite tout téléchargement au démarrage.
  static TextStyle _defaultBodyFont({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) => GoogleFonts.inter(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
  );

  /// Restaure les fournisseurs par défaut (utile après un override en test).
  static void resetFontProviders() {
    titleFontProvider = _defaultTitleFont;
    bodyFontProvider = _defaultBodyFont;
  }

  static TextTheme getTextTheme({required bool isDark}) {
    final textColor = isDark
        ? AppColors.textColorDark
        : AppColors.textColorLight;
    final subTextColor = isDark
        ? AppColors.subTextColorDark
        : AppColors.subTextColorLight;

    return TextTheme(
      headlineLarge: titleFontProvider(
        color: textColor,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      ),
      headlineMedium: titleFontProvider(
        color: textColor,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      ),
      headlineSmall: titleFontProvider(
        color: textColor,
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
      titleLarge: titleFontProvider(
        color: textColor,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
      titleMedium: bodyFontProvider(
        color: textColor,
        fontSize: 15,
        fontWeight: FontWeight.w600,
      ),
      titleSmall: bodyFontProvider(
        color: textColor,
        fontSize: 14,
        fontWeight: FontWeight.w500,
      ),
      bodyLarge: bodyFontProvider(color: textColor, fontSize: 16),
      bodyMedium: bodyFontProvider(color: textColor, fontSize: 14),
      bodySmall: bodyFontProvider(color: subTextColor, fontSize: 12),
      labelLarge: bodyFontProvider(
        color: textColor,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
      labelMedium: bodyFontProvider(color: subTextColor, fontSize: 12),
      labelSmall: bodyFontProvider(color: subTextColor, fontSize: 11),
    );
  }

  static TextStyle titleStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) => titleFontProvider(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
  );

  static TextStyle bodyStyle({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) => bodyFontProvider(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    height: height,
  );

  static TextTheme get lightTextTheme => getTextTheme(isDark: false);
  static TextTheme get darkTextTheme => getTextTheme(isDark: true);
}
