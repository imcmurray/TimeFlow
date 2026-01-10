import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/domain/entities/settings.dart';

/// Notifier for managing app settings state.
class SettingsNotifier extends Notifier<Settings> {
  @override
  Settings build() => const Settings();

  void setTheme(String theme) {
    state = state.copyWith(theme: theme);
  }

  void setDefaultReminderMinutes(int minutes) {
    state = state.copyWith(defaultReminderMinutes: minutes);
  }

  void setTimelineDensity(double density) {
    state = state.copyWith(timelineDensity: density);
  }

  void setNotificationsEnabled(bool enabled) {
    state = state.copyWith(notificationsEnabled: enabled);
  }

  void setFirstLaunch(bool firstLaunch) {
    state = state.copyWith(firstLaunch: firstLaunch);
  }

  void setUpcomingTasksAboveNow(bool value) {
    state = state.copyWith(upcomingTasksAboveNow: value);
  }

  void setBringWindowToFrontOnReminder(bool value) {
    state = state.copyWith(bringWindowToFrontOnReminder: value);
  }

  void setReminderSoundEnabled(bool value) {
    state = state.copyWith(reminderSoundEnabled: value);
  }

  void setReminderSound(String sound) {
    state = state.copyWith(reminderSound: sound);
  }
}

/// Global settings provider.
final settingsProvider = NotifierProvider<SettingsNotifier, Settings>(
  SettingsNotifier.new,
);
