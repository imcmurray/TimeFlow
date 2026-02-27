import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cron_timeflow/presentation/providers/settings_provider.dart';
import 'package:cron_timeflow/presentation/screens/settings/section_header.dart';

/// Task creation settings: default duration and snap interval.
class SettingsTaskCreationSection extends ConsumerWidget {
  const SettingsTaskCreationSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const SectionHeader(title: 'Task Creation'),
        ListTile(
          leading: const Icon(Icons.touch_app_outlined),
          title: const Text('Default Duration'),
          subtitle: Text(_formatDurationMinutes(
              ref.watch(settingsProvider).longPressDefaultDurationMinutes)),
          onTap: () => _showDefaultDurationDialog(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.straighten_outlined),
          title: const Text('Snap Interval'),
          subtitle: Text(_formatSnapInterval(
              ref.watch(settingsProvider).longPressSnapIntervalMinutes)),
          onTap: () => _showSnapIntervalDialog(context, ref),
        ),
      ],
    );
  }

  String _formatDurationMinutes(int minutes) {
    if (minutes >= 60) {
      final hours = minutes ~/ 60;
      final mins = minutes % 60;
      if (mins == 0) {
        return '$hours hour${hours > 1 ? 's' : ''}';
      }
      return '$hours hour${hours > 1 ? 's' : ''} $mins min';
    }
    return '$minutes minutes';
  }

  String _formatSnapInterval(int minutes) {
    return '$minutes minute intervals';
  }

  void _showDefaultDurationDialog(BuildContext context, WidgetRef ref) {
    final currentDuration =
        ref.read(settingsProvider).longPressDefaultDurationMinutes;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default Task Duration'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Duration when long-pressing to create a task',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            for (final minutes in [15, 30, 45, 60, 90, 120])
              RadioListTile<int>(
                title: Text(_formatDurationMinutes(minutes)),
                value: minutes,
                groupValue: currentDuration,
                onChanged: (value) {
                  ref
                      .read(settingsProvider.notifier)
                      .setLongPressDefaultDuration(value!);
                  Navigator.pop(context);
                },
              ),
          ],
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

  void _showSnapIntervalDialog(BuildContext context, WidgetRef ref) {
    final currentInterval =
        ref.read(settingsProvider).longPressSnapIntervalMinutes;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Time Snap Interval'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Text(
                'Snap times to nearest interval when creating tasks',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            for (final minutes in [5, 15, 30])
              RadioListTile<int>(
                title: Text('$minutes minutes'),
                subtitle: Text(minutes == 15 ? 'Recommended' : ''),
                value: minutes,
                groupValue: currentInterval,
                onChanged: (value) {
                  ref
                      .read(settingsProvider.notifier)
                      .setLongPressSnapInterval(value!);
                  Navigator.pop(context);
                },
              ),
          ],
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
}
