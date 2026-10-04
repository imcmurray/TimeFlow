import 'package:flutter/foundation.dart';
import 'package:timeflow/domain/entities/task.dart';

/// A reminder to deliver at [fireAt] for [task].
@immutable
class PlannedReminder {
  final Task task;
  final DateTime fireAt;

  const PlannedReminder(this.task, this.fireAt);

  /// Stable notification id for this occurrence's reminder (31-bit, as
  /// Android requires a positive int).
  int get notificationId => notificationIdFor(task.id);

  static int notificationIdFor(String taskId) {
    // FNV-1a: stable across runs and isolates, unlike String.hashCode.
    var hash = 0x811c9dc5;
    for (final unit in taskId.codeUnits) {
      hash ^= unit;
      hash = (hash * 0x01000193) & 0xffffffff;
    }
    return hash & 0x7fffffff;
  }

  @override
  bool operator ==(Object other) =>
      other is PlannedReminder &&
      other.task.id == task.id &&
      other.fireAt == fireAt;

  @override
  int get hashCode => Object.hash(task.id, fireAt);

  @override
  String toString() => 'PlannedReminder(${task.title} at $fireAt)';
}

/// Decides which reminders to hand to the operating system.
///
/// Phones limit how many notifications an app may schedule (iOS keeps 64),
/// so only the soonest [limit] reminders within [horizon] are planned. The
/// plan is rebuilt whenever tasks change and whenever the app opens.
class ReminderPlanner {
  final Duration horizon;
  final int limit;

  const ReminderPlanner({
    this.horizon = const Duration(days: 14),
    this.limit = 60,
  });

  /// Reminders for [tasks] that are still due after [now], soonest first.
  /// [snoozedUntil] moves a task's reminder to another time, by task id.
  List<PlannedReminder> plan(
    Iterable<Task> tasks, {
    required DateTime now,
    Map<String, DateTime> snoozedUntil = const {},
  }) {
    final end = now.add(horizon);
    final planned = <PlannedReminder>[];
    for (final task in tasks) {
      if (task.isCompleted || task.reminderMinutes == null) continue;
      final fireAt =
          snoozedUntil[task.id] ??
          task.startTime.subtract(Duration(minutes: task.reminderMinutes!));
      if (!fireAt.isAfter(now) || fireAt.isAfter(end)) continue;
      planned.add(PlannedReminder(task, fireAt));
    }
    planned.sort((a, b) {
      final c = a.fireAt.compareTo(b.fireAt);
      return c != 0 ? c : a.task.id.compareTo(b.task.id);
    });
    return planned.length > limit ? planned.sublist(0, limit) : planned;
  }
}
