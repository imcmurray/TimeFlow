import 'package:flutter/material.dart';
import 'package:timeflow/core/theme/app_colors.dart';

/// App theme configuration following the TimeFlow design system.
///
/// The theme embodies a calm, minimalist, nature-inspired aesthetic
/// reminiscent of flowing water.
class AppTheme {
  AppTheme._();

  /// Bundled in assets/fonts (SIL Open Font License).
  static const fontFamily = 'Nunito';

  /// Light theme for TimeFlow.
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: AppColors.primaryInk,
        primaryContainer: AppColors.primaryBlueLight,
        onPrimaryContainer: const Color(0xFF0D3C61),
        secondary: AppColors.secondaryGreen,
        secondaryContainer: AppColors.secondaryGreenLight,
        onSecondaryContainer: const Color(0xFF1B5E20),
        tertiary: AppColors.accentCoral,
        tertiaryContainer: AppColors.accentCoralLight,
        onTertiaryContainer: const Color(0xFF7A2E0E),
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
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shadowColor: AppColors.primaryBlue.withValues(alpha: 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryInk,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        bodyLarge: TextStyle(color: AppColors.textPrimary),
        bodyMedium: TextStyle(color: AppColors.textSecondary),
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
      fontFamily: fontFamily,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: AppColors.primaryInkDark,
        onPrimary: AppColors.onPrimaryDark,
        primaryContainer: AppColors.primaryBlue.withValues(alpha: 0.3),
        onPrimaryContainer: const Color(0xFFD6E9FB),
        secondary: AppColors.secondaryGreen,
        secondaryContainer: AppColors.secondaryGreen.withValues(alpha: 0.3),
        onSecondaryContainer: const Color(0xFFDDF2DE),
        tertiary: AppColors.accentCoral,
        tertiaryContainer: AppColors.accentCoral.withValues(alpha: 0.3),
        onTertiaryContainer: const Color(0xFFFFE0D4),
        surface: AppColors.backgroundDark,
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
      cardTheme: CardThemeData(
        color: AppColors.cardDark,
        elevation: 2,
        shadowColor: Colors.black26,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primaryInkDark,
        foregroundColor: AppColors.onPrimaryDark,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
        bodyLarge: TextStyle(color: AppColors.textLightPrimary),
        bodyMedium: TextStyle(color: AppColors.textLightSecondary),
        labelLarge: TextStyle(
          color: AppColors.textLightPrimary,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
