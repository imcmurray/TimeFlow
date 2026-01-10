import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeflow/domain/entities/settings.dart';

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

  SharedPreferences? _prefs;

  @override
  Settings build() {
    _loadSettings();
    return const Settings();
  }

  Future<void> _loadSettings() async {
    _prefs = await SharedPreferences.getInstance();
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
}

/// Global settings provider.
final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(
  SettingsNotifier.new,
);
