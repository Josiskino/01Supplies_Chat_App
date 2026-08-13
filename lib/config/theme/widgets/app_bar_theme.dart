import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../app_colors.dart';

class TAppBarTheme {
  TAppBarTheme._();

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
    titleTextStyle: TextStyle(color: AppColors.primaryColorLight),
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
    titleTextStyle: TextStyle(color: AppColors.primaryColorDark),
  );
}
