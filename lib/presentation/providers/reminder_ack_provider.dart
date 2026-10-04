import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';
import 'package:timeflow/presentation/widgets/reminder_line.dart';

/// What the user did with a task's reminder.
class ReminderAck {
  /// The user dismissed the triggered reminder on the timeline.
  final bool acknowledged;

  /// The reminder was snoozed to this time.
  final DateTime? snoozedUntil;

  const ReminderAck({this.acknowledged = false, this.snoozedUntil});

  Map<String, Object?> toJson() => {
    if (acknowledged) 'ack': true,
    if (snoozedUntil != null) 'until': snoozedUntil!.toIso8601String(),
  };

  static ReminderAck fromJson(Map<String, dynamic> j) => ReminderAck(
    acknowledged: j['ack'] as bool? ?? false,
    snoozedUntil: j['until'] == null
        ? null
        : DateTime.parse(j['until'] as String),
  );
}

/// Acknowledged and snoozed reminders by task (occurrence) id, persisted so
/// they survive restarts and can be written by the notification background
/// handler.
class ReminderAcksNotifier extends Notifier<Map<String, ReminderAck>> {
  static const prefsKey = 'timeflow_reminder_acks';

  /// Timeline snooze steps, in minutes before the task starts.
  static const snoozeSteps = [60, 30, 15, 10, 5, 0];

  late SharedPreferences _prefs;

  @override
  Map<String, ReminderAck> build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    return load(_prefs);
  }

  /// Reads the stored map, dropping entries older than a day.
  static Map<String, ReminderAck> load(SharedPreferences prefs) {
    final raw = prefs.getString(prefsKey);
    if (raw == null) return const {};
    try {
      final cutoff = DateTime.now().subtract(const Duration(days: 1));
      final map = (jsonDecode(raw) as Map<String, dynamic>).map(
        (k, v) => MapEntry(k, ReminderAck.fromJson(v as Map<String, dynamic>)),
      );
      map.removeWhere(
        (_, a) => a.snoozedUntil != null && a.snoozedUntil!.isBefore(cutoff),
      );
      return map;
    } catch (_) {
      return const {};
    }
  }

  static Future<void> save(
    SharedPreferences prefs,
    Map<String, ReminderAck> acks,
  ) {
    return prefs.setString(
      prefsKey,
      jsonEncode(acks.map((k, v) => MapEntry(k, v.toJson()))),
    );
  }

  void _set(String id, ReminderAck ack) {
    state = {...state, id: ack};
    save(_prefs, state);
  }

  /// Re-reads the store (e.g. after the background handler changed it).
  Future<void> reload() async {
    await _prefs.reload();
    state = load(_prefs);
  }

  void acknowledge(Task task) => _set(
    task.id,
    ReminderAck(acknowledged: true, snoozedUntil: state[task.id]?.snoozedUntil),
  );

  /// Moves the reminder to the next step closer to the start time.
  void snooze(Task task) {
    final current = effectiveReminderTime(task, state[task.id]);
    if (current == null) return;
    final minutesBefore = task.startTime.difference(current).inMinutes;
    final next = snoozeSteps.firstWhere(
      (m) => m < minutesBefore,
      orElse: () => -1,
    );
    if (next < 0) return;
    _set(
      task.id,
      ReminderAck(
        snoozedUntil: task.startTime.subtract(Duration(minutes: next)),
      ),
    );
  }

  /// Snoozes a reminder to an absolute time (from a notification button).
  void snoozeUntil(String taskId, DateTime until) =>
      _set(taskId, ReminderAck(snoozedUntil: until));

  /// Snoozed reminder times, for the reminder planner.
  Map<String, DateTime> get snoozedUntil => {
    for (final e in state.entries)
      if (e.value.snoozedUntil != null) e.key: e.value.snoozedUntil!,
  };
}

final reminderAcksProvider =
    NotifierProvider<ReminderAcksNotifier, Map<String, ReminderAck>>(
      ReminderAcksNotifier.new,
    );

/// When the reminder fires, taking snoozes into account.
DateTime? effectiveReminderTime(Task task, ReminderAck? ack) {
  if (task.reminderMinutes == null) return null;
  return ack?.snoozedUntil ??
      task.startTime.subtract(Duration(minutes: task.reminderMinutes!));
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
