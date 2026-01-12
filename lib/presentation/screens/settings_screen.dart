import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeflow/build_info.dart';
import 'package:timeflow/presentation/helpers/file_export.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';
import 'package:timeflow/presentation/providers/task_provider.dart';
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
          SwitchListTile(
            secondary: const Icon(Icons.access_time),
            title: const Text('24-Hour Time'),
            subtitle: const Text('Display time as 14:30 instead of 2:30 PM'),
            value: ref.watch(settingsProvider).use24HourFormat,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setUse24HourFormat(value);
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

          // Data Section
          _SectionHeader(title: 'Data'),
          ListTile(
            leading: const Icon(Icons.upload_file),
            title: const Text('Export Tasks'),
            subtitle: const Text('Save tasks to a JSON file'),
            onTap: () => _exportTasks(),
          ),
          ListTile(
            leading: const Icon(Icons.download),
            title: const Text('Import Tasks'),
            subtitle: const Text('Load tasks from a JSON file'),
            onTap: () => _importTasks(),
          ),
          ListTile(
            leading: const Icon(Icons.delete_forever, color: Colors.red),
            title: const Text('Delete All Tasks'),
            subtitle: const Text('Permanently remove all tasks'),
            onTap: () => _showDeleteAllTasksDialog(),
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
            leading: const Icon(Icons.help_outline),
            title: const Text('Support'),
            subtitle: const Text('Get help & report issues'),
            onTap: () => _showSupportDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Privacy Policy'),
            onTap: () => _showPrivacyPolicyDialog(),
          ),
          ListTile(
            leading: const Icon(Icons.article_outlined),
            title: const Text('Terms of Service'),
            onTap: () => _showTermsOfServiceDialog(),
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

  Future<void> _showDeleteAllTasksDialog() async {
    final taskCount = await ref.read(taskRepositoryProvider).count();
    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete All Tasks?'),
        content: Text(
          'This will permanently delete all $taskCount task(s). '
          'This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete All'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(taskRepositoryProvider).clear();
      ref.read(taskNotifierProvider.notifier).notifyTasksChanged();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All tasks deleted'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _exportTasks() async {
    final jsonString = await ref.read(taskRepositoryProvider).exportToJson();
    final fileName =
        'timeflow_backup_${DateTime.now().toIso8601String().split('T')[0]}.json';

    final result = await exportJsonFile(jsonString, fileName);

    if (!mounted) return;

    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.filePath != null
              ? 'Exported to ${result.filePath}'
              : 'Export complete'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Export failed: ${result.error}'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _importTasks() async {
    final fileResult = await pickAndReadJsonFile();

    if (!fileResult.success || fileResult.content == null) {
      if (fileResult.error != 'No file selected' && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to read file: ${fileResult.error}'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    if (!mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Import Tasks?'),
        content: const Text(
          'This will add all tasks from the backup file. '
          'Existing tasks with the same ID will be updated.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Import'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    try {
      final count = await ref
          .read(taskRepositoryProvider)
          .importFromJson(fileResult.content!);
      ref.read(taskNotifierProvider.notifier).notifyTasksChanged();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Imported $count task(s)'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Import failed: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
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
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          'assets/images/timeflow-logo.png',
          width: 64,
          height: 64,
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

  Future<void> _showSupportDialog() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: ${packageInfo.version}'),
            Text('Build: #$gitCommitCount ($gitCommitHash)'),
            const SizedBox(height: 16),
            const Text('Need help or found a bug?'),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => launchUrl(
                Uri.parse('https://github.com/imcmurray/TimeFlow/issues'),
              ),
              child: Text(
                'View or create issues on GitHub',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showPrivacyPolicyDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Last updated: January 2026\n'),
              const Text(
                'TimeFlow Privacy Policy\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'TimeFlow is designed with your privacy in mind. '
                'Here\'s what you need to know:\n',
              ),
              const Text(
                'Data Storage',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                '• All your tasks and settings are stored locally on your device\n'
                '• We do not collect, transmit, or store any personal data on external servers\n'
                '• Your data remains entirely under your control\n',
              ),
              const Text(
                'Permissions',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                '• Notifications: Used only to remind you of upcoming tasks\n'
                '• No other permissions are required\n',
              ),
              const Text(
                'Third Parties',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                '• TimeFlow does not share any data with third parties\n'
                '• No analytics or tracking services are used\n',
              ),
              const Text(
                'Contact',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('For privacy questions, visit our '),
              Builder(
                builder: (context) => InkWell(
                  onTap: () => launchUrl(
                    Uri.parse('https://github.com/imcmurray/TimeFlow'),
                  ),
                  child: Text(
                    'GitHub repository',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showTermsOfServiceDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Last updated: January 2026\n'),
              const Text(
                'Terms of Service\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('By using TimeFlow, you agree to these terms:\n'),
              const Text(
                'Use of Service',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                '• TimeFlow is provided "as is" without warranties\n'
                '• You are responsible for your own task data\n'
                '• The app is free to use for personal purposes\n',
              ),
              const Text(
                'Limitations',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                '• We are not liable for any data loss\n'
                '• We reserve the right to update the app and these terms\n',
              ),
              const Text(
                'Open Source',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('• TimeFlow is open source software'),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• Contributions are welcome via '),
                  Builder(
                    builder: (context) => InkWell(
                      onTap: () => launchUrl(
                        Uri.parse('https://github.com/imcmurray/TimeFlow'),
                      ),
                      child: Text(
                        'GitHub',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
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
