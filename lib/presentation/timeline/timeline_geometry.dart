import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:timeflow/domain/time/local_date.dart';
import 'package:timeflow/presentation/providers/task_provider.dart';

/// Maps times to vertical positions on the timeline and back.
///
/// Every day is exactly 24 hours tall and positions come from wall-clock
/// readings, so tasks, hour labels and day dividers always agree, including
/// on DST-change days (the skipped hour simply has no tasks; the repeated
/// hour overlaps itself).
///
/// The timeline covers [dayCount] days starting at [firstDay]. With
/// [futureAtTop], later times are higher up (smaller y) and the river flows
/// down toward the NOW line; otherwise later times are lower.
@immutable
class TimelineGeometry {
  final LocalDate firstDay;
  final int dayCount;
  final double hourHeight;
  final bool futureAtTop;

  const TimelineGeometry({
    required this.firstDay,
    required this.dayCount,
    required this.hourHeight,
    required this.futureAtTop,
  });

  double get dayHeight => 24 * hourHeight;
  double get totalHeight => dayCount * dayHeight;
  LocalDate get lastDay => firstDay.addDays(dayCount - 1);

  /// Hours from the start of [firstDay] to [t] on a wall clock.
  double _hoursOf(DateTime t) =>
      firstDay.daysUntil(LocalDate.of(t)) * 24 +
      t.hour +
      t.minute / 60 +
      t.second / 3600;

  double _yOfHours(double hours) {
    final y = hours * hourHeight;
    return futureAtTop ? totalHeight - y : y;
  }

  /// Vertical position of [t].
  double yOf(DateTime t) => _yOfHours(_hoursOf(t));

  /// Vertical position of [hour] (fractional) on [day].
  double yOfDayHour(LocalDate day, double hour) =>
      _yOfHours(firstDay.daysUntil(day) * 24 + hour);

  /// The wall-clock time at vertical position [y], to the minute.
  DateTime timeAt(double y) {
    final hours = (futureAtTop ? totalHeight - y : y) / hourHeight;
    final minutes = (hours * 60).round();
    final dayIndex = (minutes / (24 * 60)).floor();
    return firstDay.addDays(dayIndex).at(0, minutes - dayIndex * 24 * 60);
  }

  /// Top edge and height of the block from [start] to [end].
  ({double top, double height}) spanOf(DateTime start, DateTime end) {
    final a = yOf(start);
    final b = yOf(end);
    return (top: math.min(a, b), height: (a - b).abs());
  }

  /// The days that intersect the vertical band [top]..[bottom], clamped to
  /// the timeline.
  DayRange daysIn(double top, double bottom) {
    LocalDate dayAt(double y) {
      final hours = (futureAtTop ? totalHeight - y : y) / hourHeight;
      final index = (hours / 24).floor().clamp(0, dayCount - 1);
      return firstDay.addDays(index);
    }

    final a = dayAt(top);
    final b = dayAt(bottom);
    return a.isAfter(b) ? DayRange(b, a) : DayRange(a, b);
  }

  /// A copy covering [dayCount] days centred on [center].
  TimelineGeometry centeredOn(LocalDate center) => TimelineGeometry(
    firstDay: center.addDays(-(dayCount ~/ 2)),
    dayCount: dayCount,
    hourHeight: hourHeight,
    futureAtTop: futureAtTop,
  );

  TimelineGeometry copyWith({double? hourHeight, bool? futureAtTop}) =>
      TimelineGeometry(
        firstDay: firstDay,
        dayCount: dayCount,
        hourHeight: hourHeight ?? this.hourHeight,
        futureAtTop: futureAtTop ?? this.futureAtTop,
      );

  @override
  bool operator ==(Object other) =>
      other is TimelineGeometry &&
      other.firstDay == firstDay &&
      other.dayCount == dayCount &&
      other.hourHeight == hourHeight &&
      other.futureAtTop == futureAtTop;

  @override
  int get hashCode => Object.hash(firstDay, dayCount, hourHeight, futureAtTop);
}
