import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/plugins/server_flow/presentation/providers/server_flow_providers.dart';
import 'package:timeflow/plugins/server_flow/presentation/providers/display_mode_provider.dart';
import 'package:timeflow/plugins/server_flow/presentation/csv_upload_screen.dart';
import 'package:timeflow/plugins/server_flow/presentation/widgets/display_mode_card.dart';

/// Inline configuration section for ServerFlow shown on the plugin detail page.
class ServerFlowConfigSection extends ConsumerWidget {
  const ServerFlowConfigSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(allCronJobsProvider);
    final jobCount = jobsAsync.whenOrNull(data: (jobs) => jobs.length) ?? 0;
    final displayState = ref.watch(displayModeProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CSV Import
        ListTile(
          leading: const Icon(Icons.upload_file),
          title: const Text('CSV Import'),
          subtitle: Text(
            '$jobCount cron job${jobCount == 1 ? '' : 's'} imported',
          ),
          trailing: const Icon(Icons.chevron_right),
          contentPadding: EdgeInsets.zero,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(builder: (context) => const CsvUploadScreen()),
            );
          },
        ),
        if (jobCount > 0)
          ListTile(
            leading: Icon(
              Icons.delete_sweep_outlined,
              color: Theme.of(context).colorScheme.error,
            ),
            title: const Text('Remove imported jobs'),
            contentPadding: EdgeInsets.zero,
            onTap: () async {
              final confirmed = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Remove imported jobs?'),
                  content: Text(
                    'The $jobCount imported job'
                    '${jobCount == 1 ? '' : 's'} disappear from the timeline. '
                    'Your own tasks aren\'t affected.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancel'),
                    ),
                    FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Remove'),
                    ),
                  ],
                ),
              );
              if (confirmed == true) {
                await ref.read(cronJobRepositoryProvider).clear();
              }
            },
          ),
        const Divider(),
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            'Schedule times are in',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        SegmentedButton<bool>(
          segments: const [
            ButtonSegment(value: false, label: Text('This device\'s time')),
            ButtonSegment(value: true, label: Text('UTC')),
          ],
          selected: {ref.watch(cronUtcProvider)},
          onSelectionChanged: (s) =>
              ref.read(cronUtcProvider.notifier).set(s.single),
        ),
        const SizedBox(height: 8),
        const Divider(),

        // Display Mode
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            'Display Mode',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        ...DisplayMode.values.map(
          (mode) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: DisplayModeCard(
              mode: mode,
              isSelected: displayState.mode == mode,
              onTap: () => ref.read(displayModeProvider.notifier).setMode(mode),
            ),
          ),
        ),

        // Cluster window selector (only when timeClusters is active)
        if (displayState.mode == DisplayMode.timeClusters) ...[
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Text(
              'Cluster Window',
              style: Theme.of(context).textTheme.titleSmall,
            ),
          ),
          SegmentedButton<ClusterWindow>(
            segments: ClusterWindow.values
                .map((w) => ButtonSegment(value: w, label: Text(w.label)))
                .toList(),
            selected: {displayState.clusterWindow},
            onSelectionChanged: (selected) => ref
                .read(displayModeProvider.notifier)
                .setClusterWindow(selected.first),
          ),
        ],
      ],
    );
  }
}
