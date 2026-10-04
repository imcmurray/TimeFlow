import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/core/theme/app_colors.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';
import 'package:timeflow/presentation/utils/time_formatter.dart';
import 'package:timeflow/presentation/utils/timeline_offset.dart';
import 'package:timeflow/services/sun_times_service.dart';

/// Displays hour markers for multiple days with sunrise/sunset indicators.
class HourMarkersMultiDay extends ConsumerWidget {
  final double hourHeight;
  final bool upcomingTasksAboveNow;
  final DateTime referenceDate;
  final int daysLoadedBefore;
  final int daysLoadedAfter;
  final bool use24HourFormat;

  const HourMarkersMultiDay({
    super.key,
    required this.hourHeight,
    required this.upcomingTasksAboveNow,
    required this.referenceDate,
    required this.daysLoadedBefore,
    required this.daysLoadedAfter,
    this.use24HourFormat = false,
  });

  double _getOffsetForHour(int dayOffset, double hour) {
    return TimelineOffset.forHour(
      dayOffset: dayOffset,
      hour: hour,
      hourHeight: hourHeight,
      daysLoadedBefore: daysLoadedBefore,
      daysLoadedAfter: daysLoadedAfter,
      upcomingTasksAboveNow: upcomingTasksAboveNow,
    );
  }

  double _getOffsetForDateTime(int dayOffset, DateTime time) {
    final fractionalHour = time.hour + (time.minute / 60.0);
    return _getOffsetForHour(dayOffset, fractionalHour);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final markerColor =
        isDark ? AppColors.hourMarkerDark : AppColors.hourMarkerLight;
    final settings = ref.watch(settingsProvider);

    // Pre-calculate sun times for each day if enabled
    final Map<int, SunTimes> sunTimesMap = {};
    if (settings.showSunTimes) {
      for (int dayOffset = -daysLoadedBefore;
          dayOffset <= daysLoadedAfter;
          dayOffset++) {
        final date = referenceDate.add(Duration(days: dayOffset));
        sunTimesMap[dayOffset] = SunTimesService.calculate(
          date: date,
          latitude: settings.latitude,
          longitude: settings.longitude,
          timezoneOffsetHours: settings.timezoneOffsetHours,
        );
      }
    }

    final markers = <Widget>[];

    // Generate hour markers for each day
    for (int dayOffset = -daysLoadedBefore;
        dayOffset <= daysLoadedAfter;
        dayOffset++) {
      final sunTimes = sunTimesMap[dayOffset];

      for (int hour = 0; hour < 24; hour++) {
        final offset = _getOffsetForHour(dayOffset, hour.toDouble());

        markers.add(
          Positioned(
            top: offset - 8,
            left: 4,
            right: 4,
            child: Row(
              children: [
                const SizedBox(width: 14), // Placeholder to align text
                // Hour text
                Expanded(
                  child: Text(
                    _formatHour(hour),
                    style: TextStyle(
                      fontSize: 11,
                      color: markerColor,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
          ),
        );

        // Dynamic sub-markers based on zoom level
        if (hourHeight >= 120) {
          final List<int> minuteMarks;
          if (hourHeight >= 240) {
            // Every 5 minutes
            minuteMarks = [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55];
          } else if (hourHeight >= 160) {
            // Quarter hours
            minuteMarks = [15, 30, 45];
          } else {
            // Half hour only
            minuteMarks = [30];
          }

          for (final minutes in minuteMarks) {
            final subOffset =
                _getOffsetForHour(dayOffset, hour + minutes / 60.0);
            final bool isQuarterMark = minutes % 15 == 0;
            markers.add(
              Positioned(
                top: subOffset - 6,
                left: 4,
                right: 4,
                child: Row(
                  children: [
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        ':${minutes.toString().padLeft(2, '0')}',
                        style: TextStyle(
                          fontSize: isQuarterMark ? 9 : 8,
                          color: markerColor.withValues(
                              alpha: isQuarterMark ? 0.5 : 0.35),
                          fontWeight:
                              isQuarterMark ? FontWeight.w400 : FontWeight.w300,
                        ),
                        textAlign: TextAlign.right,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }
        }
      }

      // Add exact sunrise/sunset time markers (positioned precisely between hours)
      if (settings.showSunTimes && sunTimes != null) {
        // Sunrise marker
        if (sunTimes.sunrise != null &&
            !sunTimes.isPolarDay &&
            !sunTimes.isPolarNight) {
          final sunriseOffset =
              _getOffsetForDateTime(dayOffset, sunTimes.sunrise!);
          markers.add(
            Positioned(
              top: sunriseOffset - 8,
              left: 2,
              right: 2,
              child: Row(
                children: [
                  const Icon(
                    Icons.wb_sunny,
                    size: 10,
                    color: Color(0xFFFFB74D),
                  ),
                  const SizedBox(width: 1),
                  Expanded(
                    child: Text(
                      _formatExactTime(sunTimes.sunrise!),
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFFFFB74D),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Sunset marker
        if (sunTimes.sunset != null &&
            !sunTimes.isPolarDay &&
            !sunTimes.isPolarNight) {
          final sunsetOffset =
              _getOffsetForDateTime(dayOffset, sunTimes.sunset!);
          markers.add(
            Positioned(
              top: sunsetOffset - 8,
              left: 2,
              right: 2,
              child: Row(
                children: [
                  const Icon(
                    Icons.nightlight_round,
                    size: 10,
                    color: Color(0xFF7986CB),
                  ),
                  const SizedBox(width: 1),
                  Expanded(
                    child: Text(
                      _formatExactTime(sunTimes.sunset!),
                      style: const TextStyle(
                        fontSize: 9,
                        color: Color(0xFF7986CB),
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ),
            ),
          );
        }
      }
    }

    return Stack(children: markers);
  }

  String _formatHour(int hour) =>
      TimeFormatter.formatHour(hour, use24HourFormat: use24HourFormat);

  String _formatExactTime(DateTime time) {
    if (use24HourFormat) {
      return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
    final hour =
        time.hour == 0 ? 12 : (time.hour > 12 ? time.hour - 12 : time.hour);
    final period = time.hour >= 12 ? 'p' : 'a';
    return '$hour:${time.minute.toString().padLeft(2, '0')}$period';
  }
}
