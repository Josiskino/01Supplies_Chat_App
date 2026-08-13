import 'package:flutter/material.dart';

import '../responsive/breakpoints.dart';

extension ThemeExtension on BuildContext {
  ThemeData get theme => Theme.of(this);
  TextTheme get textTheme => theme.textTheme;
  ColorScheme get colors => theme.colorScheme;
  AppBarThemeData get appBarTheme => theme.appBarTheme;
  bool get isDarkMode => theme.brightness == Brightness.dark;
  Color get primaryColor => theme.primaryColor;
  Color get surfaceColor => theme.colorScheme.surface;
  Color get errorColor => theme.colorScheme.error;
  Color get onErrorColor => theme.colorScheme.onError;
}

extension MediaQueryExtension on BuildContext {
  Size get screenSize => MediaQuery.sizeOf(this);
  double get width => screenSize.width;
  double get height => screenSize.height;
  EdgeInsets get viewPadding => MediaQuery.viewPaddingOf(this);
  bool get isLandscape =>
      MediaQuery.orientationOf(this) == Orientation.landscape;
}

/// Raccourcis responsive.
///
/// Basés sur la largeur de la fenêtre, jamais sur la plateforme : une fenêtre
/// macOS réduite doit se comporter comme un mobile, et une tablette Android en
/// paysage comme un desktop.
extension ResponsiveExtension on BuildContext {
  FormFactor get formFactor => Breakpoints.formFactorOf(width);
  bool get isCompact => formFactor == FormFactor.compact;
  bool get isMedium => formFactor == FormFactor.medium;
  bool get isExpanded => formFactor == FormFactor.expanded;

  /// La navigation latérale remplace la barre du bas dès le format medium.
  bool get usesLateralNavigation => !isCompact;
}
