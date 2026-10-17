import 'package:flutter/foundation.dart';

/// What a reminder's button means once its identifier has been read.
enum ReminderIntent {
  /// Open the task: a tap on the notification itself, or an identifier from
  /// some future build this one doesn't know.
  open,

  /// Mark the task (this occurrence) completed, and stop reminding.
  complete,

  /// Remind again later; the task is unchanged.
  snooze,

  /// "I've seen it": stop this reminder and its in-app alert, change nothing
  /// about the task.
  dismiss,
}

/// A button on a reminder.
///
/// [id] travels in the notification itself, which is why it can't be renamed
/// freely: a reminder already sitting on someone's lock screen was built by an
/// older build and will come back with that build's identifier.
@immutable
class ReminderAction {
  const ReminderAction({
    required this.id,
    required this.label,
    required this.intent,
    this.snooze,
  });

  final String id;
  final String label;
  final ReminderIntent intent;

  /// How long [ReminderIntent.snooze] waits, and null for everything else.
  final Duration? snooze;
}

/// The buttons a reminder offers, and what each one means.
///
/// Ian chose this set with a tester after both of them read *Done* and couldn't
/// tell whether it meant "stop reminding me" or "the task is finished"
/// (TimeFlow#68). **Completed** and **Dismiss** separate those two meanings, and
/// neither of them is *Delete*: from a lock screen that would be one mis-tap
/// away from losing a task, with no undo, so deleting stays in the app.
class ReminderActions {
  const ReminderActions._();

  static const completed = ReminderAction(
    id: 'completed',
    label: 'Completed',
    intent: ReminderIntent.complete,
  );
  static const snooze5 = ReminderAction(
    id: 'snooze5',
    label: 'Snooze 5 min',
    intent: ReminderIntent.snooze,
    snooze: Duration(minutes: 5),
  );

  /// Ten minutes keeps the `snooze` identifier it has always had, so a reminder
  /// delivered by an older build still snoozes when this build handles it.
  static const snooze10 = ReminderAction(
    id: 'snooze',
    label: 'Snooze 10 min',
    intent: ReminderIntent.snooze,
    snooze: Duration(minutes: 10),
  );
  static const dismiss = ReminderAction(
    id: 'dismiss',
    label: 'Dismiss',
    intent: ReminderIntent.dismiss,
  );

  /// *Done* as built up to and including 1.1.3 (242). It is not offered any
  /// more, and it still completes the task, because a notification from 242 can
  /// outlive the update that replaced it.
  static const legacyDone = ReminderAction(
    id: 'done',
    label: 'Done',
    intent: ReminderIntent.complete,
  );

  /// iPhone and iPad: all four, shown in the long-press view.
  static const onDarwin = [completed, snooze5, snooze10, dismiss];

  /// Android shows at most three buttons on a notification, so *Snooze 5 min*
  /// is the one left out: the shorter snooze is the smaller loss.
  static const onAndroid = [completed, snooze10, dismiss];

  /// Everything an arriving response might name, offered or not.
  static const known = [completed, snooze5, snooze10, dismiss, legacyDone];

  /// The action an arriving identifier refers to, or null for a plain tap and
  /// for anything this build doesn't recognise — both of which open the task.
  static ReminderAction? byId(String? id) {
    for (final action in known) {
      if (action.id == id) return action;
    }
    return null;
  }

  /// What an arriving identifier means, with the open-the-task default.
  static ReminderIntent intentOf(String? id) =>
      byId(id)?.intent ?? ReminderIntent.open;
}
