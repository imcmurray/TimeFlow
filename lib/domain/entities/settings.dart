/// Domain entity representing user Settings in TimeFlow.
///
/// Stores user preferences for theme, notifications, and timeline display.
class Settings {
  /// Theme mode: 'light', 'dark', or 'auto'.
  final String theme;

  /// Default number of minutes before a task to set reminders.
  final int defaultReminderMinutes;

  /// Zoom level for the timeline (1.0 is default, higher is more spread out).
  final double timelineDensity;

  /// Whether notifications are globally enabled.
  final bool notificationsEnabled;

  /// Whether this is the first launch (show onboarding).
  final bool firstLaunch;

  /// Whether upcoming tasks appear above the NOW line on the timeline.
  /// When true, later times render at the top and flow down toward the NOW line.
  final bool upcomingTasksAboveNow;

  /// Whether to bring the app window to front when a reminder triggers.
  final bool bringWindowToFrontOnReminder;

  /// Whether to play sound when reminder triggers.
  final bool reminderSoundEnabled;

  /// Which sound to play for reminders.
  /// Options: 'chime', 'bell', 'alert', 'soft'
  final String reminderSound;

  /// Whether to display time in 24-hour format (14:30) vs 12-hour (2:30 PM).
  final bool use24HourFormat;

  const Settings({
    this.theme = 'auto',
    this.defaultReminderMinutes = 10,
    this.timelineDensity = 1.0,
    this.notificationsEnabled = true,
    this.firstLaunch = true,
    this.upcomingTasksAboveNow = true,
    this.bringWindowToFrontOnReminder = true,
    this.reminderSoundEnabled = true,
    this.reminderSound = 'chime',
    this.use24HourFormat = false,
  });

  /// Default settings for first-time users.
  static const Settings defaults = Settings();

  /// Creates a copy of these settings with the given fields replaced.
  Settings copyWith({
    String? theme,
    int? defaultReminderMinutes,
    double? timelineDensity,
    bool? notificationsEnabled,
    bool? firstLaunch,
    bool? upcomingTasksAboveNow,
    bool? bringWindowToFrontOnReminder,
    bool? reminderSoundEnabled,
    String? reminderSound,
    bool? use24HourFormat,
  }) {
    return Settings(
      theme: theme ?? this.theme,
      defaultReminderMinutes: defaultReminderMinutes ?? this.defaultReminderMinutes,
      timelineDensity: timelineDensity ?? this.timelineDensity,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      firstLaunch: firstLaunch ?? this.firstLaunch,
      upcomingTasksAboveNow: upcomingTasksAboveNow ?? this.upcomingTasksAboveNow,
      bringWindowToFrontOnReminder: bringWindowToFrontOnReminder ?? this.bringWindowToFrontOnReminder,
      reminderSoundEnabled: reminderSoundEnabled ?? this.reminderSoundEnabled,
      reminderSound: reminderSound ?? this.reminderSound,
      use24HourFormat: use24HourFormat ?? this.use24HourFormat,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Settings &&
        other.theme == theme &&
        other.defaultReminderMinutes == defaultReminderMinutes &&
        other.timelineDensity == timelineDensity &&
        other.notificationsEnabled == notificationsEnabled &&
        other.firstLaunch == firstLaunch &&
        other.upcomingTasksAboveNow == upcomingTasksAboveNow &&
        other.bringWindowToFrontOnReminder == bringWindowToFrontOnReminder &&
        other.reminderSoundEnabled == reminderSoundEnabled &&
        other.reminderSound == reminderSound &&
        other.use24HourFormat == use24HourFormat;
  }

  @override
  int get hashCode {
    return Object.hash(
      theme,
      defaultReminderMinutes,
      timelineDensity,
      notificationsEnabled,
      firstLaunch,
      upcomingTasksAboveNow,
      bringWindowToFrontOnReminder,
      reminderSoundEnabled,
      reminderSound,
      use24HourFormat,
    );
  }

  @override
  String toString() {
    return 'Settings(theme: $theme, defaultReminderMinutes: $defaultReminderMinutes, '
        'timelineDensity: $timelineDensity, notificationsEnabled: $notificationsEnabled, '
        'firstLaunch: $firstLaunch, upcomingTasksAboveNow: $upcomingTasksAboveNow, '
        'bringWindowToFrontOnReminder: $bringWindowToFrontOnReminder, '
        'reminderSoundEnabled: $reminderSoundEnabled, reminderSound: $reminderSound, '
        'use24HourFormat: $use24HourFormat)';
  }
}
