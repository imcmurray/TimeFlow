import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:timeflow/domain/reminders/reminder_planner.dart';
import 'package:timeflow/domain/time/wall_clock.dart';
import 'package:timeflow/services/reminder_actions.dart';
import 'package:timeflow/presentation/utils/time_formatter.dart';

/// What a notification refers to, carried in its payload.
@immutable
class ReminderPayload {
  /// Id of the task or occurrence (occurrence ids look like `series@20261004`).
  final String taskId;

  /// Start of the task, to find the occurrence again.
  final DateTime start;

  const ReminderPayload(this.taskId, this.start);

  String encode() =>
      jsonEncode({'id': taskId, 'start': formatWallClock(start)});

  static ReminderPayload? decode(String? payload) {
    if (payload == null) return null;
    try {
      final j = jsonDecode(payload) as Map<String, dynamic>;
      return ReminderPayload(
        j['id'] as String,
        parseWallClock(j['start'] as String),
      );
    } catch (_) {
      return null;
    }
  }
}

/// A tap on a notification or one of its buttons.
@immutable
class ReminderResponse {
  final ReminderPayload payload;

  /// The button pressed, or null for a tap on the notification itself — and
  /// also for an identifier this build doesn't know, which an older or newer
  /// build's notification can carry. Both open the task, which is the safe
  /// reading of "something was pressed and we can't tell what".
  final ReminderAction? action;

  const ReminderResponse(this.payload, this.action);

  ReminderIntent get intent => action?.intent ?? ReminderIntent.open;
}

/// Delivers task reminders as system notifications.
///
/// On Android, iOS, macOS and Windows reminders are scheduled with the
/// operating system, so they arrive even when TimeFlow isn't running. Linux
/// and browsers can't schedule notifications; there the caller shows them
/// with [showNow] while the app is open ([canSchedule] is false).
class NotificationService {
  NotificationService([FlutterLocalNotificationsPlugin? plugin])
    : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  final FlutterLocalNotificationsPlugin _plugin;

  static const _category = 'task_reminder';
  static const _channelId = 'task_reminders';

  bool _initialized = false;

  /// Whether reminders can be scheduled ahead of time on this platform.
  bool get canSchedule =>
      !kIsWeb &&
      const {
        TargetPlatform.android,
        TargetPlatform.iOS,
        TargetPlatform.macOS,
        TargetPlatform.windows,
      }.contains(defaultTargetPlatform);

  /// Sets up the plugin. [onResponse] handles taps while the app runs;
  /// [onBackgroundResponse] must be a top-level function and handles action
  /// buttons pressed while the app isn't running.
  Future<void> initialize({
    required void Function(ReminderResponse) onResponse,
    DidReceiveBackgroundNotificationResponseCallback? onBackgroundResponse,
  }) async {
    if (_initialized) return;
    tzdata.initializeTimeZones();

    final darwin = DarwinInitializationSettings(
      // Ask when the user first sets a reminder, not at launch.
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
      notificationCategories: [
        DarwinNotificationCategory(
          _category,
          // `plain`, so none of them opens the app: the point of these buttons
          // is answering a reminder from the lock screen.
          actions: [
            for (final a in ReminderActions.onDarwin)
              DarwinNotificationAction.plain(a.id, a.label),
          ],
        ),
      ],
    );
    await _plugin.initialize(
      settings: InitializationSettings(
        android: const AndroidInitializationSettings('ic_stat_timeflow'),
        iOS: darwin,
        macOS: darwin,
        linux: const LinuxInitializationSettings(defaultActionName: 'Open'),
        windows: const WindowsInitializationSettings(
          appName: 'TimeFlow',
          appUserModelId: 'RinseRepeatLabs.TimeFlow',
          guid: '6d6a0a8e-6a3c-4b5e-9d43-1f3c7f2a9b10',
        ),
      ),
      onDidReceiveNotificationResponse: (r) {
        final response = _toResponse(r);
        if (response != null) onResponse(response);
      },
      onDidReceiveBackgroundNotificationResponse: onBackgroundResponse,
    );
    _initialized = true;
  }

  static ReminderResponse? _toResponse(NotificationResponse r) {
    final payload = ReminderPayload.decode(r.payload);
    if (payload == null) return null;
    return ReminderResponse(payload, ReminderActions.byId(r.actionId));
  }

  /// Public for the background handler, which receives raw responses.
  static ReminderResponse? parseResponse(NotificationResponse r) =>
      _toResponse(r);

  /// The response that launched the app, if it was opened from a reminder.
  Future<ReminderResponse?> launchResponse() async {
    if (kIsWeb) return null;
    final NotificationAppLaunchDetails? details;
    try {
      details = await _plugin.getNotificationAppLaunchDetails();
    } on UnimplementedError {
      return null; // Linux and Windows can't report this.
    }
    final r = details?.notificationResponse;
    if (details?.didNotificationLaunchApp != true || r == null) return null;
    return _toResponse(r);
  }

  /// Asks for permission to show notifications. Returns whether reminders
  /// can be shown. Call it in response to a user action.
  Future<bool> requestPermission() async {
    if (kIsWeb) {
      return await _plugin
              .resolvePlatformSpecificImplementation<
                WebFlutterLocalNotificationsPlugin
              >()
              ?.requestNotificationsPermission() ??
          false;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final android = _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >();
        return await android?.requestNotificationsPermission() ?? false;
      case TargetPlatform.iOS:
        return await _plugin
                .resolvePlatformSpecificImplementation<
                  IOSFlutterLocalNotificationsPlugin
                >()
                ?.requestPermissions(alert: true, sound: true) ??
            false;
      case TargetPlatform.macOS:
        return await _plugin
                .resolvePlatformSpecificImplementation<
                  MacOSFlutterLocalNotificationsPlugin
                >()
                ?.requestPermissions(alert: true, sound: true) ??
            false;
      default:
        return true;
    }
  }

  /// Whether notifications are currently allowed (null when unknown).
  Future<bool?> areEnabled() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return null;
    return _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.areNotificationsEnabled();
  }

  /// Android 12+: whether reminders can fire at the exact minute. Without
  /// this permission Android may deliver them a few minutes late.
  Future<bool> canUseExactTiming() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return true;
    return await _plugin
            .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin
            >()
            ?.canScheduleExactNotifications() ??
        true;
  }

  /// Opens the Android setting that allows exact reminders.
  Future<void> requestExactTiming() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestExactAlarmsPermission();
  }

  NotificationDetails _details() => NotificationDetails(
    android: AndroidNotificationDetails(
      _channelId,
      'Task reminders',
      channelDescription: 'Reminders before your tasks start',
      importance: Importance.high,
      priority: Priority.high,
      category: AndroidNotificationCategory.reminder,
      // Three at most on Android; the Darwin set is on the category instead,
      // which is why iOS can have four.
      actions: [
        for (final a in ReminderActions.onAndroid)
          AndroidNotificationAction(a.id, a.label),
      ],
    ),
    iOS: const DarwinNotificationDetails(categoryIdentifier: _category),
    macOS: const DarwinNotificationDetails(categoryIdentifier: _category),
  );

  String _body(PlannedReminder r, bool use24Hour) {
    final start = TimeFormatter.formatTime(
      r.task.startTime,
      use24HourFormat: use24Hour,
    );
    final minutes = r.task.startTime.difference(r.fireAt).inMinutes;
    final when = minutes <= 0
        ? 'Starting now'
        : minutes < 60
        ? 'In $minutes min'
        : minutes % 60 == 0
        ? 'In ${minutes ~/ 60} h'
        : 'In ${minutes ~/ 60} h ${minutes % 60} min';
    return '$when · $start';
  }

  /// Replaces all scheduled reminders with [plan].
  Future<void> scheduleAll(
    List<PlannedReminder> plan, {
    required bool use24Hour,
  }) async {
    if (!_initialized || !canSchedule) return;
    try {
      await _plugin.cancelAllPendingNotifications();
    } on UnimplementedError {
      await _plugin.cancelAll(); // Windows
    }
    final exact = await canUseExactTiming();
    for (final r in plan) {
      await _plugin.zonedSchedule(
        id: r.notificationId,
        title: r.task.title,
        body: _body(r, use24Hour),
        scheduledDate: tz.TZDateTime.from(r.fireAt.toUtc(), tz.UTC),
        notificationDetails: _details(),
        androidScheduleMode: exact
            ? AndroidScheduleMode.exactAllowWhileIdle
            : AndroidScheduleMode.inexactAllowWhileIdle,
        payload: ReminderPayload(r.task.id, r.task.startTime).encode(),
      );
    }
  }

  /// Shows a reminder immediately.
  Future<void> showNow(PlannedReminder r, {required bool use24Hour}) async {
    if (!_initialized) return;
    await _plugin.show(
      id: r.notificationId,
      title: r.task.title,
      body: _body(r, use24Hour),
      notificationDetails: _details(),
      payload: ReminderPayload(r.task.id, r.task.startTime).encode(),
    );
  }

  /// Schedules a single reminder at [fireAt] (used for snoozes from the
  /// background handler, where the full plan isn't available).
  Future<void> scheduleOne({
    required ReminderPayload payload,
    required String title,
    required DateTime fireAt,
  }) async {
    if (!_initialized || !canSchedule) return;
    await _plugin.zonedSchedule(
      id: PlannedReminder.notificationIdFor(payload.taskId),
      title: title,
      body: 'Snoozed reminder',
      scheduledDate: tz.TZDateTime.from(fireAt.toUtc(), tz.UTC),
      notificationDetails: _details(),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload.encode(),
    );
  }

  Future<void> cancelAll() async {
    if (!_initialized) return;
    await _plugin.cancelAll();
  }
}
