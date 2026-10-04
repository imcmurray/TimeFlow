import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/core/theme/app_colors.dart';
import 'package:timeflow/domain/time/local_date.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';
import 'package:timeflow/presentation/providers/task_provider.dart';
import 'package:timeflow/presentation/timeline/timeline_geometry.dart';
import 'package:timeflow/presentation/utils/time_formatter.dart';
import 'package:timeflow/services/sun_times_service.dart';

/// Hour labels (and minute labels when zoomed in) in the left gutter, plus
/// sunrise and sunset times, for the visible [days].
class HourMarkersLayer extends ConsumerWidget {
  final TimelineGeometry geometry;
  final DayRange days;

  const HourMarkersLayer({
    super.key,
    required this.geometry,
    required this.days,
  });

  static const _sunriseColor = Color(0xFFFFB74D);
  static const _sunsetColor = Color(0xFF7986CB);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final markerColor = isDark
        ? AppColors.hourMarkerDark
        : AppColors.hourMarkerLight;
    final use24Hour = ref.watch(
      settingsProvider.select((s) => s.use24HourFormat),
    );
    final showSun = ref.watch(settingsProvider.select((s) => s.showSunTimes));
    final latitude = ref.watch(settingsProvider.select((s) => s.latitude));
    final longitude = ref.watch(settingsProvider.select((s) => s.longitude));
    final hourHeight = geometry.hourHeight;

    final minuteMarks = hourHeight >= 240
        ? const [5, 10, 15, 20, 25, 30, 35, 40, 45, 50, 55]
        : hourHeight >= 160
        ? const [15, 30, 45]
        : hourHeight >= 120
        ? const [30]
        : const <int>[];

    final markers = <Widget>[];
    Widget label(double y, double height, Widget child) => Positioned(
      top: y - height / 2,
      left: 4,
      right: 4,
      height: height,
      child: Align(alignment: Alignment.centerRight, child: child),
    );

    for (var day = days.first; !day.isAfter(days.last); day = day.addDays(1)) {
      final sun = showSun
          ? SunTimesService.calculate(
              date: day.startOfDay,
              latitude: latitude,
              longitude: longitude,
            )
          : null;
      // Minutes of the day taken by a sunrise/sunset label; hour and minute
      // labels within 20 minutes of one give way to it.
      final sunMinutes = [
        for (final t in [sun?.sunrise, sun?.sunset])
          if (t != null && LocalDate.of(t) == day) t.hour * 60 + t.minute,
      ];
      bool clear(int minuteOfDay) =>
          sunMinutes.every((m) => (m - minuteOfDay).abs() >= 20);

      for (var hour = 0; hour < 24; hour++) {
        if (clear(hour * 60)) {
          markers.add(
            label(
              geometry.yOfDayHour(day, hour.toDouble()),
              16,
              Text(
                TimeFormatter.formatHour(hour, use24HourFormat: use24Hour),
                style: TextStyle(
                  fontSize: 11,
                  color: markerColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }
        for (final minute in minuteMarks) {
          if (!clear(hour * 60 + minute)) continue;
          final quarter = minute % 15 == 0;
          markers.add(
            label(
              geometry.yOfDayHour(day, hour + minute / 60),
              12,
              Text(
                ':${minute.toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: quarter ? 9 : 8,
                  color: markerColor.withValues(alpha: quarter ? 0.6 : 0.45),
                ),
              ),
            ),
          );
        }
      }

      if (sun != null) {
        if (!sun.isPolarDay && !sun.isPolarNight) {
          if (sun.sunrise != null) {
            markers.add(
              _sunMarker(
                day,
                sun.sunrise!,
                Icons.wb_sunny,
                _sunriseColor,
                use24Hour,
                'Sunrise',
              ),
            );
          }
          if (sun.sunset != null) {
            markers.add(
              _sunMarker(
                day,
                sun.sunset!,
                Icons.nightlight_round,
                _sunsetColor,
                use24Hour,
                'Sunset',
              ),
            );
          }
        }
      }
    }

    return Stack(children: markers);
  }

  Widget _sunMarker(
    LocalDate day,
    DateTime time,
    IconData icon,
    Color color,
    bool use24Hour,
    String name,
  ) {
    final y = geometry.yOfDayHour(day, time.hour + time.minute / 60);
    final text = TimeFormatter.formatTime(time, use24HourFormat: use24Hour);
    return Positioned(
      top: y - 8,
      left: 2,
      right: 2,
      height: 16,
      child: Semantics(
        label: '$name $text',
        excludeSemantics: true,
        child: Row(
          children: [
            Icon(icon, size: 10, color: color),
            const SizedBox(width: 1),
            Expanded(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerRight,
                child: Text(
                  text,
                  style: TextStyle(
                    fontSize: 9,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
