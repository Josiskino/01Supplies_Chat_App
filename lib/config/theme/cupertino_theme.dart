import 'package:flutter/cupertino.dart';

import 'app_colors.dart';
import 'widgets/text_theme.dart';

/// Thème Cupertino, dérivé de la même palette que le thème Material.
///
/// Deux systèmes de design, **une seule identité de marque** : le violet et
/// l'orange 01Supplies sont identiques sur les deux, seules les conventions de
/// rendu changent. Repartir des couleurs système d'iOS donnerait deux apps
/// visuellement différentes, ce qui n'est pas le but — on veut le *vocabulaire*
/// d'iOS, pas son identité.
///
/// Provisoire jusqu'à réception de la maquette iOS : les valeurs viennent de la
/// palette existante, et c'est ce fichier qu'il faudra ajuster.
class TCupertinoTheme {
  TCupertinoTheme._();

  static CupertinoThemeData get lightTheme => CupertinoThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primaryColorLight,
    primaryContrastingColor: CupertinoColors.white,
    scaffoldBackgroundColor: AppColors.backgroundColorLight,
    barBackgroundColor: AppColors.appBarColorLight,
    applyThemeToAll: true,
    textTheme: _textTheme(isDark: false),
  );

  static CupertinoThemeData get darkTheme => CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primaryColorDark,
    primaryContrastingColor: CupertinoColors.white,
    scaffoldBackgroundColor: AppColors.backgroundColorDark,
    barBackgroundColor: AppColors.appBarColorDark,
    applyThemeToAll: true,
    textTheme: _textTheme(isDark: true),
  );

  /// Réutilise les fournisseurs de police du thème Material.
  ///
  /// La typographie ne doit pas diverger entre les plateformes : c'est un
  /// marqueur d'identité, pas une convention système. Seules les tailles suivent
  /// les habitudes d'iOS (17 pt pour le corps de texte).
  static CupertinoTextThemeData _textTheme({required bool isDark}) {
    final textColor = isDark
        ? AppColors.textColorDark
        : AppColors.textColorLight;
    final primaryColor = isDark
        ? AppColors.primaryColorDark
        : AppColors.primaryColorLight;

    return CupertinoTextThemeData(
      primaryColor: primaryColor,
      textStyle: TTextTheme.bodyStyle(fontSize: 17, color: textColor),
      actionTextStyle: TTextTheme.bodyStyle(fontSize: 17, color: primaryColor),
      navTitleTextStyle: TTextTheme.titleStyle(
        fontSize: 17,
        fontWeight: FontWeight.w600,
        color: textColor,
      ),
      navLargeTitleTextStyle: TTextTheme.titleStyle(
        fontSize: 34,
        fontWeight: FontWeight.bold,
        color: textColor,
      ),
      navActionTextStyle: TTextTheme.bodyStyle(
        fontSize: 17,
        color: primaryColor,
      ),
      tabLabelTextStyle: TTextTheme.bodyStyle(fontSize: 10, color: textColor),
      pickerTextStyle: TTextTheme.bodyStyle(fontSize: 21, color: textColor),
      dateTimePickerTextStyle: TTextTheme.bodyStyle(
        fontSize: 21,
        color: textColor,
      ),
    );
  }
}
