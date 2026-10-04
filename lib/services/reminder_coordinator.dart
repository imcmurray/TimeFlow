import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeflow/data/datasources/database.dart';
import 'package:timeflow/data/repositories/task_repository.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/domain/reminders/reminder_planner.dart';
import 'package:timeflow/domain/time/local_date.dart';
import 'package:timeflow/presentation/providers/reminder_ack_provider.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';
import 'package:timeflow/presentation/providers/task_provider.dart';
import 'package:timeflow/services/notification_service.dart';
import 'package:timeflow/services/reminder_sound_service.dart';
import 'package:timeflow/services/task_service.dart';
import 'package:window_to_front/window_to_front.dart';

const _snoozeFor = Duration(minutes: 10);

final notificationServiceProvider = Provider<NotificationService>(
  (ref) => NotificationService(),
);

/// Called with the task to show when the user taps a reminder.
typedef OpenTask = void Function(Task task);

/// Keeps scheduled reminders in step with the tasks, and handles what the
/// user does with them.
///
/// Rebuilds the reminder plan when tasks, snoozes or reminder settings
/// change and when the app comes back to the foreground. While the app is
/// open it also plays the reminder sound (and on desktop raises the window).
/// On Linux and the web, which can't schedule notifications, it shows them
/// itself.
class ReminderCoordinator with WidgetsBindingObserver {
  ReminderCoordinator(this._ref);

  final Ref _ref;
  final _planner = const ReminderPlanner();
  OpenTask? _openTask;
  List<PlannedReminder> _plan = const [];
  Timer? _replanDebounce;
  Timer? _nextAlert;
  Timer? _periodic;
  final List<ProviderSubscription<Object?>> _subscriptions = [];
  StreamSubscription<void>? _changes;
  final Set<String> _alerted = {};

  NotificationService get _notifications =>
      _ref.read(notificationServiceProvider);
  TaskRepository get _repo => _ref.read(taskRepositoryProvider);

  bool get _isDesktop =>
      !kIsWeb &&
      const {
        TargetPlatform.linux,
        TargetPlatform.macOS,
        TargetPlatform.windows,
      }.contains(defaultTargetPlatform);

  Future<void> start({required OpenTask openTask}) async {
    _openTask = openTask;
    try {
      await _notifications.initialize(
        onResponse: _handle,
        onBackgroundResponse: notificationBackgroundHandler,
      );
    } catch (e) {
      debugPrint('Notifications unavailable: $e');
    }
    WidgetsBinding.instance.addObserver(this);
    _changes = _repo.changes.listen((_) => _scheduleReplan());
    _subscriptions
      ..add(_ref.listen(reminderAcksProvider, (_, _) => _scheduleReplan()))
      ..add(
        _ref.listen(
          settingsProvider.select(
            (s) => (s.notificationsEnabled, s.use24HourFormat),
          ),
          (_, _) => _scheduleReplan(),
        ),
      );
    // The plan only looks two weeks ahead; keep it rolling while the app
    // stays open.
    _periodic = Timer.periodic(const Duration(hours: 6), (_) => _replan());
    await _replan();

    final launch = await _notifications.launchResponse();
    if (launch != null) _handle(launch);
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _replanDebounce?.cancel();
    _nextAlert?.cancel();
    _periodic?.cancel();
    _changes?.cancel();
    for (final s in _subscriptions) {
      s.close();
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // The background handler may have snoozed or completed something.
      _ref.read(reminderAcksProvider.notifier).reload();
      _replan();
    }
  }

  void _scheduleReplan() {
    _replanDebounce?.cancel();
    _replanDebounce = Timer(const Duration(milliseconds: 400), _replan);
  }

  Future<void> _replan() async {
    final settings = _ref.read(settingsProvider);
    final now = DateTime.now();
    final tasks = await _repo.getRange(now, now.add(_planner.horizon));
    _plan = settings.notificationsEnabled
        ? _planner.plan(
            tasks,
            now: now,
            snoozedUntil: _ref.read(reminderAcksProvider.notifier).snoozedUntil,
          )
        : const [];
    try {
      if (settings.notificationsEnabled) {
        await _notifications.scheduleAll(
          _plan,
          use24Hour: settings.use24HourFormat,
        );
      } else if (_notifications.canSchedule) {
        await _notifications.cancelAll();
      }
    } catch (e) {
      debugPrint('Could not schedule reminders: $e');
    }
    _armNextAlert();
  }

  /// Sets a timer for the next reminder that should alert in the app.
  void _armNextAlert() {
    _nextAlert?.cancel();
    final now = DateTime.now();
    final next = _plan.where((r) => !_alerted.contains(_key(r))).firstOrNull;
    if (next == null) return;
    final delay = next.fireAt.difference(now);
    _nextAlert = Timer(delay.isNegative ? Duration.zero : delay, () {
      _alert(next);
      _armNextAlert();
    });
  }

  String _key(PlannedReminder r) => '${r.task.id}@${r.fireAt}';

  Future<void> _alert(PlannedReminder r) async {
    _alerted.add(_key(r));
    final settings = _ref.read(settingsProvider);
    final foreground =
        WidgetsBinding.instance.lifecycleState == AppLifecycleState.resumed;
    if (!_notifications.canSchedule) {
      await _notifications.showNow(r, use24Hour: settings.use24HourFormat);
    }
    // Phones already make the notification sound; desktops and the web get
    // the app's own chime while the app is open.
    if (foreground && (_isDesktop || kIsWeb) && settings.reminderSoundEnabled) {
      unawaited(ReminderSoundService.play(settings.reminderSound));
    }
    if (_isDesktop && settings.bringWindowToFrontOnReminder) {
      try {
        await WindowToFront.activate();
      } catch (_) {}
    }
  }

  Future<void> _handle(ReminderResponse response) async {
    final task = await findTask(_repo, response.payload);
    if (task == null) return;
    switch (response.action) {
      case NotificationService.actionDone:
        await _ref.read(taskServiceProvider).setCompleted(task, true);
      case NotificationService.actionSnooze:
        _ref
            .read(reminderAcksProvider.notifier)
            .snoozeUntil(task.id, DateTime.now().add(_snoozeFor));
      default:
        _openTask?.call(task);
    }
  }

  /// Asks for notification permission the first time the user sets a
  /// reminder. Returns whether reminders can be shown.
  Future<bool> ensurePermission() async {
    try {
      return await _notifications.requestPermission();
    } catch (_) {
      return false;
    }
  }
}

final reminderCoordinatorProvider = Provider<ReminderCoordinator>((ref) {
  final coordinator = ReminderCoordinator(ref);
  ref.onDispose(coordinator.dispose);
  return coordinator;
});

/// Finds the task or occurrence a reminder refers to.
Future<Task?> findTask(TaskRepository repo, ReminderPayload payload) async {
  final day = LocalDate.of(payload.start);
  final tasks = await repo.getRange(day.startOfDay, day.addDays(1).startOfDay);
  return tasks.where((t) => t.id == payload.taskId).firstOrNull;
}

/// Handles "Done" and "Snooze" pressed on a notification while TimeFlow
/// isn't running. Runs in a background isolate, so it opens its own
/// database and preferences.
@pragma('vm:entry-point')
Future<void> notificationBackgroundHandler(NotificationResponse raw) async {
  WidgetsFlutterBinding.ensureInitialized();
  final response = NotificationService.parseResponse(raw);
  if (response == null) return;
  final db = AppDatabase();
  try {
    final repo = TaskRepository(db);
    final task = await findTask(repo, response.payload);
    if (task == null) return;
    if (response.action == NotificationService.actionDone) {
      await TaskService(repo).setCompleted(task, true);
    } else if (response.action == NotificationService.actionSnooze) {
      final until = DateTime.now().add(_snoozeFor);
      final prefs = await SharedPreferences.getInstance();
      final acks = Map.of(ReminderAcksNotifier.load(prefs));
      acks[task.id] = ReminderAck(snoozedUntil: until);
      await ReminderAcksNotifier.save(prefs, acks);
      final notifications = NotificationService();
      await notifications.initialize(onResponse: (_) {});
      await notifications.scheduleOne(
        payload: response.payload,
        title: task.title,
        fireAt: until,
      );
    }
  } finally {
    await db.close();
  }
}
