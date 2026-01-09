import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/domain/entities/settings.dart';

/// Notifier for managing app settings state.
class SettingsNotifier extends StateNotifier<Settings> {
  SettingsNotifier() : super(const Settings());

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
}

/// Global settings provider.
final settingsProvider = StateNotifierProvider<SettingsNotifier, Settings>((ref) {
  return SettingsNotifier();
});
