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

  /// User's latitude for sunrise/sunset calculations.
  /// Default is 40°N (continental US average, good for MST/CST/EST regions).
  final double latitude;

  /// User's longitude for sunrise/sunset calculations.
  /// Default is 0.0 which signals auto-detection from device timezone.
  final double longitude;

  /// Manual timezone offset in hours (e.g., -5 for EST, +1 for CET).
  /// Null means auto-detect from device.
  final double? timezoneOffsetHours;

  /// Whether to show sunrise/sunset indicators on the timeline.
  final bool showSunTimes;

  // Watermark display options

  /// Whether to show week number in day watermark.
  final bool watermarkShowWeekNumber;

  /// Whether to show day of year in day watermark.
  final bool watermarkShowDayOfYear;

  /// Whether to show holidays in day watermark.
  final bool watermarkShowHolidays;

  /// Whether to show moon phase in day watermark.
  final bool watermarkShowMoonPhase;

  /// Whether to show quarter in day watermark.
  final bool watermarkShowQuarter;

  /// Whether to show days remaining in year in day watermark.
  final bool watermarkShowDaysRemaining;

  /// Custom NOW line offset in minutes from midnight.
  /// When null, the NOW line follows the actual current time.
  /// When set, the NOW line stays at this fixed position until reset.
  final int? customNowLineMinutesFromMidnight;

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
    this.latitude = 40.0,
    this.longitude = 0.0,
    this.timezoneOffsetHours,
    this.showSunTimes = true,
    this.watermarkShowWeekNumber = true,
    this.watermarkShowDayOfYear = false,
    this.watermarkShowHolidays = true,
    this.watermarkShowMoonPhase = false,
    this.watermarkShowQuarter = false,
    this.watermarkShowDaysRemaining = false,
    this.customNowLineMinutesFromMidnight,
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
    double? latitude,
    double? longitude,
    double? timezoneOffsetHours,
    bool clearTimezoneOffset = false,
    bool? showSunTimes,
    bool? watermarkShowWeekNumber,
    bool? watermarkShowDayOfYear,
    bool? watermarkShowHolidays,
    bool? watermarkShowMoonPhase,
    bool? watermarkShowQuarter,
    bool? watermarkShowDaysRemaining,
    int? customNowLineMinutesFromMidnight,
    bool clearCustomNowLine = false,
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
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      timezoneOffsetHours: clearTimezoneOffset ? null : (timezoneOffsetHours ?? this.timezoneOffsetHours),
      showSunTimes: showSunTimes ?? this.showSunTimes,
      watermarkShowWeekNumber: watermarkShowWeekNumber ?? this.watermarkShowWeekNumber,
      watermarkShowDayOfYear: watermarkShowDayOfYear ?? this.watermarkShowDayOfYear,
      watermarkShowHolidays: watermarkShowHolidays ?? this.watermarkShowHolidays,
      watermarkShowMoonPhase: watermarkShowMoonPhase ?? this.watermarkShowMoonPhase,
      watermarkShowQuarter: watermarkShowQuarter ?? this.watermarkShowQuarter,
      watermarkShowDaysRemaining: watermarkShowDaysRemaining ?? this.watermarkShowDaysRemaining,
      customNowLineMinutesFromMidnight: clearCustomNowLine ? null : (customNowLineMinutesFromMidnight ?? this.customNowLineMinutesFromMidnight),
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
        other.use24HourFormat == use24HourFormat &&
        other.latitude == latitude &&
        other.longitude == longitude &&
        other.timezoneOffsetHours == timezoneOffsetHours &&
        other.showSunTimes == showSunTimes &&
        other.watermarkShowWeekNumber == watermarkShowWeekNumber &&
        other.watermarkShowDayOfYear == watermarkShowDayOfYear &&
        other.watermarkShowHolidays == watermarkShowHolidays &&
        other.watermarkShowMoonPhase == watermarkShowMoonPhase &&
        other.watermarkShowQuarter == watermarkShowQuarter &&
        other.watermarkShowDaysRemaining == watermarkShowDaysRemaining &&
        other.customNowLineMinutesFromMidnight == customNowLineMinutesFromMidnight;
  }

  @override
  int get hashCode {
    return Object.hashAll([
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
      latitude,
      longitude,
      timezoneOffsetHours,
      showSunTimes,
      watermarkShowWeekNumber,
      watermarkShowDayOfYear,
      watermarkShowHolidays,
      watermarkShowMoonPhase,
      watermarkShowQuarter,
      watermarkShowDaysRemaining,
      customNowLineMinutesFromMidnight,
    ]);
  }

  @override
  String toString() {
    return 'Settings(theme: $theme, defaultReminderMinutes: $defaultReminderMinutes, '
        'timelineDensity: $timelineDensity, notificationsEnabled: $notificationsEnabled, '
        'firstLaunch: $firstLaunch, upcomingTasksAboveNow: $upcomingTasksAboveNow, '
        'bringWindowToFrontOnReminder: $bringWindowToFrontOnReminder, '
        'reminderSoundEnabled: $reminderSoundEnabled, reminderSound: $reminderSound, '
        'use24HourFormat: $use24HourFormat, latitude: $latitude, longitude: $longitude, '
        'timezoneOffsetHours: $timezoneOffsetHours, showSunTimes: $showSunTimes, '
        'watermarkShowWeekNumber: $watermarkShowWeekNumber, '
        'watermarkShowDayOfYear: $watermarkShowDayOfYear, '
        'watermarkShowHolidays: $watermarkShowHolidays, '
        'watermarkShowMoonPhase: $watermarkShowMoonPhase, '
        'watermarkShowQuarter: $watermarkShowQuarter, '
        'watermarkShowDaysRemaining: $watermarkShowDaysRemaining, '
        'customNowLineMinutesFromMidnight: $customNowLineMinutesFromMidnight)';
  }
}
