import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeflow/domain/entities/settings.dart';
import 'package:timeflow/services/sun_times_service.dart';

/// The preferences store, loaded in `main()` before the first frame so
/// settings are available synchronously (no flash of defaults or of the
/// onboarding screen). Tests override it with mock values.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('Override in main() or the test'),
);

/// App settings, persisted to shared preferences.
class SettingsNotifier extends Notifier<Settings> {
  // Keys predate 1.0; keep them so existing users keep their settings.
  static const _theme = 'timeflow_theme';
  static const _defaultReminderMinutes = 'timeflow_default_reminder_minutes';
  static const _notificationsEnabled = 'timeflow_notifications_enabled';
  static const _firstLaunch = 'timeflow_first_launch';
  static const _upcomingTasksAboveNow = 'timeflow_upcoming_tasks_above_now';
  static const _bringWindowToFront = 'timeflow_bring_window_to_front';
  static const _reminderSoundEnabled = 'timeflow_reminder_sound_enabled';
  static const _reminderSound = 'timeflow_reminder_sound';
  static const _use24HourFormat = 'timeflow_use_24_hour_format';
  static const _latitude = 'timeflow_latitude';
  static const _longitude = 'timeflow_longitude';
  static const _showSunTimes = 'timeflow_show_sun_times';
  static const _watermarkWeekNumber = 'timeflow_watermark_show_week_number';
  static const _watermarkDayOfYear = 'timeflow_watermark_show_day_of_year';
  static const _watermarkHolidays = 'timeflow_watermark_show_holidays';
  static const _watermarkMoonPhase = 'timeflow_watermark_show_moon_phase';
  static const _watermarkQuarter = 'timeflow_watermark_show_quarter';
  static const _watermarkDaysRemaining =
      'timeflow_watermark_show_days_remaining';
  static const _holidayRegion = 'timeflow_holiday_region';
  static const _nowLinePosition = 'timeflow_now_line_viewport_position';
  static const _longPressDuration = 'timeflow_longpress_default_duration';
  static const _longPressSnap = 'timeflow_longpress_snap_interval';
  static const _seenLongPressHint = 'timeflow_has_seen_longpress_hint';
  static const _timelineZoom = 'timeflow_timeline_zoom';

  late SharedPreferences _prefs;

  @override
  Settings build() {
    _prefs = ref.watch(sharedPreferencesProvider);
    final p = _prefs;
    const d = Settings();
    final hasLocation = p.containsKey(_latitude) && p.containsKey(_longitude);
    return Settings(
      theme: p.getString(_theme) ?? d.theme,
      defaultReminderMinutes:
          p.getInt(_defaultReminderMinutes) ?? d.defaultReminderMinutes,
      notificationsEnabled:
          p.getBool(_notificationsEnabled) ?? d.notificationsEnabled,
      firstLaunch: p.getBool(_firstLaunch) ?? d.firstLaunch,
      upcomingTasksAboveNow:
          p.getBool(_upcomingTasksAboveNow) ?? d.upcomingTasksAboveNow,
      bringWindowToFrontOnReminder:
          p.getBool(_bringWindowToFront) ?? d.bringWindowToFrontOnReminder,
      reminderSoundEnabled:
          p.getBool(_reminderSoundEnabled) ?? d.reminderSoundEnabled,
      reminderSound: p.getString(_reminderSound) ?? d.reminderSound,
      use24HourPreference: p.getBool(_use24HourFormat),
      systemUses24Hour:
          WidgetsBinding.instance.platformDispatcher.alwaysUse24HourFormat,
      latitude: hasLocation ? p.getDouble(_latitude)! : d.latitude,
      longitude: hasLocation
          ? p.getDouble(_longitude)!
          : SunTimesService.estimateLongitudeFromTimezone(),
      hasChosenLocation: hasLocation,
      showSunTimes: p.getBool(_showSunTimes) ?? d.showSunTimes,
      watermarkShowWeekNumber:
          p.getBool(_watermarkWeekNumber) ?? d.watermarkShowWeekNumber,
      watermarkShowDayOfYear:
          p.getBool(_watermarkDayOfYear) ?? d.watermarkShowDayOfYear,
      watermarkShowHolidays:
          p.getBool(_watermarkHolidays) ?? d.watermarkShowHolidays,
      watermarkShowMoonPhase:
          p.getBool(_watermarkMoonPhase) ?? d.watermarkShowMoonPhase,
      watermarkShowQuarter:
          p.getBool(_watermarkQuarter) ?? d.watermarkShowQuarter,
      watermarkShowDaysRemaining:
          p.getBool(_watermarkDaysRemaining) ?? d.watermarkShowDaysRemaining,
      holidayRegion: p.getString(_holidayRegion) ?? d.holidayRegion,
      nowLineViewportPosition:
          p.getDouble(_nowLinePosition) ?? d.nowLineViewportPosition,
      longPressDefaultDurationMinutes:
          p.getInt(_longPressDuration) ?? d.longPressDefaultDurationMinutes,
      longPressSnapIntervalMinutes:
          p.getInt(_longPressSnap) ?? d.longPressSnapIntervalMinutes,
      hasSeenLongPressHint:
          p.getBool(_seenLongPressHint) ?? d.hasSeenLongPressHint,
      timelineZoom: p.getDouble(_timelineZoom) ?? d.timelineZoom,
    );
  }

  void _setBool(String key, bool value, Settings next) {
    state = next;
    _prefs.setBool(key, value);
  }

  void _setInt(String key, int value, Settings next) {
    state = next;
    _prefs.setInt(key, value);
  }

  void _setDouble(String key, double value, Settings next) {
    state = next;
    _prefs.setDouble(key, value);
  }

  void _setString(String key, String value, Settings next) {
    state = next;
    _prefs.setString(key, value);
  }

  void setTheme(String v) => _setString(_theme, v, state.copyWith(theme: v));

  void setDefaultReminderMinutes(int v) => _setInt(
      _defaultReminderMinutes, v, state.copyWith(defaultReminderMinutes: v));

  void setNotificationsEnabled(bool v) => _setBool(
      _notificationsEnabled, v, state.copyWith(notificationsEnabled: v));

  void setFirstLaunch(bool v) =>
      _setBool(_firstLaunch, v, state.copyWith(firstLaunch: v));

  void setUpcomingTasksAboveNow(bool v) => _setBool(
      _upcomingTasksAboveNow, v, state.copyWith(upcomingTasksAboveNow: v));

  void setBringWindowToFrontOnReminder(bool v) => _setBool(
      _bringWindowToFront, v, state.copyWith(bringWindowToFrontOnReminder: v));

  void setReminderSoundEnabled(bool v) => _setBool(
      _reminderSoundEnabled, v, state.copyWith(reminderSoundEnabled: v));

  void setReminderSound(String v) =>
      _setString(_reminderSound, v, state.copyWith(reminderSound: v));

  /// null follows the system setting.
  void setUse24HourPreference(bool? v) {
    state = state.copyWith(use24HourPreference: v);
    if (v == null) {
      _prefs.remove(_use24HourFormat);
    } else {
      _prefs.setBool(_use24HourFormat, v);
    }
  }

  void setLocation(double latitude, double longitude) {
    state = state.copyWith(
        latitude: latitude, longitude: longitude, hasChosenLocation: true);
    _prefs.setDouble(_latitude, latitude);
    _prefs.setDouble(_longitude, longitude);
  }

  void setShowSunTimes(bool v) =>
      _setBool(_showSunTimes, v, state.copyWith(showSunTimes: v));

  void setWatermarkShowWeekNumber(bool v) => _setBool(
      _watermarkWeekNumber, v, state.copyWith(watermarkShowWeekNumber: v));

  void setWatermarkShowDayOfYear(bool v) => _setBool(
      _watermarkDayOfYear, v, state.copyWith(watermarkShowDayOfYear: v));

  void setWatermarkShowHolidays(bool v) =>
      _setBool(_watermarkHolidays, v, state.copyWith(watermarkShowHolidays: v));

  void setWatermarkShowMoonPhase(bool v) => _setBool(
      _watermarkMoonPhase, v, state.copyWith(watermarkShowMoonPhase: v));

  void setWatermarkShowQuarter(bool v) =>
      _setBool(_watermarkQuarter, v, state.copyWith(watermarkShowQuarter: v));

  void setWatermarkShowDaysRemaining(bool v) => _setBool(
      _watermarkDaysRemaining,
      v,
      state.copyWith(watermarkShowDaysRemaining: v));

  void setHolidayRegion(String v) =>
      _setString(_holidayRegion, v, state.copyWith(holidayRegion: v));

  /// Fraction of the screen height from the top, clamped to 0.1..0.9.
  void setNowLineViewportPosition(double v) {
    final clamped = v.clamp(0.1, 0.9);
    _setDouble(_nowLinePosition, clamped,
        state.copyWith(nowLineViewportPosition: clamped));
  }

  void setLongPressDefaultDuration(int v) => _setInt(_longPressDuration, v,
      state.copyWith(longPressDefaultDurationMinutes: v));

  void setLongPressSnapInterval(int v) {
    final valid = const [5, 15, 30].contains(v) ? v : 15;
    _setInt(_longPressSnap, valid,
        state.copyWith(longPressSnapIntervalMinutes: valid));
  }

  void setHasSeenLongPressHint(bool v) =>
      _setBool(_seenLongPressHint, v, state.copyWith(hasSeenLongPressHint: v));

  void setTimelineZoom(double v) =>
      _setDouble(_timelineZoom, v, state.copyWith(timelineZoom: v));
}

final settingsProvider =
    NotifierProvider<SettingsNotifier, Settings>(SettingsNotifier.new);
