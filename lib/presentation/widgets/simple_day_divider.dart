import 'package:flutter/material.dart';
import 'package:cron_timeflow/presentation/utils/day_label_formatter.dart';

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
        ? (isDark
            ? colorScheme.primary.withValues(alpha: 0.15)
            : colorScheme.primary.withValues(alpha: 0.08))
        : (isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03));

    final lineColor = isToday
        ? colorScheme.primary.withValues(alpha: 0.6)
        : colorScheme.outlineVariant.withValues(alpha: 0.5);

    final icon = Icons.wb_twilight;
    final iconColor =
        isDark ? const Color(0xFFFFB74D) : const Color(0xFFFF9800);

    return Container(
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            bandColor.withValues(alpha: 0),
            bandColor,
            bandColor,
            bandColor.withValues(alpha: 0),
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
                    lineColor.withValues(alpha: 0),
                    lineColor,
                  ],
                ),
                boxShadow: isToday
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.3),
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
                  ? (isToday
                      ? colorScheme.primary.withValues(alpha: 0.2)
                      : Colors.grey[900]!.withValues(alpha: 0.8))
                  : (isToday
                      ? colorScheme.primary.withValues(alpha: 0.1)
                      : Colors.white.withValues(alpha: 0.9)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isToday
                    ? colorScheme.primary.withValues(alpha: 0.5)
                    : lineColor,
                width: isToday ? 1.5 : 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
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
                  DayLabelFormatter.compact(date),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                    color:
                        isToday ? colorScheme.primary : colorScheme.onSurface,
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
                    lineColor.withValues(alpha: 0),
                  ],
                ),
                boxShadow: isToday
                    ? [
                        BoxShadow(
                          color: colorScheme.primary.withValues(alpha: 0.3),
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
}
