import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:timeflow/services/holidays_service.dart';

/// Large watermark date displayed in the background of each day.
/// Shows a big day number that's semi-transparent so tasks can overlay it.
/// Supports brightness boost on hover/tap via [isHighlighted].
class DayWatermark extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final double height;
  final bool showWeekNumber;
  final bool showDayOfYear;
  final bool showHolidays;
  final bool showMoonPhase;
  final bool showQuarter;
  final bool showDaysRemaining;

  /// When true, displays watermark at higher opacity (brighter)
  final bool isHighlighted;

  const DayWatermark({
    super.key,
    required this.date,
    required this.isToday,
    required this.height,
    this.showWeekNumber = true,
    this.showDayOfYear = false,
    this.showHolidays = true,
    this.showMoonPhase = false,
    this.showQuarter = false,
    this.showDaysRemaining = false,
    this.isHighlighted = false,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Large day number
    final dayNumber = date.day.toString();
    final dayName = DateFormat('EEEE').format(date);

    // Opacity multiplier for highlighted state (3x brighter when highlighted)
    final opacityMultiplier = isHighlighted ? 3.0 : 1.0;

    // Color for the watermark - subtle but visible, boosted when highlighted
    final baseWatermarkOpacity =
        isToday ? (isDark ? 0.12 : 0.08) : (isDark ? 0.04 : 0.03);
    final watermarkColor = isToday
        ? colorScheme.primary.withValues(
            alpha: (baseWatermarkOpacity * opacityMultiplier).clamp(0.0, 0.5))
        : (isDark
            ? Colors.white.withValues(
                alpha:
                    (baseWatermarkOpacity * opacityMultiplier).clamp(0.0, 0.3))
            : Colors.black.withValues(
                alpha: (baseWatermarkOpacity * opacityMultiplier)
                    .clamp(0.0, 0.2)));

    // Slightly more visible color for secondary info
    final baseSecondaryOpacity =
        isToday ? (isDark ? 0.10 : 0.06) : (isDark ? 0.03 : 0.025);
    final secondaryColor = isToday
        ? colorScheme.primary.withValues(
            alpha: (baseSecondaryOpacity * opacityMultiplier).clamp(0.0, 0.4))
        : (isDark
            ? Colors.white.withValues(
                alpha:
                    (baseSecondaryOpacity * opacityMultiplier).clamp(0.0, 0.25))
            : Colors.black.withValues(
                alpha: (baseSecondaryOpacity * opacityMultiplier)
                    .clamp(0.0, 0.15)));

    // Holiday color (more prominent)
    final baseHolidayOpacity =
        isToday ? (isDark ? 0.18 : 0.12) : (isDark ? 0.12 : 0.18);
    final holidayColor = isToday
        ? colorScheme.primary.withValues(
            alpha: (baseHolidayOpacity * opacityMultiplier).clamp(0.0, 0.6))
        : (isDark
            ? Colors.amber.withValues(
                alpha: (baseHolidayOpacity * opacityMultiplier).clamp(0.0, 0.5))
            : Colors.amber.withValues(
                alpha:
                    (baseHolidayOpacity * opacityMultiplier).clamp(0.0, 0.5)));

    // Build the secondary info line (Week X • Q1 • Day 28)
    final infoParts = <String>[];

    if (showWeekNumber) {
      final weekNum = HolidaysService.getWeekNumber(date);
      infoParts.add('WEEK $weekNum');
    }

    if (showQuarter) {
      final quarter = HolidaysService.getQuarter(date);
      infoParts.add('Q$quarter');
    }

    if (showDayOfYear) {
      final dayOfYear = HolidaysService.getDayOfYear(date);
      infoParts.add('DAY $dayOfYear');
    }

    if (showDaysRemaining) {
      final remaining = HolidaysService.getDaysRemainingInYear(date);
      infoParts.add('$remaining LEFT');
    }

    // Holiday name
    String? holidayName;
    if (showHolidays) {
      holidayName = HolidaysService.getShortHolidayName(date);
    }

    // Moon phase
    String? moonPhase;
    if (showMoonPhase) {
      moonPhase = HolidaysService.getMoonPhaseEmoji(date);
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      height: height,
      child: Stack(
        children: [
          // Large day number watermark
          Positioned(
            left: 0,
            right: 0,
            top: 10,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Big day number
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      fontSize: 120,
                      fontWeight: FontWeight.w800,
                      color: watermarkColor,
                      height: 1.0,
                    ),
                    child: Text(dayNumber),
                  ),

                  // Day name
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 300),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 6,
                      color: watermarkColor,
                    ),
                    child: Text(dayName.toUpperCase()),
                  ),

                  // Holiday name (if any) - slightly more prominent
                  if (holidayName != null) ...[
                    const SizedBox(height: 12),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 3,
                        color: holidayColor,
                      ),
                      child: Text(holidayName.toUpperCase()),
                    ),
                  ],

                  // Secondary info line (Week • Quarter • Day of Year)
                  if (infoParts.isNotEmpty) ...[
                    SizedBox(height: holidayName != null ? 12 : 20),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 3,
                        color: secondaryColor,
                      ),
                      child: Text(infoParts.join('  •  ')),
                    ),
                  ],

                  // Moon phase on its own line
                  if (moonPhase != null) ...[
                    const SizedBox(height: 12),
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 300),
                      style: TextStyle(
                        fontSize: 28,
                        color: secondaryColor,
                      ),
                      child: Text(moonPhase),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
