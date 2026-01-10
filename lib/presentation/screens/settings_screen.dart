import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';
import 'package:timeflow/services/reminder_sound_service.dart';

/// Settings screen for app preferences and customization.
///
/// Allows users to configure theme, notifications, timeline density,
/// and other preferences.
class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  // TODO: Replace remaining local state with settings provider
  int _defaultReminderMinutes = 10;
  double _timelineDensity = 1.0;
  bool _notificationsEnabled = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: ListView(
        children: [
          // Theme Section
          _SectionHeader(title: 'Appearance'),
          ListTile(
            leading: const Icon(Icons.palette_outlined),
            title: const Text('Theme'),
            subtitle: Text(_themeLabel(ref.watch(settingsProvider).theme)),
            onTap: () => _showThemeDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.straighten),
            title: const Text('Timeline Density'),
            subtitle: Text(_densityLabel(_timelineDensity)),
            onTap: () => _showDensityDialog(),
          ),
          SwitchListTile(
            secondary: const Icon(Icons.swap_vert),
            title: const Text('Upcoming Tasks Above NOW'),
            subtitle: const Text('Future tasks flow down toward the NOW line'),
            value: ref.watch(settingsProvider).upcomingTasksAboveNow,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setUpcomingTasksAboveNow(value);
            },
          ),

          const Divider(),

          // Notifications Section
          _SectionHeader(title: 'Notifications'),
          SwitchListTile(
            secondary: const Icon(Icons.notifications_outlined),
            title: const Text('Enable Notifications'),
            subtitle: const Text('Get reminders for upcoming tasks'),
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() => _notificationsEnabled = value);
              // TODO: Save via settings provider
            },
          ),
          ListTile(
            leading: const Icon(Icons.timer_outlined),
            title: const Text('Default Reminder Time'),
            subtitle: Text('$_defaultReminderMinutes minutes before'),
            enabled: _notificationsEnabled,
            onTap: _notificationsEnabled ? () => _showReminderDialog() : null,
          ),
          SwitchListTile(
            secondary: const Icon(Icons.open_in_new),
            title: const Text('Bring Window to Front'),
            subtitle: const Text('Raise app window when reminder triggers'),
            value: ref.watch(settingsProvider).bringWindowToFrontOnReminder,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setBringWindowToFrontOnReminder(value);
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
                ? () => _showSoundPicker(ref)
                : null,
          ),

          const Divider(),

          // About Section
          _SectionHeader(title: 'About'),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('TimeFlow'),
            subtitle: const Text('Version 1.0.0'),
            onTap: () => _showAboutDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Privacy Policy'),
            onTap: () {
              // TODO: Open privacy policy
            },
          ),
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('Terms of Service'),
            onTap: () {
              // TODO: Open terms of service
            },
          ),
        ],
      ),
    );
  }

  String _themeLabel(String theme) {
    switch (theme) {
      case 'light':
        return 'Light';
      case 'dark':
        return 'Dark';
      case 'auto':
      default:
        return 'System default';
    }
  }

  String _densityLabel(double density) {
    if (density < 0.8) return 'Compact';
    if (density > 1.2) return 'Spacious';
    return 'Normal';
  }

  void _showThemeDialog() {
    final currentTheme = ref.read(settingsProvider).theme;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('Light'),
              value: 'light',
              groupValue: currentTheme,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setTheme(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('Dark'),
              value: 'dark',
              groupValue: currentTheme,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setTheme(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<String>(
              title: const Text('System default'),
              value: 'auto',
              groupValue: currentTheme,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setTheme(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDensityDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Timeline Density'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<double>(
              title: const Text('Compact'),
              subtitle: const Text('More hours visible'),
              value: 0.7,
              groupValue: _timelineDensity,
              onChanged: (value) {
                setState(() => _timelineDensity = value!);
                Navigator.pop(context);
                // TODO: Save via settings provider
              },
            ),
            RadioListTile<double>(
              title: const Text('Normal'),
              value: 1.0,
              groupValue: _timelineDensity,
              onChanged: (value) {
                setState(() => _timelineDensity = value!);
                Navigator.pop(context);
                // TODO: Save via settings provider
              },
            ),
            RadioListTile<double>(
              title: const Text('Spacious'),
              subtitle: const Text('Easier to read'),
              value: 1.3,
              groupValue: _timelineDensity,
              onChanged: (value) {
                setState(() => _timelineDensity = value!);
                Navigator.pop(context);
                // TODO: Save via settings provider
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showReminderDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default Reminder Time'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final minutes in [5, 10, 15, 30, 60])
              RadioListTile<int>(
                title: Text(minutes == 60
                    ? '1 hour before'
                    : '$minutes minutes before'),
                value: minutes,
                groupValue: _defaultReminderMinutes,
                onChanged: (value) {
                  setState(() => _defaultReminderMinutes = value!);
                  Navigator.pop(context);
                  // TODO: Save via settings provider
                },
              ),
          ],
        ),
      ),
    );
  }

  void _showSoundPicker(WidgetRef ref) {
    final currentSound = ref.read(settingsProvider).reminderSound;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Alert Sound'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: ReminderSoundService.availableSounds.map((sound) {
            return ListTile(
              title: Text(ReminderSoundService.getLabel(sound)),
              leading: Radio<String>(
                value: sound,
                groupValue: currentSound,
                onChanged: (value) {
                  ref.read(settingsProvider.notifier).setReminderSound(value!);
                  Navigator.pop(context);
                },
              ),
              trailing: IconButton(
                icon: const Icon(Icons.play_arrow),
                onPressed: () => ReminderSoundService.play(sound),
              ),
              onTap: () {
                ref.read(settingsProvider.notifier).setReminderSound(sound);
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showAboutDialog(
      context: context,
      applicationName: 'TimeFlow',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primaryContainer,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Icon(
          Icons.water_drop,
          size: 32,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      children: [
        const SizedBox(height: 16),
        const Text(
          'Experience time as a gentle flowing river, not a pressure cooker.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'TimeFlow transforms daily scheduling into a calming visual experience '
          'where your day flows naturally past the NOW line.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
              color: Theme.of(context).colorScheme.primary,
            ),
      ),
    );
  }
}
