import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Visual marker indicating day boundaries with sunrise/sunset theming.
///
/// Shows the start of a new day with contextual icons (sunrise for morning,
/// sunset for evening) and friendly date labels.
class DayBoundaryMarker extends StatelessWidget {
  /// The date this marker represents.
  final DateTime date;

  /// Whether this is today's marker.
  final bool isToday;

  /// Whether to show the sunrise variant (true) or sunset variant (false).
  /// Sunrise is shown at midnight/start of day, sunset at end of day.
  final bool isSunrise;

  const DayBoundaryMarker({
    super.key,
    required this.date,
    required this.isToday,
    this.isSunrise = true,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final icon = isSunrise ? Icons.wb_sunny : Icons.nightlight_round;
    final gradientColors = isSunrise
        ? [
            isDark ? const Color(0xFF1A1A2E) : const Color(0xFFFFF8E1),
            isDark ? const Color(0xFF16213E) : const Color(0xFFFFECB3),
          ]
        : [
            isDark ? const Color(0xFF1A1A2E) : const Color(0xFFE3F2FD),
            isDark ? const Color(0xFF0F0F1A) : const Color(0xFFE8EAF6),
          ];

    final iconColor = isSunrise
        ? (isDark ? const Color(0xFFFFB74D) : const Color(0xFFFF9800))
        : (isDark ? const Color(0xFF7986CB) : const Color(0xFF5C6BC0));

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          // Left line
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.outlineVariant.withOpacity(0.0),
                    colorScheme.outlineVariant.withOpacity(0.5),
                  ],
                ),
              ),
            ),
          ),

          // Center badge with icon and date
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 12),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: gradientColors,
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isToday
                    ? colorScheme.primary.withOpacity(0.5)
                    : colorScheme.outlineVariant.withOpacity(0.3),
                width: isToday ? 2 : 1,
              ),
              boxShadow: [
                if (isToday)
                  BoxShadow(
                    color: colorScheme.primary.withOpacity(0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 18,
                  color: iconColor,
                ),
                const SizedBox(width: 8),
                Text(
                  _formatDayLabel(),
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                    color: isToday
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          // Right line
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    colorScheme.outlineVariant.withOpacity(0.5),
                    colorScheme.outlineVariant.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDayLabel() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final difference = targetDate.difference(today).inDays;

    if (difference == 0) {
      return 'Today';
    } else if (difference == 1) {
      return 'Tomorrow';
    } else if (difference == -1) {
      return 'Yesterday';
    } else if (difference > 1 && difference <= 6) {
      return DateFormat('EEEE').format(date); // Just day name for this week
    } else if (difference < -1 && difference >= -6) {
      return 'Last ${DateFormat('EEEE').format(date)}';
    }

    return DateFormat('EEE, MMM d').format(date);
  }
}

/// A simpler inline day divider with sunrise/sunset icon and gradient band.
class SimpleDayDivider extends StatelessWidget {
  final DateTime date;
  final bool isToday;

  const SimpleDayDivider({
    super.key,
    required this.date,
    required this.isToday,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Gradient colors for the band
    final bandColor = isToday
        ? (isDark ? colorScheme.primary.withOpacity(0.15) : colorScheme.primary.withOpacity(0.08))
        : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.03));

    final lineColor = isToday
        ? colorScheme.primary.withOpacity(0.6)
        : colorScheme.outlineVariant.withOpacity(0.5);

    final icon = Icons.wb_twilight;
    final iconColor = isDark
        ? const Color(0xFFFFB74D)
        : const Color(0xFFFF9800);

    return Container(
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            bandColor.withOpacity(0),
            bandColor,
            bandColor,
            bandColor.withOpacity(0),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Row(
        children: [
          // Left gradient line
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    lineColor.withOpacity(0),
                    lineColor,
                  ],
                ),
                boxShadow: isToday
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 4,
                        ),
                      ]
                    : null,
              ),
            ),
          ),

          // Center badge with icon and date
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isDark
                  ? (isToday ? colorScheme.primary.withOpacity(0.2) : Colors.grey[900]!.withOpacity(0.8))
                  : (isToday ? colorScheme.primary.withOpacity(0.1) : Colors.white.withOpacity(0.9)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isToday ? colorScheme.primary.withOpacity(0.5) : lineColor,
                width: isToday ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  icon,
                  size: 14,
                  color: iconColor,
                ),
                const SizedBox(width: 6),
                Text(
                  _formatDayLabel(),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                    color: isToday
                        ? colorScheme.primary
                        : colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          // Right gradient line
          Expanded(
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    lineColor,
                    lineColor.withOpacity(0),
                  ],
                ),
                boxShadow: isToday
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 4,
                        ),
                      ]
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDayLabel() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final difference = targetDate.difference(today).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference == -1) return 'Yesterday';

    return DateFormat('EEE, MMM d').format(date);
  }
}

/// Large watermark date displayed in the background of each day.
/// Shows a big day number that's semi-transparent so tasks can overlay it.
class DayWatermark extends StatelessWidget {
  final DateTime date;
  final bool isToday;
  final double height;

  const DayWatermark({
    super.key,
    required this.date,
    required this.isToday,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Large day number
    final dayNumber = date.day.toString();
    final dayName = DateFormat('EEEE').format(date);

    // Color for the watermark - subtle but visible
    final watermarkColor = isToday
        ? colorScheme.primary.withOpacity(isDark ? 0.12 : 0.08)
        : (isDark ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03));

    return SizedBox(
      height: height,
      child: Stack(
        children: [
          // Large day number watermark
          Positioned(
            left: 0,
            right: 0,
            top: 20, // Offset from top to position in early morning area
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Big day number
                  Text(
                    dayNumber,
                    style: TextStyle(
                      fontSize: 120,
                      fontWeight: FontWeight.w800,
                      color: watermarkColor,
                      height: 1.0,
                    ),
                  ),
                  // Day name below
                  Text(
                    dayName.toUpperCase(),
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 4,
                      color: watermarkColor,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
