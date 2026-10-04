import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/domain/sharing/share_codec.dart';
import 'package:timeflow/domain/time/local_date.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';
import 'package:timeflow/presentation/providers/task_provider.dart';
import 'package:timeflow/presentation/screens/timeline_screen.dart';
import 'package:timeflow/presentation/timeline/timeline_tasks.dart';
import 'package:timeflow/presentation/timeline/timeline_view.dart';
import 'package:timeflow/presentation/utils/time_formatter.dart';

/// A schedule someone shared with a link, shown as a live, read-only river.
class SharedScheduleScreen extends ConsumerWidget {
  final SharedSchedule schedule;

  const SharedScheduleScreen({super.key, required this.schedule});

  Future<void> _addToMine(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add to your TimeFlow?'),
        content: Text(
          'The ${schedule.tasks.length} tasks in this schedule are copied to '
          'your own timeline on this device. You can change them afterwards.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Add'),
          ),
        ],
      ),
    );
    if (confirmed != true || !context.mounted) return;
    final service = ref.read(taskServiceProvider);
    for (final task in schedule.tasks) {
      await service.create(task.copyWith(isCompleted: false));
    }
    ref.read(settingsProvider.notifier).setFirstLaunch(false);
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const TimelineScreen()),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = schedule.tasks;
    final first = tasks.isEmpty
        ? LocalDate.today()
        : LocalDate.of(
            tasks
                .map((t) => t.startTime)
                .reduce((a, b) => a.isBefore(b) ? a : b),
          );
    final last = tasks.isEmpty
        ? first
        : LocalDate.of(
            tasks.map((t) => t.endTime).reduce((a, b) => a.isAfter(b) ? a : b),
          );
    final today = LocalDate.today();
    final coversToday = !today.isBefore(first) && !today.isAfter(last);
    final range = first == last
        ? TimeFormatter.formatDateFull(first.startOfDay)
        : '${TimeFormatter.formatDateCompact(first.startOfDay)} – '
              '${TimeFormatter.formatDateCompact(last.startOfDay)}';

    return ProviderScope(
      overrides: [
        timelineReadOnlyProvider.overrideWithValue(true),
        tasksInRangeProvider.overrideWith(
          (ref, r) => Stream.value([
            for (final t in tasks)
              if (t.startTime.isBefore(r.end) && t.endTime.isAfter(r.start)) t,
          ]),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(schedule.title ?? 'Shared schedule'),
              Text(range, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
          actions: [
            TextButton.icon(
              onPressed: tasks.isEmpty ? null : () => _addToMine(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Add to mine'),
            ),
          ],
        ),
        body: Column(
          children: [
            MaterialBanner(
              content: const Text(
                'Someone shared this schedule with you. It lives only in the '
                'link — tap a task for details.',
              ),
              leading: const Icon(Icons.visibility_outlined),
              actions: const [SizedBox.shrink()],
            ),
            Expanded(
              child: TimelineView(
                initialDate: coversToday ? null : first.startOfDay,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
