import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';
import 'package:timeflow/presentation/screens/settings/choice_dialog.dart';
import 'package:timeflow/presentation/screens/settings/section_header.dart';
import 'package:timeflow/services/reminder_sound_service.dart';

/// Notification and reminder settings.
class SettingsNotificationsSection extends ConsumerWidget {
  const SettingsNotificationsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Notifications
        const SectionHeader(title: 'Notifications'),
        SwitchListTile(
          secondary: const Icon(Icons.notifications_outlined),
          title: const Text('Enable Notifications'),
          subtitle: const Text('Get reminders for upcoming tasks'),
          value: ref.watch(settingsProvider).notificationsEnabled,
          onChanged: (value) {
            ref.read(settingsProvider.notifier).setNotificationsEnabled(value);
          },
        ),
        ListTile(
          leading: const Icon(Icons.timer_outlined),
          title: const Text('Default Reminder Time'),
          subtitle: Text(
              '${ref.watch(settingsProvider).defaultReminderMinutes} minutes before'),
          enabled: ref.watch(settingsProvider).notificationsEnabled,
          onTap: ref.watch(settingsProvider).notificationsEnabled
              ? () => _showReminderDialog(context, ref)
              : null,
        ),
        SwitchListTile(
          secondary: const Icon(Icons.open_in_new),
          title: const Text('Bring Window to Front'),
          subtitle: const Text('Raise app window when reminder triggers'),
          value: ref.watch(settingsProvider).bringWindowToFrontOnReminder,
          onChanged: (value) {
            ref
                .read(settingsProvider.notifier)
                .setBringWindowToFrontOnReminder(value);
          },
        ),
        SwitchListTile(
          secondary: const Icon(Icons.volume_up),
          title: const Text('Reminder Sound'),
          subtitle: const Text('Play sound when reminder triggers'),
          value: ref.watch(settingsProvider).reminderSoundEnabled,
          onChanged: (value) {
            ref.read(settingsProvider.notifier).setReminderSoundEnabled(value);
          },
        ),
        ListTile(
          leading: const Icon(Icons.music_note),
          title: const Text('Alert Sound'),
          subtitle: Text(ReminderSoundService.getLabel(
              ref.watch(settingsProvider).reminderSound)),
          enabled: ref.watch(settingsProvider).reminderSoundEnabled,
          onTap: ref.watch(settingsProvider).reminderSoundEnabled
              ? () => _showSoundPicker(context, ref)
              : null,
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
        for (final m in [5, 10, 15, 30, 60])
          ChoiceOption(m, m == 60 ? '1 hour before' : '$m minutes before'),
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
    if (sound != null) ref.read(settingsProvider.notifier).setReminderSound(sound);
  }
}
