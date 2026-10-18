import 'dart:async';
import 'dart:ui' show DartPluginRegistrant;

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
import 'package:timeflow/services/background_breadcrumb.dart';
import 'package:timeflow/services/notification_service.dart';
import 'package:timeflow/services/reminder_actions.dart';
import 'package:timeflow/services/reminder_sound_service.dart';
import 'package:timeflow/services/task_service.dart';
import 'package:window_to_front/window_to_front.dart';

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
      // The background handler may have snoozed or completed something,
      // through its own database connection.
      _repo.markChangedElsewhere();
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

  /// The same four outcomes as [notificationBackgroundHandler], from the same
  /// [ReminderIntent]. They were two switches on two action identifiers, and
  /// the pair of them disagreeing is how Done could complete a task in one
  /// isolate and not the other (TimeFlow#68).
  Future<void> _handle(ReminderResponse response) async {
    final task = await findTask(_repo, response.payload);
    if (task == null) return;
    switch (response.intent) {
      case ReminderIntent.complete:
        await _ref.read(taskServiceProvider).setCompleted(task, true);
      case ReminderIntent.snooze:
        _ref
            .read(reminderAcksProvider.notifier)
            .snoozeUntil(task.id, DateTime.now().add(response.action!.snooze!));
      case ReminderIntent.dismiss:
        // Seen, not done: the in-app alert has to go too, or the app keeps
        // nagging about a reminder the tester already answered.
        _ref.read(reminderAcksProvider.notifier).acknowledge(task);
      case ReminderIntent.open:
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

/// Handles a button pressed on a reminder while TimeFlow isn't running. Runs in
/// a background isolate, so it opens its own database and preferences.
///
/// Every step leaves a [BackgroundBreadcrumb], because this is the path that
/// failed on a tester's iPhone in a release build and passed on every simulator
/// in a debug one (TimeFlow#68). Nobody can attach a debugger to a tester's
/// phone; the isolate writes down how far it got, and Settings → About shows it
/// on a beta build.
@pragma('vm:entry-point')
Future<void> notificationBackgroundHandler(NotificationResponse raw) async {
  WidgetsFlutterBinding.ensureInitialized();
  // In a background isolate the plugins this handler needs — path_provider for
  // the database's directory, shared_preferences for the acks — are not
  // registered by ensureInitialized() alone. This is what registers them, and
  // its absence is a documented way for exactly this handler to do nothing.
  DartPluginRegistrant.ensureInitialized();
  await BackgroundBreadcrumb.note(
    '${BackgroundBreadcrumb.received} ${raw.actionId ?? 'tap'}',
  );
  await BackgroundBreadcrumb.note(BackgroundBreadcrumb.plugins);
  final response = NotificationService.parseResponse(raw);
  if (response == null) {
    await BackgroundBreadcrumb.failed('the notification carried no task');
    return;
  }
  final db = AppDatabase();
  try {
    await BackgroundBreadcrumb.note(BackgroundBreadcrumb.database);
    final repo = TaskRepository(db);
    final task = await findTask(repo, response.payload);
    if (task == null) {
      await BackgroundBreadcrumb.failed(
        'no task for ${response.payload.taskId}',
      );
      return;
    }
    await BackgroundBreadcrumb.note(BackgroundBreadcrumb.found);
    await applyInBackground(repo, response, task);
    await BackgroundBreadcrumb.note(BackgroundBreadcrumb.written);
  } catch (e) {
    // Swallowed before as well, only silently: the isolate has nowhere to
    // report to, which is the whole reason for the breadcrumb.
    await BackgroundBreadcrumb.failed(e);
  } finally {
    await db.close();
  }
}

/// What a button does when the app isn't running: the same four outcomes as
/// [ReminderCoordinator._handle], written straight to the stores a background
/// isolate can reach. Separate from the handler so a test can drive it without
/// a notification plugin in the way.
@visibleForTesting
Future<void> applyInBackground(
  TaskRepository repo,
  ReminderResponse response,
  Task task,
) async {
  switch (response.intent) {
    case ReminderIntent.complete:
      await writeWithRetries(() => TaskService(repo).setCompleted(task, true));
    case ReminderIntent.snooze:
      // The ack first, and the new notification after, each on its own: if
      // scheduling fails the snooze still stands, so the app stops alerting
      // about a reminder the tester has already answered. The breadcrumb says
      // when that happened rather than letting it pass for success.
      final until = DateTime.now().add(response.action!.snooze!);
      await _writeAck(task.id, ReminderAck(snoozedUntil: until));
      try {
        final notifications = NotificationService();
        await notifications.initialize(onResponse: (_) {});
        await notifications.scheduleOne(
          payload: response.payload,
          title: task.title,
          fireAt: until,
        );
      } catch (e) {
        await BackgroundBreadcrumb.failed('snoozed, but not rescheduled: $e');
      }
    case ReminderIntent.dismiss:
      await _writeAck(task.id, const ReminderAck(acknowledged: true));
    case ReminderIntent.open:
      // A tap, not a button: the system brings the app up and the main isolate
      // opens the task from launchResponse().
      break;
  }
}

/// How long to wait before trying a refused write again.
const backgroundWriteWaits = [
  Duration(milliseconds: 200),
  Duration(milliseconds: 400),
  Duration(milliseconds: 800),
];

/// Runs [write], trying again if another connection is holding the database.
///
/// WAL stopped a *reader* in the app's main isolate from blocking this commit,
/// which is what a tester lost a *Completed* to. A writer there still blocks
/// it: two connections in one process never wait for each other, because
/// SQLite returns `SQLITE_BUSY` rather than risk a deadlock, however long
/// `busy_timeout` is. On a background launch the main isolate is almost always
/// only reading, so this covers the narrow rest — a first launch still seeding
/// categories, a migration — where a second or so is plenty.
///
/// Anything that isn't the lock is thrown straight on: a write that fails for
/// its own reasons should reach the breadcrumb now, not in three tries' time.
@visibleForTesting
Future<void> writeWithRetries(
  Future<void> Function() write, {
  List<Duration> waits = backgroundWriteWaits,
}) async {
  for (var attempt = 0; ; attempt++) {
    try {
      await write();
      return;
    } catch (e) {
      if (attempt >= waits.length ||
          !e.toString().toLowerCase().contains('database is locked')) {
        rethrow;
      }
      await BackgroundBreadcrumb.note(
        '${BackgroundBreadcrumb.locked} ${waits[attempt].inMilliseconds}ms',
      );
      await Future<void>.delayed(waits[attempt]);
    }
  }
}

Future<void> _writeAck(String taskId, ReminderAck ack) async {
  final prefs = await SharedPreferences.getInstance();
  final acks = Map.of(ReminderAcksNotifier.load(prefs));
  acks[taskId] = ack;
  await ReminderAcksNotifier.save(prefs, acks);
}
