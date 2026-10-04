import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';
import 'package:timeflow/presentation/screens/settings/section_header.dart';

/// Appearance settings: theme, density, task direction, 24-hour time.
class SettingsAppearanceSection extends ConsumerWidget {
  const SettingsAppearanceSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const SectionHeader(title: 'Appearance'),
        ListTile(
          leading: const Icon(Icons.palette_outlined),
          title: const Text('Theme'),
          subtitle: Text(_themeLabel(ref.watch(settingsProvider).theme)),
          onTap: () => _showThemeDialog(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.straighten),
          title: const Text('Timeline Density'),
          subtitle:
              Text(_densityLabel(ref.watch(settingsProvider).timelineDensity)),
          onTap: () => _showDensityDialog(context, ref),
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
      ],
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

  void _showThemeDialog(BuildContext context, WidgetRef ref) {
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

  void _showDensityDialog(BuildContext context, WidgetRef ref) {
    final currentDensity = ref.read(settingsProvider).timelineDensity;
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
              groupValue: currentDensity,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setTimelineDensity(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<double>(
              title: const Text('Normal'),
              value: 1.0,
              groupValue: currentDensity,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setTimelineDensity(value!);
                Navigator.pop(context);
              },
            ),
            RadioListTile<double>(
              title: const Text('Spacious'),
              subtitle: const Text('Easier to read'),
              value: 1.3,
              groupValue: currentDensity,
              onChanged: (value) {
                ref.read(settingsProvider.notifier).setTimelineDensity(value!);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }
}
