import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

class AppThemes {
  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.backgroundLight,
    fontFamily: AppTextStyles.fontFamily,
    colorScheme: const ColorScheme.light(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.backgroundLight,
      onSurface: AppColors.foregroundLight,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: AppTextStyles.text3xl,
        color: AppColors.slate900,
      ),
      headlineMedium: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: AppTextStyles.text2xl,
        color: AppColors.slate900,
      ),
      headlineSmall: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: AppTextStyles.textXl,
        color: AppColors.slate900,
      ),
      bodyLarge: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: AppTextStyles.textBase,
        color: AppColors.foregroundLight,
      ),
      bodyMedium: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: AppTextStyles.textSm,
        color: AppColors.gray500,
      ),
      bodySmall: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: AppTextStyles.textXs,
        color: AppColors.gray500,
      ),
    ),
  );

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: AppColors.primary,
    scaffoldBackgroundColor: AppColors.backgroundDark,
    fontFamily: AppTextStyles.fontFamily,
    colorScheme: const ColorScheme.dark(
      primary: AppColors.primary,
      secondary: AppColors.accent,
      surface: AppColors.backgroundDark,
      onSurface: AppColors.foregroundDark,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: AppTextStyles.text3xl,
        color: AppColors.foregroundDark,
      ),
      headlineMedium: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: AppTextStyles.text2xl,
        color: AppColors.foregroundDark,
      ),
      headlineSmall: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: AppTextStyles.textXl,
        color: AppColors.foregroundDark,
      ),
      bodyLarge: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: AppTextStyles.textBase,
        color: AppColors.foregroundDark,
      ),
      bodyMedium: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: AppTextStyles.textSm,
        color: AppColors.gray400,
      ),
      bodySmall: TextStyle(
        fontFamily: AppTextStyles.fontFamily,
        fontSize: AppTextStyles.textXs,
        color: AppColors.gray400,
      ),
    ),
  );
}