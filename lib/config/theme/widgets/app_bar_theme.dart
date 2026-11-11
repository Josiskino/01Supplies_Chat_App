import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_colors.dart';

/// Thème des barres de titre.
///
/// ⚠️ `titleTextStyle` **remplace** le style par défaut de l'`AppBar`, il ne le
/// complète pas : n'y déclarer qu'une couleur laisse le titre retomber sur la
/// taille héritée du `DefaultTextStyle`, soit un titre minuscule. Taille et
/// graisse sont donc explicites — même piège que `copyWith(textTheme:)`.
class TAppBarTheme {
  TAppBarTheme._();

  /// Taille du titre de barre. Alignée sur `titleLarge` de Material 3.
  static const double _titleSize = 22;

  static AppBarTheme lightThemeAppBarTheme = const AppBarTheme(
    backgroundColor: AppColors.appBarColorLight,
    elevation: 1,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: AppColors.appBarColorLight,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
    ),
    iconTheme: IconThemeData(color: AppColors.primaryColorLight),
    titleTextStyle: TextStyle(
      color: Colors.black,
      fontSize: _titleSize,
      fontWeight: FontWeight.w600,
    ),
  );

  static AppBarTheme darkThemeAppBarTheme = const AppBarTheme(
    backgroundColor: AppColors.appBarColorDark,
    elevation: 1,
    scrolledUnderElevation: 0,
    surfaceTintColor: Colors.transparent,
    systemOverlayStyle: SystemUiOverlayStyle(
      statusBarColor: AppColors.appBarColorDark,
      statusBarIconBrightness: Brightness.light,
      statusBarBrightness: Brightness.dark,
    ),
    iconTheme: IconThemeData(color: AppColors.primaryColorDark),
    titleTextStyle: TextStyle(
      color: Colors.white,
      fontSize: _titleSize,
      fontWeight: FontWeight.w600,
    ),
  );
}
