import 'package:flutter/material.dart';

/// Color palette for TimeFlow following the design specification.
///
/// Calm, minimalist, nature-inspired aesthetic reminiscent of flowing water.
class AppColors {
  AppColors._();

  // Primary Blues - Soft, calming water tones
  static const Color primaryBlueLight = Color(0xFFE3F2FD);
  static const Color primaryBlue = Color(0xFF42A5F5);
  static const Color primaryBlueDark = Color(0xFF1976D2);

  // Secondary Greens - Gentle, natural tones
  static const Color secondaryGreenLight = Color(0xFFE8F5E9);
  static const Color secondaryGreen = Color(0xFF66BB6A);
  static const Color secondaryGreenDark = Color(0xFF388E3C);

  // Accent Coral - Warm highlights for important items
  static const Color accentCoralLight = Color(0xFFFFCCBC);
  static const Color accentCoral = Color(0xFFFF7043);
  static const Color accentCoralDark = Color(0xFFE64A19);

  // Background Colors
  static const Color backgroundLight = Color(0xFFFAFAFA);
  static const Color backgroundDark = Color(0xFF121212);
  static const Color cardDark = Color(0xFF1E1E1E);

  // Text Colors - Light Theme
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textTertiary = Color(0xFF9E9E9E);

  // Text Colors - Dark Theme
  static const Color textLightPrimary = Color(0xFFFAFAFA);
  static const Color textLightSecondary = Color(0xFFB0B0B0);
  static const Color textLightTertiary = Color(0xFF757575);

  // NOW Line Colors
  static const Color nowLineLight = Color(0xFF42A5F5);
  static const Color nowLineDark = Color(0xFF64B5F6);
  static const Color nowLineGlow = Color(0x4042A5F5);

  // Task Status Colors
  static const Color taskCompleted = Color(0xFF66BB6A);
  static const Color taskUpcoming = Color(0xFF42A5F5);
  static const Color taskCurrent = Color(0xFFFFB74D);
  static const Color taskOverdue = Color(0xFFEF5350);

  // Timeline Colors
  static const Color timelineLight = Color(0xFFE0E0E0);
  static const Color timelineDark = Color(0xFF424242);
  static const Color hourMarkerLight = Color(0xFF9E9E9E);
  static const Color hourMarkerDark = Color(0xFF757575);

  // Overlay and Shadow
  static const Color shadowLight = Color(0x1A000000);
  static const Color shadowDark = Color(0x40000000);
  static const Color overlayLight = Color(0x80FFFFFF);
  static const Color overlayDark = Color(0x80000000);
}
