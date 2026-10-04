import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';
import 'package:timeflow/presentation/screens/settings/choice_dialog.dart';
import 'package:timeflow/presentation/screens/settings/section_header.dart';

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
          subtitle: Text(
            _formatDurationMinutes(
              ref.watch(settingsProvider).longPressDefaultDurationMinutes,
            ),
          ),
          onTap: () => _showDurationDialog(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.straighten_outlined),
          title: const Text('Snap Interval'),
          subtitle: Text(
            _formatSnapInterval(
              ref.watch(settingsProvider).longPressSnapIntervalMinutes,
            ),
          ),
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

  Future<void> _showDurationDialog(BuildContext context, WidgetRef ref) async {
    final minutes = await showChoiceDialog<int>(
      context: context,
      title: 'Default Task Duration',
      description: 'Duration when long-pressing to create a task',
      current: ref.read(settingsProvider).longPressDefaultDurationMinutes,
      options: [
        for (final m in [15, 30, 45, 60, 90, 120])
          ChoiceOption(m, _formatDurationMinutes(m)),
      ],
    );
    if (minutes != null) {
      ref.read(settingsProvider.notifier).setLongPressDefaultDuration(minutes);
    }
  }

  Future<void> _showSnapIntervalDialog(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final minutes = await showChoiceDialog<int>(
      context: context,
      title: 'Time Snap Interval',
      description: 'Snap times to nearest interval when creating tasks',
      current: ref.read(settingsProvider).longPressSnapIntervalMinutes,
      options: [
        for (final m in [5, 15, 30])
          ChoiceOption(
            m,
            '$m minutes',
            subtitle: m == 15 ? 'Recommended' : null,
          ),
      ],
    );
    if (minutes != null) {
      ref.read(settingsProvider.notifier).setLongPressSnapInterval(minutes);
    }
  }
}
