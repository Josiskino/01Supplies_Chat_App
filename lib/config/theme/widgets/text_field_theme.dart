import 'package:flutter/material.dart';
import '../app_colors.dart';

class TTextFormFieldTheme {
  TTextFormFieldTheme._();

  // ─────────────────────────────────────────────────────────────────────────
  // Light
  // ─────────────────────────────────────────────────────────────────────────

  static InputDecorationTheme lightThemeDecorationTheme = InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.containerColorLight),
    ),
    labelStyle: const TextStyle(color: AppColors.textColorLight),
    prefixIconColor: AppColors.textColorLight,
    suffixIconColor: AppColors.textColorLight,
    floatingLabelStyle: const TextStyle(color: AppColors.primaryColorLight),
    focusedBorder: const OutlineInputBorder(
      borderSide: BorderSide(width: 2, color: AppColors.secondaryColorLight),
    ),
    enabledBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.containerColorLight),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.red.shade300),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderSide: BorderSide(width: 2, color: Colors.red.shade300),
    ),
  );

  // ─────────────────────────────────────────────────────────────────────────
  // Dark
  // ─────────────────────────────────────────────────────────────────────────

  static InputDecorationTheme darkThemeDecorationTheme = InputDecorationTheme(
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: AppColors.containerColorDark),
    ),
    labelStyle: const TextStyle(color: AppColors.textColorDark),
    prefixIconColor: AppColors.textColorDark,
    suffixIconColor: AppColors.textColorDark,
    floatingLabelStyle: const TextStyle(color: AppColors.primaryColorDark),
    focusedBorder: const OutlineInputBorder(
      borderSide: BorderSide(width: 2, color: AppColors.secondaryColorDark),
    ),
    enabledBorder: const OutlineInputBorder(
      borderSide: BorderSide(color: AppColors.containerColorDark),
    ),
    errorBorder: OutlineInputBorder(
      borderSide: BorderSide(color: Colors.red.shade300),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderSide: BorderSide(width: 2, color: Colors.red.shade300),
    ),
  );
}
