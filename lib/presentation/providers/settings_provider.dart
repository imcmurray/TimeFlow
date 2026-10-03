import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeflow/domain/entities/settings.dart';
import 'package:timeflow/services/sun_times_service.dart';

/// Notifier for managing app settings state with persistence.
class SettingsNotifier extends Notifier<Settings> {
  static const _keyTheme = 'timeflow_theme';
  static const _keyDefaultReminderMinutes = 'timeflow_default_reminder_minutes';
  static const _keyTimelineDensity = 'timeflow_timeline_density';
  static const _keyNotificationsEnabled = 'timeflow_notifications_enabled';
  static const _keyFirstLaunch = 'timeflow_first_launch';
  static const _keyUpcomingTasksAboveNow = 'timeflow_upcoming_tasks_above_now';
  static const _keyBringWindowToFront = 'timeflow_bring_window_to_front';
  static const _keyReminderSoundEnabled = 'timeflow_reminder_sound_enabled';
  static const _keyReminderSound = 'timeflow_reminder_sound';
  static const _keyUse24HourFormat = 'timeflow_use_24_hour_format';
  static const _keyLatitude = 'timeflow_latitude';
  static const _keyLongitude = 'timeflow_longitude';
  static const _keyTimezoneOffsetHours = 'timeflow_timezone_offset_hours';
  static const _keyShowSunTimes = 'timeflow_show_sun_times';
  // Watermark settings keys
  static const _keyWatermarkShowWeekNumber = 'timeflow_watermark_show_week_number';
  // Custom NOW line position
  static const _keyCustomNowLineMinutes = 'timeflow_custom_now_line_minutes';
  static const _keyNowLineViewportPosition = 'timeflow_now_line_viewport_position';
  static const _keyWatermarkShowDayOfYear = 'timeflow_watermark_show_day_of_year';
  static const _keyWatermarkShowHolidays = 'timeflow_watermark_show_holidays';
  static const _keyWatermarkShowMoonPhase = 'timeflow_watermark_show_moon_phase';
  static const _keyWatermarkShowQuarter = 'timeflow_watermark_show_quarter';
  static const _keyWatermarkShowDaysRemaining = 'timeflow_watermark_show_days_remaining';
  // Long-press task creation settings
  static const _keyLongPressDefaultDuration = 'timeflow_longpress_default_duration';
  static const _keyLongPressSnapInterval = 'timeflow_longpress_snap_interval';
  static const _keyHasSeenLongPressHint = 'timeflow_has_seen_longpress_hint';

  SharedPreferences? _prefs;

  @override
  Settings build() {
    _loadSettings();
    return const Settings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();

    // Auto-detect location from timezone if not previously set
    final hasCustomLocation = _prefs!.containsKey(_keyLatitude) &&
        _prefs!.containsKey(_keyLongitude);

    double latitude;
    double longitude;

    if (hasCustomLocation) {
      latitude = _prefs!.getDouble(_keyLatitude) ?? 40.0;
      longitude = _prefs!.getDouble(_keyLongitude) ?? 0.0;
    } else {
      // Estimate location from device timezone
      // Use 40°N as default (continental US average), estimate longitude from timezone
      latitude = 40.0;
      longitude = SunTimesService.estimateLongitudeFromTimezone();
    }

    // Load timezone offset (null means auto-detect)
    double? timezoneOffsetHours;
    if (_prefs!.containsKey(_keyTimezoneOffsetHours)) {
      timezoneOffsetHours = _prefs!.getDouble(_keyTimezoneOffsetHours);
    }

    state = Settings(
      theme: _prefs!.getString(_keyTheme) ?? 'auto',
      defaultReminderMinutes: _prefs!.getInt(_keyDefaultReminderMinutes) ?? 10,
      timelineDensity: _prefs!.getDouble(_keyTimelineDensity) ?? 1.0,
      notificationsEnabled: _prefs!.getBool(_keyNotificationsEnabled) ?? true,
      firstLaunch: _prefs!.getBool(_keyFirstLaunch) ?? true,
      upcomingTasksAboveNow: _prefs!.getBool(_keyUpcomingTasksAboveNow) ?? true,
      bringWindowToFrontOnReminder: _prefs!.getBool(_keyBringWindowToFront) ?? true,
      reminderSoundEnabled: _prefs!.getBool(_keyReminderSoundEnabled) ?? true,
      reminderSound: _prefs!.getString(_keyReminderSound) ?? 'chime',
      use24HourFormat: _prefs!.getBool(_keyUse24HourFormat) ?? false,
      latitude: latitude,
      longitude: longitude,
      timezoneOffsetHours: timezoneOffsetHours,
      showSunTimes: _prefs!.getBool(_keyShowSunTimes) ?? true,
      watermarkShowWeekNumber: _prefs!.getBool(_keyWatermarkShowWeekNumber) ?? true,
      watermarkShowDayOfYear: _prefs!.getBool(_keyWatermarkShowDayOfYear) ?? false,
      watermarkShowHolidays: _prefs!.getBool(_keyWatermarkShowHolidays) ?? true,
      watermarkShowMoonPhase: _prefs!.getBool(_keyWatermarkShowMoonPhase) ?? false,
      watermarkShowQuarter: _prefs!.getBool(_keyWatermarkShowQuarter) ?? false,
      watermarkShowDaysRemaining: _prefs!.getBool(_keyWatermarkShowDaysRemaining) ?? false,
      customNowLineMinutesFromMidnight: _prefs!.containsKey(_keyCustomNowLineMinutes)
          ? _prefs!.getInt(_keyCustomNowLineMinutes)
          : null,
      nowLineViewportPosition: _prefs!.getDouble(_keyNowLineViewportPosition) ?? 0.75,
      longPressDefaultDurationMinutes: _prefs!.getInt(_keyLongPressDefaultDuration) ?? 60,
      longPressSnapIntervalMinutes: _prefs!.getInt(_keyLongPressSnapInterval) ?? 15,
      hasSeenLongPressHint: _prefs!.getBool(_keyHasSeenLongPressHint) ?? false,
    );
  }

  Future<void> _ensurePrefs() async {
    _prefs ??= await SharedPreferences.getInstance();
  }

  Future<void> setTheme(String theme) async {
    state = state.copyWith(theme: theme);
    await _ensurePrefs();
    await _prefs!.setString(_keyTheme, theme);
  }

  Future<void> setDefaultReminderMinutes(int minutes) async {
    state = state.copyWith(defaultReminderMinutes: minutes);
    await _ensurePrefs();
    await _prefs!.setInt(_keyDefaultReminderMinutes, minutes);
  }

  Future<void> setTimelineDensity(double density) async {
    state = state.copyWith(timelineDensity: density);
    await _ensurePrefs();
    await _prefs!.setDouble(_keyTimelineDensity, density);
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    state = state.copyWith(notificationsEnabled: enabled);
    await _ensurePrefs();
    await _prefs!.setBool(_keyNotificationsEnabled, enabled);
  }

  Future<void> setFirstLaunch(bool firstLaunch) async {
    state = state.copyWith(firstLaunch: firstLaunch);
    await _ensurePrefs();
    await _prefs!.setBool(_keyFirstLaunch, firstLaunch);
  }

  Future<void> setUpcomingTasksAboveNow(bool value) async {
    state = state.copyWith(upcomingTasksAboveNow: value);
    await _ensurePrefs();
    await _prefs!.setBool(_keyUpcomingTasksAboveNow, value);
  }

  Future<void> setBringWindowToFrontOnReminder(bool value) async {
    state = state.copyWith(bringWindowToFrontOnReminder: value);
    await _ensurePrefs();
    await _prefs!.setBool(_keyBringWindowToFront, value);
  }

  Future<void> setReminderSoundEnabled(bool value) async {
    state = state.copyWith(reminderSoundEnabled: value);
    await _ensurePrefs();
    await _prefs!.setBool(_keyReminderSoundEnabled, value);
  }

  Future<void> setReminderSound(String sound) async {
    state = state.copyWith(reminderSound: sound);
    await _ensurePrefs();
    await _prefs!.setString(_keyReminderSound, sound);
  }

  Future<void> setUse24HourFormat(bool value) async {
    state = state.copyWith(use24HourFormat: value);
    await _ensurePrefs();
    await _prefs!.setBool(_keyUse24HourFormat, value);
  }

  Future<void> setLatitude(double value) async {
    state = state.copyWith(latitude: value);
    await _ensurePrefs();
    await _prefs!.setDouble(_keyLatitude, value);
  }

  Future<void> setLongitude(double value) async {
    state = state.copyWith(longitude: value);
    await _ensurePrefs();
    await _prefs!.setDouble(_keyLongitude, value);
  }

  Future<void> setLocation(double latitude, double longitude) async {
    state = state.copyWith(latitude: latitude, longitude: longitude);
    await _ensurePrefs();
    await _prefs!.setDouble(_keyLatitude, latitude);
    await _prefs!.setDouble(_keyLongitude, longitude);
  }

  Future<void> setShowSunTimes(bool value) async {
    state = state.copyWith(showSunTimes: value);
    await _ensurePrefs();
    await _prefs!.setBool(_keyShowSunTimes, value);
  }

  Future<void> setTimezoneOffsetHours(double? value) async {
    if (value == null) {
      state = state.copyWith(clearTimezoneOffset: true);
      await _ensurePrefs();
      await _prefs!.remove(_keyTimezoneOffsetHours);
    } else {
      state = state.copyWith(timezoneOffsetHours: value);
      await _ensurePrefs();
      await _prefs!.setDouble(_keyTimezoneOffsetHours, value);
    }
  }

  // Watermark settings setters

  Future<void> setWatermarkShowWeekNumber(bool value) async {
    state = state.copyWith(watermarkShowWeekNumber: value);
    await _ensurePrefs();
    await _prefs!.setBool(_keyWatermarkShowWeekNumber, value);
  }

  Future<void> setWatermarkShowDayOfYear(bool value) async {
    state = state.copyWith(watermarkShowDayOfYear: value);
    await _ensurePrefs();
    await _prefs!.setBool(_keyWatermarkShowDayOfYear, value);
  }

  Future<void> setWatermarkShowHolidays(bool value) async {
    state = state.copyWith(watermarkShowHolidays: value);
    await _ensurePrefs();
    await _prefs!.setBool(_keyWatermarkShowHolidays, value);
  }

  Future<void> setWatermarkShowMoonPhase(bool value) async {
    state = state.copyWith(watermarkShowMoonPhase: value);
    await _ensurePrefs();
    await _prefs!.setBool(_keyWatermarkShowMoonPhase, value);
  }

  Future<void> setWatermarkShowQuarter(bool value) async {
    state = state.copyWith(watermarkShowQuarter: value);
    await _ensurePrefs();
    await _prefs!.setBool(_keyWatermarkShowQuarter, value);
  }

  Future<void> setWatermarkShowDaysRemaining(bool value) async {
    state = state.copyWith(watermarkShowDaysRemaining: value);
    await _ensurePrefs();
    await _prefs!.setBool(_keyWatermarkShowDaysRemaining, value);
  }

  // Custom NOW line position methods

  /// Sets a custom NOW line position (minutes from midnight).
  Future<void> setCustomNowLineMinutes(int minutes) async {
    state = state.copyWith(customNowLineMinutesFromMidnight: minutes);
    await _ensurePrefs();
    await _prefs!.setInt(_keyCustomNowLineMinutes, minutes);
  }

  /// Clears the custom NOW line position, reverting to real time.
  Future<void> clearCustomNowLine() async {
    state = state.copyWith(clearCustomNowLine: true);
    await _ensurePrefs();
    await _prefs!.remove(_keyCustomNowLineMinutes);
  }

  /// Sets the NOW line viewport position (0.0 to 1.0, where 0.75 is 75% down).
  Future<void> setNowLineViewportPosition(double position) async {
    // Clamp to valid range
    final clampedPosition = position.clamp(0.1, 0.9);
    state = state.copyWith(nowLineViewportPosition: clampedPosition);
    await _ensurePrefs();
    await _prefs!.setDouble(_keyNowLineViewportPosition, clampedPosition);
  }

  // Long-press task creation settings

  /// Sets the default duration for long-press task creation (in minutes).
  Future<void> setLongPressDefaultDuration(int minutes) async {
    state = state.copyWith(longPressDefaultDurationMinutes: minutes);
    await _ensurePrefs();
    await _prefs!.setInt(_keyLongPressDefaultDuration, minutes);
  }

  /// Sets the snap interval for long-press task creation (in minutes).
  /// Valid values: 5, 15, or 30 minutes.
  Future<void> setLongPressSnapInterval(int minutes) async {
    // Clamp to valid options
    final validMinutes = [5, 15, 30].contains(minutes) ? minutes : 15;
    state = state.copyWith(longPressSnapIntervalMinutes: validMinutes);
    await _ensurePrefs();
    await _prefs!.setInt(_keyLongPressSnapInterval, validMinutes);
  }

  /// Marks the long-press hint as seen by the user.
  Future<void> setHasSeenLongPressHint(bool value) async {
    state = state.copyWith(hasSeenLongPressHint: value);
    await _ensurePrefs();
    await _prefs!.setBool(_keyHasSeenLongPressHint, value);
  }
}

/// Global settings provider.
final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(
  SettingsNotifier.new,
);
