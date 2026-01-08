import 'package:flutter/material.dart';
import 'package:timeflow/core/theme/app_colors.dart';

/// App theme configuration following the TimeFlow design system.
///
/// The theme embodies a calm, minimalist, nature-inspired aesthetic
/// reminiscent of flowing water.
class AppTheme {
  AppTheme._();

  /// Light theme for TimeFlow.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryBlue,
        primaryContainer: AppColors.primaryBlueLight,
        secondary: AppColors.secondaryGreen,
        secondaryContainer: AppColors.secondaryGreenLight,
        tertiary: AppColors.accentCoral,
        tertiaryContainer: AppColors.accentCoralLight,
        surface: AppColors.backgroundLight,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textPrimary,
      ),
      scaffoldBackgroundColor: AppColors.backgroundLight,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundLight,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardTheme(
        color: Colors.white,
        elevation: 2,
        shadowColor: AppColors.primaryBlue.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textPrimary,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textSecondary,
        ),
        labelLarge: TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  /// Dark theme for TimeFlow.
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryBlue,
        primaryContainer: AppColors.primaryBlue.withOpacity(0.3),
        secondary: AppColors.secondaryGreen,
        secondaryContainer: AppColors.secondaryGreen.withOpacity(0.3),
        tertiary: AppColors.accentCoral,
        tertiaryContainer: AppColors.accentCoral.withOpacity(0.3),
        surface: AppColors.backgroundDark,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: AppColors.textLightPrimary,
      ),
      scaffoldBackgroundColor: AppColors.backgroundDark,
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.backgroundDark,
        foregroundColor: AppColors.textLightPrimary,
        elevation: 0,
        centerTitle: true,
      ),
      cardTheme: CardTheme(
        color: AppColors.cardDark,
        elevation: 2,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
      textTheme: const TextTheme(
        headlineLarge: TextStyle(
          color: AppColors.textLightPrimary,
          fontWeight: FontWeight.bold,
        ),
        headlineMedium: TextStyle(
          color: AppColors.textLightPrimary,
          fontWeight: FontWeight.w600,
        ),
        bodyLarge: TextStyle(
          color: AppColors.textLightPrimary,
        ),
        bodyMedium: TextStyle(
          color: AppColors.textLightSecondary,
        ),
        labelLarge: TextStyle(
          color: AppColors.textLightPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
