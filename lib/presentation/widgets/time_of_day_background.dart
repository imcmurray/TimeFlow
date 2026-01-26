import 'package:flutter/material.dart';

/// A gradient background that changes based on the time of day.
///
/// Creates an ambient atmosphere that reflects the natural
/// progression of daylight - from dawn pink through day blue
/// to dusk amber and night indigo.
class TimeOfDayBackground extends StatelessWidget {
  /// The current hour (0-23) to determine the color scheme.
  final int hour;

  /// Whether to use dark mode variants.
  final bool isDark;

  /// Child widget to display over the background.
  final Widget? child;

  const TimeOfDayBackground({
    super.key,
    required this.hour,
    required this.isDark,
    this.child,
  });

  @override
  Widget build(BuildContext context) {
    final colors = _getGradientColors();

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: child,
    );
  }

  List<Color> _getGradientColors() {
    // Time periods and their colors
    // Dawn: 5-7 AM - Pink/orange sunrise
    // Morning: 7-12 PM - Bright blue
    // Afternoon: 12-17 PM - Warm blue
    // Dusk: 17-20 PM - Amber/orange sunset
    // Night: 20-5 AM - Deep indigo/purple

    if (isDark) {
      return _getDarkModeColors();
    }

    if (hour >= 5 && hour < 7) {
      // Dawn - soft pink and orange
      return [
        const Color(0xFFFFF0E6), // Soft peach
        const Color(0xFFFFE4D6), // Light coral
        const Color(0xFFFFF5EE), // Seashell
      ];
    } else if (hour >= 7 && hour < 12) {
      // Morning - fresh blue
      return [
        const Color(0xFFE8F4FD), // Light sky blue
        const Color(0xFFF0F7FF), // Alice blue
        const Color(0xFFFAFCFF), // Near white blue
      ];
    } else if (hour >= 12 && hour < 17) {
      // Afternoon - warm light blue
      return [
        const Color(0xFFF5F9FC), // Soft blue white
        const Color(0xFFFAFBFD), // Very light blue
        const Color(0xFFFFFFFD), // Warm white
      ];
    } else if (hour >= 17 && hour < 20) {
      // Dusk - amber and orange
      return [
        const Color(0xFFFFF8E7), // Warm cream
        const Color(0xFFFFF3E0), // Light orange
        const Color(0xFFFFFAF0), // Floral white
      ];
    } else {
      // Night - soft indigo
      return [
        const Color(0xFFF0F0F8), // Lavender mist
        const Color(0xFFF5F5FA), // Ghost white
        const Color(0xFFFAFAFC), // Light lavender
      ];
    }
  }

  List<Color> _getDarkModeColors() {
    if (hour >= 5 && hour < 7) {
      // Dawn - deep rose
      return [
        const Color(0xFF1A1418), // Deep rose black
        const Color(0xFF151214), // Dark rose
        const Color(0xFF121212), // Base dark
      ];
    } else if (hour >= 7 && hour < 12) {
      // Morning - cool blue dark
      return [
        const Color(0xFF0D1520), // Deep blue
        const Color(0xFF101418), // Blue black
        const Color(0xFF121212), // Base dark
      ];
    } else if (hour >= 12 && hour < 17) {
      // Afternoon - neutral dark
      return [
        const Color(0xFF141414), // Slightly warm dark
        const Color(0xFF121212), // Base dark
        const Color(0xFF111111), // Deep dark
      ];
    } else if (hour >= 17 && hour < 20) {
      // Dusk - warm amber dark
      return [
        const Color(0xFF1A1610), // Amber dark
        const Color(0xFF161412), // Warm dark
        const Color(0xFF121212), // Base dark
      ];
    } else {
      // Night - deep indigo
      return [
        const Color(0xFF0A0A14), // Deep indigo
        const Color(0xFF0D0D12), // Indigo black
        const Color(0xFF121212), // Base dark
      ];
    }
  }

  /// Get a label for the current time period.
  static String getTimePeriodLabel(int hour) {
    if (hour >= 5 && hour < 7) {
      return 'Dawn';
    } else if (hour >= 7 && hour < 12) {
      return 'Morning';
    } else if (hour >= 12 && hour < 17) {
      return 'Afternoon';
    } else if (hour >= 17 && hour < 20) {
      return 'Evening';
    } else {
      return 'Night';
    }
  }

  /// Get an icon for the current time period.
  static IconData getTimePeriodIcon(int hour) {
    if (hour >= 5 && hour < 7) {
      return Icons.wb_twilight;
    } else if (hour >= 7 && hour < 12) {
      return Icons.wb_sunny;
    } else if (hour >= 12 && hour < 17) {
      return Icons.light_mode;
    } else if (hour >= 17 && hour < 20) {
      return Icons.wb_twilight;
    } else {
      return Icons.nightlight_round;
    }
  }

  /// Get the accent color for the current time period.
  static Color getAccentColor(int hour, {bool isDark = false}) {
    if (hour >= 5 && hour < 7) {
      return isDark ? const Color(0xFFFFB088) : const Color(0xFFFF9966);
    } else if (hour >= 7 && hour < 12) {
      return isDark ? const Color(0xFF64B5F6) : const Color(0xFF42A5F5);
    } else if (hour >= 12 && hour < 17) {
      return isDark ? const Color(0xFF81C784) : const Color(0xFF66BB6A);
    } else if (hour >= 17 && hour < 20) {
      return isDark ? const Color(0xFFFFB74D) : const Color(0xFFFF9800);
    } else {
      return isDark ? const Color(0xFF9575CD) : const Color(0xFF7E57C2);
    }
  }
}
