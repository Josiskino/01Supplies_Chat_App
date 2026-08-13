import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../core/services/storage_service.dart';
import 'app_colors.dart';
import 'widgets/app_bar_theme.dart';
import 'widgets/elevated_button_theme.dart';
import 'widgets/icon_theme.dart';
import 'widgets/outlined_button_theme.dart';
import 'widgets/text_field_theme.dart';
import 'widgets/text_theme.dart';

part 'theme.g.dart';

/// Gère le thème de l'application. L'état est persisté en SharedPreferences.
///
/// `keepAlive` : préférence globale, lue de façon asynchrone. En auto-dispose, la
/// lecture pourrait se terminer sur un provider déjà détruit, et le thème
/// repartirait sur `system` à chaque remontage de l'arbre.
@Riverpod(keepAlive: true)
class ThemeNotifier extends _$ThemeNotifier {
  @override
  ThemeMode build() {
    // Chargement asynchrone non bloquant : l'app démarre sur le thème système
    // puis bascule dès que la préférence est lue.
    _loadTheme();
    return ThemeMode.system;
  }

  Future<void> _loadTheme() async {
    final savedTheme = await StorageService.instance.getThemeMode();
    if (!ref.mounted) return;
    if (savedTheme != null) {
      state = switch (savedTheme) {
        'dark' => ThemeMode.dark,
        'light' => ThemeMode.light,
        _ => ThemeMode.system,
      };
      _updateSystemOverlayStyle();
    }
  }

  void toggleTheme() {
    state = state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    _updateSystemOverlayStyle();
    _saveTheme();
  }

  void setThemeMode(ThemeMode mode) {
    state = mode;
    _updateSystemOverlayStyle();
    _saveTheme();
  }

  void _saveTheme() {
    final themeString = switch (state) {
      ThemeMode.dark => 'dark',
      ThemeMode.light => 'light',
      ThemeMode.system => 'system',
    };
    StorageService.instance.saveThemeMode(themeString);
  }

  /// Aligne la barre de statut sur le thème.
  ///
  /// Sans effet — et sans erreur — hors mobile : `SystemChrome` ne pilote rien
  /// sur desktop, on évite donc l'appel plutôt que de compter sur un no-op.
  void _updateSystemOverlayStyle() {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) return;

    Future.microtask(() {
      SystemChrome.setSystemUIOverlayStyle(
        state == ThemeMode.light
            ? const SystemUiOverlayStyle(
                statusBarColor: AppColors.appBarColorLight,
                statusBarIconBrightness: Brightness.dark,
                statusBarBrightness: Brightness.light,
              )
            : const SystemUiOverlayStyle(
                statusBarColor: AppColors.appBarColorDark,
                statusBarIconBrightness: Brightness.light,
                statusBarBrightness: Brightness.dark,
              ),
      );
    });
  }
}

class TAppTheme {
  TAppTheme._();

  /// Fusionne notre TextTheme avec celui du thème de base au lieu de le
  /// remplacer.
  ///
  /// `copyWith(textTheme:)` écrase intégralement le TextTheme : les styles que
  /// [TTextTheme] ne définirait pas se retrouveraient avec une géométrie mais
  /// sans couleur → peints en blanc, donc invisibles en thème clair. Ce piège a
  /// déjà coûté un bug de production sur l'app cliente ; le `merge` le neutralise
  /// définitivement, y compris si un style est ajouté plus tard au framework.
  static TextTheme _mergedTextTheme(TextTheme base, TextTheme custom) =>
      base.merge(custom);

  /// Thème de base portant la police du corps de texte.
  ///
  /// La famille est posée sur le `ThemeData` lui-même, pas seulement dans le
  /// `TextTheme` : sans cela, tout `TextStyle` écrit à la main dans un écran —
  /// le champ de saisie de la connexion, le libellé d'un bouton — retombe sur la
  /// police par défaut de Flutter. Le résultat est une interface où la moitié des
  /// textes sont dans la bonne police et l'autre non, sans qu'on voie pourquoi.
  ///
  /// `copyWith` n'expose pas `fontFamily`, d'où cette construction en amont
  /// plutôt qu'un ajout aux surcharges existantes.
  static ThemeData _baseWith(Brightness brightness) => ThemeData(
    brightness: brightness,
    fontFamily: TFonts.sfPro.value,
    fontFamilyFallback: const [
      '.SF Pro Text',
      'Segoe UI Variable',
      'Segoe UI',
      'Roboto',
    ],
  );

  static ThemeData lightThemeData(BuildContext context) {
    final base = _baseWith(Brightness.light);
    return base.copyWith(
      primaryColor: AppColors.primaryColorLight,
      primaryColorLight: AppColors.secondaryColorLight,
      scaffoldBackgroundColor: AppColors.backgroundColorLight,
      appBarTheme: TAppBarTheme.lightThemeAppBarTheme,
      iconTheme: TIconTheme.lightThemeIconTheme,
      textTheme: _mergedTextTheme(base.textTheme, TTextTheme.lightTextTheme),
      elevatedButtonTheme: TElevatedButtonTheme.lightElevatedButtonTheme,
      outlinedButtonTheme: TOutlinedButtonTheme.lightOutlinedButtonTheme,
      inputDecorationTheme: TTextFormFieldTheme.lightThemeDecorationTheme,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primaryColorLight,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFFEFECFF),
        onPrimaryContainer: AppColors.primaryColorLight,
        secondary: AppColors.secondaryColorLight,
        secondaryContainer: Color(0xFFEFECFF),
        onSecondaryContainer: AppColors.onSurfaceColorLight,
        surface: AppColors.surfaceColorLight,
        onSurface: AppColors.onSurfaceColorLight,
        error: Colors.red,
      ),
    );
  }

  static ThemeData darkThemeData(BuildContext context) {
    final base = _baseWith(Brightness.dark);
    return base.copyWith(
      primaryColor: AppColors.primaryColorDark,
      primaryColorLight: AppColors.secondaryColorDark,
      scaffoldBackgroundColor: AppColors.backgroundColorDark,
      appBarTheme: TAppBarTheme.darkThemeAppBarTheme,
      iconTheme: TIconTheme.darkThemeIconTheme,
      textTheme: _mergedTextTheme(base.textTheme, TTextTheme.darkTextTheme),
      elevatedButtonTheme: TElevatedButtonTheme.darkElevatedButtonTheme,
      outlinedButtonTheme: TOutlinedButtonTheme.darkOutlinedButtonTheme,
      inputDecorationTheme: TTextFormFieldTheme.darkThemeDecorationTheme,
      colorScheme: const ColorScheme.dark(
        primary: AppColors.primaryColorDark,
        onPrimary: Colors.white,
        primaryContainer: Color(0xFF352675),
        onPrimaryContainer: Color(0xFFB3C7FF),
        secondary: AppColors.secondaryColorDark,
        secondaryContainer: Color(0xFF352675),
        onSecondaryContainer: AppColors.onSurfaceColorDark,
        surface: AppColors.surfaceColorDark,
        onSurface: AppColors.onSurfaceColorDark,
        error: Colors.red,
      ),
    );
  }
}
