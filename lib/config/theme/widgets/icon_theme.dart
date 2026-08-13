import 'package:flutter/material.dart';
import '../app_colors.dart';

class TIconTheme {
  TIconTheme._();

  static IconThemeData lightThemeIconTheme = const IconThemeData(
    color: AppColors.textColorLight,
    size: 24,
    opacity: 1,
  );

  static IconThemeData darkThemeIconTheme = const IconThemeData(
    color: AppColors.textColorDark,
    size: 24,
    opacity: 1,
  );
}
