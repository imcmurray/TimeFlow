import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';
import 'package:timeflow/presentation/screens/settings/choice_dialog.dart';
import 'package:timeflow/presentation/screens/settings/section_header.dart';
import 'package:timeflow/services/reminder_coordinator.dart';
import 'package:timeflow/services/reminder_sound_service.dart';

/// Whether reminders can currently be delivered, for the settings screen.
final reminderHealthProvider =
    FutureProvider.autoDispose<({bool? enabled, bool exact})>((ref) async {
      final n = ref.watch(notificationServiceProvider);
      return (
        enabled: await n.areEnabled(),
        exact: await n.canUseExactTiming(),
      );
    });

/// Notification and reminder settings.
class SettingsNotificationsSection extends ConsumerWidget {
  const SettingsNotificationsSection({super.key});

  static bool get _isDesktop =>
      !kIsWeb &&
      const {
        TargetPlatform.linux,
        TargetPlatform.macOS,
        TargetPlatform.windows,
      }.contains(defaultTargetPlatform);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final notifier = ref.read(settingsProvider.notifier);
    final health = ref.watch(reminderHealthProvider).value;
    final enabled = settings.notificationsEnabled;
    final minutes = settings.defaultReminderMinutes;

    return Column(
      children: [
        const SectionHeader(title: 'Reminders'),
        SwitchListTile(
          secondary: const Icon(Icons.notifications_outlined),
          title: const Text('Task reminders'),
          subtitle: const Text('Notify me before tasks start'),
          value: enabled,
          onChanged: (value) async {
            notifier.setNotificationsEnabled(value);
            if (value) {
              await ref.read(reminderCoordinatorProvider).ensurePermission();
              ref.invalidate(reminderHealthProvider);
            }
          },
        ),
        if (enabled && health?.enabled == false)
          ListTile(
            leading: Icon(
              Icons.notifications_off_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            title: const Text('Notifications are turned off for TimeFlow'),
            subtitle: const Text('Tap to allow them'),
            onTap: () async {
              await ref.read(reminderCoordinatorProvider).ensurePermission();
              ref.invalidate(reminderHealthProvider);
            },
          ),
        if (enabled && health != null && !health.exact)
          ListTile(
            leading: const Icon(Icons.alarm_outlined),
            title: const Text('Allow on-time reminders'),
            subtitle: const Text(
              'Without this, Android may deliver reminders a few minutes late',
            ),
            onTap: () async {
              await ref.read(notificationServiceProvider).requestExactTiming();
              ref.invalidate(reminderHealthProvider);
            },
          ),
        ListTile(
          leading: const Icon(Icons.timer_outlined),
          title: const Text('Default reminder'),
          subtitle: Text(
            minutes == 0
                ? 'At start time'
                : minutes == 60
                ? '1 hour before'
                : '$minutes minutes before',
          ),
          enabled: enabled,
          onTap: enabled ? () => _showReminderDialog(context, ref) : null,
        ),
        if (_isDesktop || kIsWeb)
          SwitchListTile(
            secondary: const Icon(Icons.volume_up),
            title: const Text('Reminder sound'),
            subtitle: const Text('Play a chime while TimeFlow is open'),
            value: settings.reminderSoundEnabled,
            onChanged: enabled ? notifier.setReminderSoundEnabled : null,
          ),
        if (_isDesktop || kIsWeb)
          ListTile(
            leading: const Icon(Icons.music_note),
            title: const Text('Sound'),
            subtitle: Text(
              ReminderSoundService.getLabel(settings.reminderSound),
            ),
            enabled: enabled && settings.reminderSoundEnabled,
            onTap: enabled && settings.reminderSoundEnabled
                ? () => _showSoundPicker(context, ref)
                : null,
          ),
        if (_isDesktop)
          SwitchListTile(
            secondary: const Icon(Icons.open_in_new),
            title: const Text('Bring window to front'),
            subtitle: const Text('Raise TimeFlow when a reminder fires'),
            value: settings.bringWindowToFrontOnReminder,
            onChanged: enabled
                ? notifier.setBringWindowToFrontOnReminder
                : null,
          ),
        if (kIsWeb)
          const ListTile(
            leading: Icon(Icons.info_outline),
            title: Text('Browser reminders'),
            subtitle: Text(
              'Browsers can only show reminders while TimeFlow is open in a tab. '
              'Install the Android app for reminders any time.',
            ),
          ),
      ],
    );
  }

  Future<void> _showReminderDialog(BuildContext context, WidgetRef ref) async {
    final minutes = await showChoiceDialog<int>(
      context: context,
      title: 'Default Reminder Time',
      current: ref.read(settingsProvider).defaultReminderMinutes,
      options: [
        for (final m in [0, 5, 10, 15, 30, 60])
          ChoiceOption(
            m,
            m == 0
                ? 'At start time'
                : m == 60
                ? '1 hour before'
                : '$m minutes before',
          ),
      ],
    );
    if (minutes != null) {
      ref.read(settingsProvider.notifier).setDefaultReminderMinutes(minutes);
    }
  }

  Future<void> _showSoundPicker(BuildContext context, WidgetRef ref) async {
    final sound = await showChoiceDialog<String>(
      context: context,
      title: 'Choose Alert Sound',
      current: ref.read(settingsProvider).reminderSound,
      options: [
        for (final sound in ReminderSoundService.availableSounds)
          ChoiceOption(
            sound,
            ReminderSoundService.getLabel(sound),
            trailing: IconButton(
              icon: const Icon(Icons.play_arrow),
              tooltip: 'Preview',
              onPressed: () => ReminderSoundService.play(sound),
            ),
          ),
      ],
    );
    if (sound != null) {
      ref.read(settingsProvider.notifier).setReminderSound(sound);
    }
  }
}
