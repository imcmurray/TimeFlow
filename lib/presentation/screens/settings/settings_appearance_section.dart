import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';
import 'package:timeflow/presentation/screens/settings/choice_dialog.dart';
import 'package:timeflow/presentation/screens/settings/section_header.dart';

/// Appearance settings: theme, timeline direction, clock format.
class SettingsAppearanceSection extends ConsumerWidget {
  const SettingsAppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    return Column(
      children: [
        const SectionHeader(title: 'Appearance'),
        ListTile(
          leading: const Icon(Icons.palette_outlined),
          title: const Text('Theme'),
          subtitle: Text(_themeLabel(settings.theme)),
          onTap: () => _showThemeDialog(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.access_time),
          title: const Text('Clock format'),
          subtitle: Text(_clockLabel(settings.use24HourPreference)),
          onTap: () => _showClockDialog(context, ref),
        ),
        SwitchListTile(
          secondary: const Icon(Icons.swap_vert),
          title: const Text('Upcoming tasks above NOW'),
          subtitle: const Text('Future tasks flow down toward the NOW line'),
          value: settings.upcomingTasksAboveNow,
          onChanged: ref
              .read(settingsProvider.notifier)
              .setUpcomingTasksAboveNow,
        ),
      ],
    );
  }

  String _themeLabel(String theme) => switch (theme) {
    'light' => 'Light',
    'dark' => 'Dark',
    _ => 'System default',
  };

  String _clockLabel(bool? use24Hour) => switch (use24Hour) {
    true => '24-hour (14:30)',
    false => '12-hour (2:30 PM)',
    null => 'System default',
  };

  Future<void> _showThemeDialog(BuildContext context, WidgetRef ref) async {
    final theme = await showChoiceDialog<String>(
      context: context,
      title: 'Choose Theme',
      current: ref.read(settingsProvider).theme,
      options: const [
        ChoiceOption('light', 'Light'),
        ChoiceOption('dark', 'Dark'),
        ChoiceOption('auto', 'System default'),
      ],
    );
    if (theme != null) ref.read(settingsProvider.notifier).setTheme(theme);
  }

  Future<void> _showClockDialog(BuildContext context, WidgetRef ref) async {
    // showChoiceDialog returns null on dismiss, so "system" needs a key.
    final choice = await showChoiceDialog<String>(
      context: context,
      title: 'Clock format',
      current: switch (ref.read(settingsProvider).use24HourPreference) {
        true => '24',
        false => '12',
        null => 'system',
      },
      options: const [
        ChoiceOption('system', 'System default'),
        ChoiceOption('12', '12-hour', subtitle: '2:30 PM'),
        ChoiceOption('24', '24-hour', subtitle: '14:30'),
      ],
    );
    if (choice == null) return;
    ref.read(settingsProvider.notifier).setUse24HourPreference(switch (choice) {
      '24' => true,
      '12' => false,
      _ => null,
    });
  }
}
