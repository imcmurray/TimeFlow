import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';
import 'package:timeflow/presentation/providers/task_provider.dart';
import 'package:timeflow/presentation/utils/timeline_offset.dart';
import 'package:timeflow/presentation/widgets/day_boundary_marker.dart';

/// Displays large watermark dates in the background of each day.
/// Adjusts position based on task overlap to avoid covering events.
class DayWatermarksWithTasks extends ConsumerStatefulWidget {
  final double hourHeight;
  final bool upcomingTasksAboveNow;
  final DateTime referenceDate;
  final int daysLoadedBefore;
  final int daysLoadedAfter;
  final DateRange loadedRange;

  const DayWatermarksWithTasks({
    super.key,
    required this.hourHeight,
    required this.upcomingTasksAboveNow,
    required this.referenceDate,
    required this.daysLoadedBefore,
    required this.daysLoadedAfter,
    required this.loadedRange,
  });

  @override
  ConsumerState<DayWatermarksWithTasks> createState() =>
      _DayWatermarksWithTasksState();
}

class _DayWatermarksWithTasksState
    extends ConsumerState<DayWatermarksWithTasks> {
  // Track which day watermarks are currently highlighted (by day offset)
  final Map<int, DateTime> _highlightedWatermarks = {};
  Timer? _highlightTimer;

  @override
  void dispose() {
    _highlightTimer?.cancel();
    super.dispose();
  }

  void _onWatermarkInteraction(int dayOffset) {
    setState(() {
      _highlightedWatermarks[dayOffset] = DateTime.now();
    });
    _startHighlightTimer();
  }

  void _startHighlightTimer() {
    _highlightTimer?.cancel();
    _highlightTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final now = DateTime.now();
      final expiredKeys = <int>[];
      for (final entry in _highlightedWatermarks.entries) {
        if (now.difference(entry.value).inSeconds >= 30) {
          expiredKeys.add(entry.key);
        }
      }
      if (expiredKeys.isNotEmpty) {
        setState(() {
          for (final key in expiredKeys) {
            _highlightedWatermarks.remove(key);
          }
        });
      }
      if (_highlightedWatermarks.isEmpty) {
        _highlightTimer?.cancel();
      }
    });
  }

  double _getOffsetForHour(int dayOffset, double hour) {
    return TimelineOffset.forHour(
      dayOffset: dayOffset,
      hour: hour,
      hourHeight: widget.hourHeight,
      daysLoadedBefore: widget.daysLoadedBefore,
      daysLoadedAfter: widget.daysLoadedAfter,
      upcomingTasksAboveNow: widget.upcomingTasksAboveNow,
    );
  }

  /// Find the best start hour for watermark (moving it earlier if tasks overlap)
  int _findBestWatermarkStartHour(DateTime date, List<Task> tasks,
      int defaultStartHour, int watermarkHeightHours) {
    final dayStart = DateTime(date.year, date.month, date.day);

    // Try positions from the default down to 0 (midnight)
    for (int startHour = defaultStartHour; startHour >= 0; startHour--) {
      final watermarkStart = dayStart.add(Duration(hours: startHour));
      final watermarkEnd =
          dayStart.add(Duration(hours: startHour + watermarkHeightHours));

      bool hasOverlap = false;
      for (final task in tasks) {
        // Check if task is on this day and overlaps with watermark time range
        if (task.startTime.isBefore(watermarkEnd) &&
            task.endTime.isAfter(watermarkStart)) {
          hasOverlap = true;
          break;
        }
      }

      if (!hasOverlap) {
        return startHour;
      }
    }

    // If all positions have overlap, use 0 (midnight) and let events overwrite
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    final settings = ref.watch(settingsProvider);
    final tasksAsync = ref.watch(tasksForRangeProvider(widget.loadedRange));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    return tasksAsync.when(
      loading: () => _buildWatermarks(context, settings, today, []),
      error: (_, __) => _buildWatermarks(context, settings, today, []),
      data: (tasks) => _buildWatermarks(context, settings, today, tasks),
    );
  }

  Widget _buildWatermarks(BuildContext context, dynamic settings,
      DateTime today, List<Task> tasks) {
    final watermarks = <Widget>[];

    // Default position - early morning hours (around 4-8 AM)
    const defaultWatermarkStartHour = 4;
    const watermarkHeightHours = 5; // Spans about 5 hours

    for (int dayOffset = -widget.daysLoadedBefore;
        dayOffset <= widget.daysLoadedAfter;
        dayOffset++) {
      final date = widget.referenceDate.add(Duration(days: dayOffset));

      final isToday = date.year == today.year &&
          date.month == today.month &&
          date.day == today.day;

      // Filter tasks for this day
      final dayStart = DateTime(date.year, date.month, date.day);
      final dayEnd = dayStart.add(const Duration(days: 1));
      final dayTasks = tasks
          .where((t) =>
              t.startTime.isBefore(dayEnd) && t.endTime.isAfter(dayStart))
          .toList();

      // Find the best position for the watermark (avoiding task overlap)
      final watermarkStartHour = _findBestWatermarkStartHour(
          date, dayTasks, defaultWatermarkStartHour, watermarkHeightHours);

      // Calculate position for this day's watermark
      final topOffset =
          _getOffsetForHour(dayOffset, watermarkStartHour.toDouble());
      final bottomOffset = _getOffsetForHour(
          dayOffset, (watermarkStartHour + watermarkHeightHours).toDouble());

      // For upcomingTasksAboveNow, the bottom offset is smaller than top offset
      final actualTop = widget.upcomingTasksAboveNow ? bottomOffset : topOffset;
      final height = (watermarkHeightHours * widget.hourHeight).abs();

      // Check if this watermark is highlighted
      final isHighlighted = _highlightedWatermarks.containsKey(dayOffset);

      watermarks.add(
        Positioned(
          top: actualTop,
          left: 70,
          right: 16,
          height: height,
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,
            onTap: () => _onWatermarkInteraction(dayOffset),
            child: MouseRegion(
              onEnter: (_) => _onWatermarkInteraction(dayOffset),
              child: DayWatermark(
                date: date,
                isToday: isToday,
                height: height,
                showWeekNumber: settings.watermarkShowWeekNumber,
                showDayOfYear: settings.watermarkShowDayOfYear,
                showHolidays: settings.watermarkShowHolidays,
                showMoonPhase: settings.watermarkShowMoonPhase,
                showQuarter: settings.watermarkShowQuarter,
                showDaysRemaining: settings.watermarkShowDaysRemaining,
                isHighlighted: isHighlighted,
              ),
            ),
          ),
        ),
      );
    }

    return Stack(children: watermarks);
  }
}
