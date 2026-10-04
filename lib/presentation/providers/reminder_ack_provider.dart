import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/domain/time/wall_clock.dart';
import 'package:timeflow/presentation/widgets/reminder_line.dart';

/// What the user did with a task's reminder on the timeline.
class ReminderAck {
  /// The user dismissed the triggered reminder.
  final bool acknowledged;

  /// A snoozed reminder offset (minutes before start) replacing the task's own.
  final int? snoozedMinutes;

  const ReminderAck({this.acknowledged = false, this.snoozedMinutes});
}

/// Acknowledged and snoozed reminders, by task (occurrence) id.
class ReminderAcksNotifier extends Notifier<Map<String, ReminderAck>> {
  /// Snooze steps, in minutes before the task starts.
  static const snoozeSteps = [60, 30, 15, 10, 5, 0];

  @override
  Map<String, ReminderAck> build() => const {};

  void acknowledge(Task task) {
    state = {
      ...state,
      task.id: ReminderAck(
        acknowledged: true,
        snoozedMinutes: state[task.id]?.snoozedMinutes,
      ),
    };
  }

  /// Moves the reminder to the next snooze step closer to the start time.
  void snooze(Task task) {
    final current = state[task.id]?.snoozedMinutes ?? task.reminderMinutes;
    if (current == null) return;
    final next = snoozeSteps.firstWhere((m) => m < current, orElse: () => -1);
    state = {
      ...state,
      task.id: ReminderAck(snoozedMinutes: next < 0 ? null : next),
    };
  }
}

final reminderAcksProvider =
    NotifierProvider<ReminderAcksNotifier, Map<String, ReminderAck>>(
        ReminderAcksNotifier.new);

/// Minutes before start the reminder fires at, taking snoozes into account.
int? effectiveReminderMinutes(Task task, ReminderAck? ack) =>
    task.reminderMinutes == null
        ? null
        : (ack?.snoozedMinutes ?? task.reminderMinutes);

DateTime? effectiveReminderTime(Task task, ReminderAck? ack) {
  final minutes = effectiveReminderMinutes(task, ack);
  return minutes == null ? null : addWallMinutes(task.startTime, -minutes);
}

/// How prominently a task's reminder should show at [now]; null when there's
/// nothing to show (no reminder, completed, already started, or more than an
/// hour away).
ReminderState? reminderStateOf(Task task, DateTime now, ReminderAck? ack) {
  final reminderAt = effectiveReminderTime(task, ack);
  if (reminderAt == null || task.isCompleted) return null;
  if (!now.isBefore(task.startTime)) return null;
  if (ack?.acknowledged ?? false) return ReminderState.acknowledged;
  final until = reminderAt.difference(now);
  if (until <= Duration.zero) return ReminderState.triggered;
  if (until.inMinutes >= 60) return null;
  if (until.inMinutes < 5) return ReminderState.imminent;
  if (until.inMinutes < 15) return ReminderState.approaching;
  return ReminderState.distant;
}
