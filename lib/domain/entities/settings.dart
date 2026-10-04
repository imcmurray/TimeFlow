import 'package:flutter/foundation.dart';

/// User preferences.
@immutable
class Settings {
  /// 'light', 'dark', or 'auto' (follow the system).
  final String theme;

  /// Reminder offset pre-filled for new tasks, in minutes.
  final int defaultReminderMinutes;

  /// Master switch for task reminders.
  final bool notificationsEnabled;

  /// True until onboarding has been completed.
  final bool firstLaunch;

  /// Later times at the top, flowing down toward the NOW line.
  final bool upcomingTasksAboveNow;

  /// Desktop: raise the window when a reminder fires.
  final bool bringWindowToFrontOnReminder;

  /// Play a sound when a reminder fires while the app is open.
  final bool reminderSoundEnabled;

  /// 'chime', 'bell', 'alert' or 'soft'.
  final String reminderSound;

  /// The user's explicit 12/24-hour choice; null follows the system.
  final bool? use24HourPreference;

  /// Whether the system uses a 24-hour clock (used when there's no explicit
  /// preference).
  final bool systemUses24Hour;

  /// Location for sunrise/sunset times.
  final double latitude;
  final double longitude;

  /// Whether [latitude]/[longitude] were chosen by the user rather than
  /// estimated from the time zone.
  final bool hasChosenLocation;

  final bool showSunTimes;

  // Day watermark contents.
  final bool watermarkShowWeekNumber;
  final bool watermarkShowDayOfYear;
  final bool watermarkShowHolidays;
  final bool watermarkShowMoonPhase;
  final bool watermarkShowQuarter;
  final bool watermarkShowDaysRemaining;

  /// Holiday calendar code ('us', 'uk', ... or 'none').
  final String holidayRegion;

  /// Where the NOW line sits, as a fraction of the screen height from the top.
  final double nowLineViewportPosition;

  /// Default length of a task created by long-pressing the timeline.
  final int longPressDefaultDurationMinutes;

  /// Minutes that long-press task times snap to (5, 15 or 30).
  final int longPressSnapIntervalMinutes;

  final bool hasSeenLongPressHint;

  /// Timeline zoom: 1.0 is 80 pixels per hour.
  final double timelineZoom;

  const Settings({
    this.theme = 'auto',
    this.defaultReminderMinutes = 10,
    this.notificationsEnabled = true,
    this.firstLaunch = true,
    this.upcomingTasksAboveNow = true,
    this.bringWindowToFrontOnReminder = true,
    this.reminderSoundEnabled = true,
    this.reminderSound = 'chime',
    this.use24HourPreference,
    this.systemUses24Hour = false,
    this.latitude = 40.0,
    this.longitude = 0.0,
    this.hasChosenLocation = false,
    this.showSunTimes = true,
    this.watermarkShowWeekNumber = true,
    this.watermarkShowDayOfYear = false,
    this.watermarkShowHolidays = true,
    this.watermarkShowMoonPhase = false,
    this.watermarkShowQuarter = false,
    this.watermarkShowDaysRemaining = false,
    this.holidayRegion = 'us',
    this.nowLineViewportPosition = 0.75,
    this.longPressDefaultDurationMinutes = 60,
    this.longPressSnapIntervalMinutes = 15,
    this.hasSeenLongPressHint = false,
    this.timelineZoom = 1.0,
  });

  /// Whether to show times as 14:30 rather than 2:30 PM.
  bool get use24HourFormat => use24HourPreference ?? systemUses24Hour;

  static const _keep = Object();

  Settings copyWith({
    String? theme,
    int? defaultReminderMinutes,
    bool? notificationsEnabled,
    bool? firstLaunch,
    bool? upcomingTasksAboveNow,
    bool? bringWindowToFrontOnReminder,
    bool? reminderSoundEnabled,
    String? reminderSound,
    Object? use24HourPreference = _keep,
    bool? systemUses24Hour,
    double? latitude,
    double? longitude,
    bool? hasChosenLocation,
    bool? showSunTimes,
    bool? watermarkShowWeekNumber,
    bool? watermarkShowDayOfYear,
    bool? watermarkShowHolidays,
    bool? watermarkShowMoonPhase,
    bool? watermarkShowQuarter,
    bool? watermarkShowDaysRemaining,
    String? holidayRegion,
    double? nowLineViewportPosition,
    int? longPressDefaultDurationMinutes,
    int? longPressSnapIntervalMinutes,
    bool? hasSeenLongPressHint,
    double? timelineZoom,
  }) {
    return Settings(
      theme: theme ?? this.theme,
      defaultReminderMinutes:
          defaultReminderMinutes ?? this.defaultReminderMinutes,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      firstLaunch: firstLaunch ?? this.firstLaunch,
      upcomingTasksAboveNow:
          upcomingTasksAboveNow ?? this.upcomingTasksAboveNow,
      bringWindowToFrontOnReminder:
          bringWindowToFrontOnReminder ?? this.bringWindowToFrontOnReminder,
      reminderSoundEnabled: reminderSoundEnabled ?? this.reminderSoundEnabled,
      reminderSound: reminderSound ?? this.reminderSound,
      use24HourPreference: identical(use24HourPreference, _keep)
          ? this.use24HourPreference
          : use24HourPreference as bool?,
      systemUses24Hour: systemUses24Hour ?? this.systemUses24Hour,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      hasChosenLocation: hasChosenLocation ?? this.hasChosenLocation,
      showSunTimes: showSunTimes ?? this.showSunTimes,
      watermarkShowWeekNumber:
          watermarkShowWeekNumber ?? this.watermarkShowWeekNumber,
      watermarkShowDayOfYear:
          watermarkShowDayOfYear ?? this.watermarkShowDayOfYear,
      watermarkShowHolidays:
          watermarkShowHolidays ?? this.watermarkShowHolidays,
      watermarkShowMoonPhase:
          watermarkShowMoonPhase ?? this.watermarkShowMoonPhase,
      watermarkShowQuarter: watermarkShowQuarter ?? this.watermarkShowQuarter,
      watermarkShowDaysRemaining:
          watermarkShowDaysRemaining ?? this.watermarkShowDaysRemaining,
      holidayRegion: holidayRegion ?? this.holidayRegion,
      nowLineViewportPosition:
          nowLineViewportPosition ?? this.nowLineViewportPosition,
      longPressDefaultDurationMinutes:
          longPressDefaultDurationMinutes ??
          this.longPressDefaultDurationMinutes,
      longPressSnapIntervalMinutes:
          longPressSnapIntervalMinutes ?? this.longPressSnapIntervalMinutes,
      hasSeenLongPressHint: hasSeenLongPressHint ?? this.hasSeenLongPressHint,
      timelineZoom: timelineZoom ?? this.timelineZoom,
    );
  }
}
