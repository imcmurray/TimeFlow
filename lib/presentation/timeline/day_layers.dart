import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/domain/time/local_date.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';
import 'package:timeflow/presentation/providers/task_provider.dart';
import 'package:timeflow/presentation/timeline/timeline_geometry.dart';
import 'package:timeflow/presentation/timeline/timeline_tasks.dart';
import 'package:timeflow/presentation/timeline/timeline_view.dart';
import 'package:timeflow/presentation/widgets/day_watermark.dart';
import 'package:timeflow/presentation/widgets/simple_day_divider.dart';
import 'package:timeflow/services/holidays_service.dart';

/// Date bands at each midnight.
class DayDividersLayer extends StatelessWidget {
  final TimelineGeometry geometry;
  final DayRange days;

  const DayDividersLayer({
    super.key,
    required this.geometry,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    final today = LocalDate.today();
    return Stack(
      children: [
        for (
          var day = days.first;
          !day.isAfter(days.last);
          day = day.addDays(1)
        )
          Positioned(
            top: geometry.yOfDayHour(day, 0) - 16,
            left: TimelineLayout.contentLeft,
            right: TimelineLayout.contentRight,
            child: SimpleDayDivider(
              date: day.startOfDay,
              isToday: day == today,
            ),
          ),
      ],
    );
  }
}

/// Dashed midnight lines drawn over task cards, so a task that runs past
/// midnight still shows where the day changes.
class DayDividerOverlay extends StatelessWidget {
  final TimelineGeometry geometry;
  final DayRange days;

  const DayDividerOverlay({
    super.key,
    required this.geometry,
    required this.days,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final color = isDark
        ? Colors.white.withValues(alpha: 0.3)
        : Colors.black.withValues(alpha: 0.2);
    return Stack(
      children: [
        for (
          var day = days.first;
          !day.isAfter(days.last);
          day = day.addDays(1)
        )
          Positioned(
            top: geometry.yOfDayHour(day, 0) - 1,
            left: TimelineLayout.contentLeft,
            right: TimelineLayout.contentRight,
            height: 2,
            child: CustomPaint(painter: DashedLinePainter(color: color)),
          ),
      ],
    );
  }
}

/// Large date watermarks in the background of each day, placed in the
/// earliest stretch of the morning that has no tasks.
class DayWatermarksLayer extends ConsumerStatefulWidget {
  final TimelineGeometry geometry;
  final DayRange days;

  const DayWatermarksLayer({
    super.key,
    required this.geometry,
    required this.days,
  });

  @override
  ConsumerState<DayWatermarksLayer> createState() => _DayWatermarksLayerState();
}

class _DayWatermarksLayerState extends ConsumerState<DayWatermarksLayer> {
  static const _preferredStartHour = 4;
  static const _heightHours = 5;
  static const _highlightFor = Duration(seconds: 30);

  List<Task> _tasks = const [];
  final Map<LocalDate, Timer> _highlighted = {};

  @override
  void dispose() {
    for (final t in _highlighted.values) {
      t.cancel();
    }
    super.dispose();
  }

  void _highlight(LocalDate day) {
    _highlighted.remove(day)?.cancel();
    setState(() {
      _highlighted[day] = Timer(_highlightFor, () {
        if (mounted) setState(() => _highlighted.remove(day));
      });
    });
  }

  int _startHourFor(LocalDate day) {
    for (var start = _preferredStartHour; start >= 0; start--) {
      final from = day.at(start, 0);
      final to = day.at(start + _heightHours, 0);
      final clear = !_tasks.any(
        (t) => t.startTime.isBefore(to) && t.endTime.isAfter(from),
      );
      if (clear) return start;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    _tasks = watchTimelineTasks(ref, widget.days, _tasks);
    final s = ref.watch(settingsProvider);
    final g = widget.geometry;
    final today = LocalDate.today();
    final height = _heightHours * g.hourHeight;

    return Stack(
      children: [
        for (
          var day = widget.days.first;
          !day.isAfter(widget.days.last);
          day = day.addDays(1)
        )
          () {
            final start = _startHourFor(day).toDouble();
            final top = g.futureAtTop
                ? g.yOfDayHour(day, start + _heightHours)
                : g.yOfDayHour(day, start);
            return Positioned(
              top: top,
              left: TimelineLayout.contentLeft,
              right: TimelineLayout.contentRight,
              height: height,
              child: ExcludeSemantics(
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: () => _highlight(day),
                  child: MouseRegion(
                    onEnter: (_) => _highlight(day),
                    child: DayWatermark(
                      date: day.startOfDay,
                      isToday: day == today,
                      height: height,
                      showWeekNumber: s.watermarkShowWeekNumber,
                      showDayOfYear: s.watermarkShowDayOfYear,
                      showHolidays: s.watermarkShowHolidays,
                      showMoonPhase: s.watermarkShowMoonPhase,
                      showQuarter: s.watermarkShowQuarter,
                      showDaysRemaining: s.watermarkShowDaysRemaining,
                      holidayRegion: HolidayRegion.fromCode(s.holidayRegion),
                      isHighlighted: _highlighted.containsKey(day),
                    ),
                  ),
                ),
              ),
            );
          }(),
      ],
    );
  }
}

/// Paints a dashed horizontal line through the middle of its box.
class DashedLinePainter extends CustomPainter {
  final Color color;

  DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    final y = size.height / 2;
    for (double x = 0; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, y), Offset(x + 6, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant DashedLinePainter old) => old.color != color;
}
