import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../app_colors.dart';

enum TFonts {
  sfPro('SF Pro'),
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

  /// Corps de texte, aligné sur l'app cliente : `SF Pro`.
  ///
  /// La famille n'est **pas** déclarée en asset, exactement comme chez le client.
  /// Sur iOS et macOS, le nom résout vers San Francisco, la police système ; le
  /// texte y est donc identique à celui de l'app cliente, ce qui est le but.
  ///
  /// Ailleurs, le nom ne résout pas — d'où la chaîne de repli explicite, et non
  /// un silence qui laisserait Flutter retomber sur sa police par défaut :
  /// Segoe UI Variable sur Windows, Roboto sur Android. Ce sont les polices
  /// système de ces plateformes, ce qui reste le comportement attendu.
  ///
  /// Le corps ne passe donc pas par `GoogleFonts`, contrairement aux titres : une
  /// police système ne se télécharge pas et s'affiche dès la première image.
  static TextStyle _defaultBodyFont({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? height,
  }) => TextStyle(
    fontFamily: TFonts.sfPro.value,
    fontFamilyFallback: const [
      '.SF Pro Text',
      'Segoe UI Variable',
      'Segoe UI',
      'Roboto',
    ],
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
