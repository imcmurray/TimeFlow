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

          // Location & Time Section
          _SectionHeader(title: 'Location & Time'),
          SwitchListTile(
            secondary: const Icon(Icons.wb_sunny_outlined),
            title: const Text('Show Sunrise/Sunset'),
            subtitle: const Text('Display sun times on timeline'),
            value: ref.watch(settingsProvider).showSunTimes,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setShowSunTimes(value);
            },
          ),
          ListTile(
            leading: const Icon(Icons.location_on_outlined),
            title: const Text('Location'),
            subtitle: Text(_getLocationLabel(
              ref.watch(settingsProvider).latitude,
              ref.watch(settingsProvider).longitude,
            )),
            enabled: ref.watch(settingsProvider).showSunTimes,
            onTap: ref.watch(settingsProvider).showSunTimes
                ? () => _showLocationDialog()
                : null,
          ),
          ListTile(
            leading: const Icon(Icons.schedule),
            title: const Text('Timezone'),
            subtitle: Text(_getTimezoneLabel(ref.watch(settingsProvider).timezoneOffsetHours)),
            enabled: ref.watch(settingsProvider).showSunTimes,
            onTap: ref.watch(settingsProvider).showSunTimes
                ? () => _showTimezoneDialog()
                : null,
          ),

          const Divider(),

          // Day Watermark Section
          _SectionHeader(title: 'Day Watermark'),
          SwitchListTile(
            secondary: const Icon(Icons.format_list_numbered),
            title: const Text('Week Number'),
            subtitle: const Text('Show W1, W2, etc.'),
            value: ref.watch(settingsProvider).watermarkShowWeekNumber,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setWatermarkShowWeekNumber(value);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.celebration),
            title: const Text('Holidays'),
            subtitle: const Text('Show US federal holidays'),
            value: ref.watch(settingsProvider).watermarkShowHolidays,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setWatermarkShowHolidays(value);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.nightlight_round),
            title: const Text('Moon Phase'),
            subtitle: const Text('Show current moon phase'),
            value: ref.watch(settingsProvider).watermarkShowMoonPhase,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setWatermarkShowMoonPhase(value);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.pie_chart_outline),
            title: const Text('Quarter'),
            subtitle: const Text('Show Q1, Q2, Q3, Q4'),
            value: ref.watch(settingsProvider).watermarkShowQuarter,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setWatermarkShowQuarter(value);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.event),
            title: const Text('Day of Year'),
            subtitle: const Text('Show Day 1 through Day 365'),
            value: ref.watch(settingsProvider).watermarkShowDayOfYear,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setWatermarkShowDayOfYear(value);
            },
          ),
          SwitchListTile(
            secondary: const Icon(Icons.timer_outlined),
            title: const Text('Days Remaining'),
            subtitle: const Text('Show days left in the year'),
            value: ref.watch(settingsProvider).watermarkShowDaysRemaining,
            onChanged: (value) {
              ref.read(settingsProvider.notifier).setWatermarkShowDaysRemaining(value);
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
          // Build info for debugging - shows branch and commit
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.build_outlined,
                      size: 16,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Build Info',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                SelectableText(
                  'Branch: $gitBranch',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  'Commit: $gitCommitHash',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  'Built: $buildTimestamp',
                  style: TextStyle(
                    fontSize: 12,
                    fontFamily: 'monospace',
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
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

  String _getTimezoneLabel(double? offset) {
    if (offset == null) {
      // Auto-detect from device
      final deviceOffset = DateTime.now().timeZoneOffset.inMinutes / 60.0;
      final sign = deviceOffset >= 0 ? '+' : '';
      return 'Auto (UTC$sign${deviceOffset.toStringAsFixed(deviceOffset.truncateToDouble() == deviceOffset ? 0 : 1)})';
    }
    final sign = offset >= 0 ? '+' : '';
    return 'UTC$sign${offset.toStringAsFixed(offset.truncateToDouble() == offset ? 0 : 1)}';
  }

  String _getLocationLabel(double latitude, double longitude) {
    // Try to match to a known location preset
    for (final preset in _locationPresets) {
      if ((preset.latitude - latitude).abs() < 0.5 &&
          (preset.longitude - longitude).abs() < 0.5) {
        return preset.name;
      }
    }
    // Otherwise show coordinates
    final latDir = latitude >= 0 ? 'N' : 'S';
    final lonDir = longitude >= 0 ? 'E' : 'W';
    return '${latitude.abs().toStringAsFixed(1)}°$latDir, ${longitude.abs().toStringAsFixed(1)}°$lonDir';
  }

  /// Location presets for common cities/regions
  static const List<_LocationPreset> _locationPresets = [
    // US West Coast
    _LocationPreset('Seattle, WA', 47.6, -122.3),
    _LocationPreset('Portland, OR', 45.5, -122.7),
    _LocationPreset('San Francisco, CA', 37.8, -122.4),
    _LocationPreset('Los Angeles, CA', 34.0, -118.2),
    _LocationPreset('San Diego, CA', 32.7, -117.2),
    // US Mountain
    _LocationPreset('Denver, CO', 39.7, -105.0),
    _LocationPreset('Salt Lake City, UT', 40.8, -111.9),
    _LocationPreset('Phoenix, AZ', 33.4, -112.1),
    _LocationPreset('Albuquerque, NM', 35.1, -106.6),
    _LocationPreset('Las Vegas, NV', 36.2, -115.1),
    _LocationPreset('Boise, ID', 43.6, -116.2),
    // US Central
    _LocationPreset('Chicago, IL', 41.9, -87.6),
    _LocationPreset('Dallas, TX', 32.8, -96.8),
    _LocationPreset('Houston, TX', 29.8, -95.4),
    _LocationPreset('Minneapolis, MN', 44.9, -93.3),
    _LocationPreset('Kansas City, MO', 39.1, -94.6),
    // US East Coast
    _LocationPreset('New York, NY', 40.7, -74.0),
    _LocationPreset('Boston, MA', 42.4, -71.1),
    _LocationPreset('Philadelphia, PA', 40.0, -75.2),
    _LocationPreset('Washington, DC', 38.9, -77.0),
    _LocationPreset('Miami, FL', 25.8, -80.2),
    _LocationPreset('Atlanta, GA', 33.7, -84.4),
    // International
    _LocationPreset('London, UK', 51.5, -0.1),
    _LocationPreset('Paris, France', 48.9, 2.3),
    _LocationPreset('Berlin, Germany', 52.5, 13.4),
    _LocationPreset('Tokyo, Japan', 35.7, 139.7),
    _LocationPreset('Sydney, Australia', -33.9, 151.2),
    _LocationPreset('Toronto, Canada', 43.7, -79.4),
    _LocationPreset('Vancouver, Canada', 49.3, -123.1),
  ];

  void _showLocationDialog() {
    final currentLat = ref.read(settingsProvider).latitude;
    final currentLon = ref.read(settingsProvider).longitude;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Location'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: _locationPresets.length,
            itemBuilder: (context, index) {
              final preset = _locationPresets[index];
              final isSelected = (preset.latitude - currentLat).abs() < 0.5 &&
                  (preset.longitude - currentLon).abs() < 0.5;
              return ListTile(
                title: Text(preset.name),
                subtitle: Text(
                  '${preset.latitude.abs().toStringAsFixed(1)}°${preset.latitude >= 0 ? 'N' : 'S'}, '
                  '${preset.longitude.abs().toStringAsFixed(1)}°${preset.longitude >= 0 ? 'E' : 'W'}',
                ),
                leading: Radio<bool>(
                  value: true,
                  groupValue: isSelected,
                  onChanged: (_) {
                    ref.read(settingsProvider.notifier).setLocation(
                      preset.latitude,
                      preset.longitude,
                    );
                    Navigator.pop(context);
                  },
                ),
                selected: isSelected,
                onTap: () {
                  ref.read(settingsProvider.notifier).setLocation(
                    preset.latitude,
                    preset.longitude,
                  );
                  Navigator.pop(context);
                },
              );
            },
          ),
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

  void _showTimezoneDialog() {
    final currentOffset = ref.read(settingsProvider).timezoneOffsetHours;

    // Common timezone offsets
    final timezones = <MapEntry<String, double?>>[
      const MapEntry('Auto-detect from device', null),
      const MapEntry('UTC-12 (Baker Island)', -12),
      const MapEntry('UTC-11 (American Samoa)', -11),
      const MapEntry('UTC-10 (Hawaii)', -10),
      const MapEntry('UTC-9 (Alaska)', -9),
      const MapEntry('UTC-8 (Pacific Time)', -8),
      const MapEntry('UTC-7 (Mountain Time)', -7),
      const MapEntry('UTC-6 (Central Time)', -6),
      const MapEntry('UTC-5 (Eastern Time)', -5),
      const MapEntry('UTC-4 (Atlantic Time)', -4),
      const MapEntry('UTC-3 (Argentina)', -3),
      const MapEntry('UTC-2 (Mid-Atlantic)', -2),
      const MapEntry('UTC-1 (Azores)', -1),
      const MapEntry('UTC+0 (London, GMT)', 0),
      const MapEntry('UTC+1 (Paris, Berlin)', 1),
      const MapEntry('UTC+2 (Athens, Cairo)', 2),
      const MapEntry('UTC+3 (Moscow)', 3),
      const MapEntry('UTC+4 (Dubai)', 4),
      const MapEntry('UTC+5 (Pakistan)', 5),
      const MapEntry('UTC+5:30 (India)', 5.5),
      const MapEntry('UTC+6 (Bangladesh)', 6),
      const MapEntry('UTC+7 (Bangkok)', 7),
      const MapEntry('UTC+8 (Singapore, Perth)', 8),
      const MapEntry('UTC+9 (Tokyo)', 9),
      const MapEntry('UTC+9:30 (Adelaide)', 9.5),
      const MapEntry('UTC+10 (Sydney)', 10),
      const MapEntry('UTC+11 (Solomon Islands)', 11),
      const MapEntry('UTC+12 (Auckland)', 12),
      const MapEntry('UTC+13 (Samoa)', 13),
      const MapEntry('UTC+14 (Line Islands)', 14),
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Timezone'),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: ListView.builder(
            itemCount: timezones.length,
            itemBuilder: (context, index) {
              final tz = timezones[index];
              final isSelected = currentOffset == tz.value;
              return ListTile(
                title: Text(tz.key),
                leading: Radio<double?>(
                  value: tz.value,
                  groupValue: currentOffset,
                  onChanged: (value) {
                    ref.read(settingsProvider.notifier).setTimezoneOffsetHours(value);
                    Navigator.pop(context);
                  },
                ),
                selected: isSelected,
                onTap: () {
                  ref.read(settingsProvider.notifier).setTimezoneOffsetHours(tz.value);
                  Navigator.pop(context);
                },
              );
            },
          ),
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

/// A location preset with name and coordinates.
class _LocationPreset {
  final String name;
  final double latitude;
  final double longitude;

  const _LocationPreset(this.name, this.latitude, this.longitude);
}
