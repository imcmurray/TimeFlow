import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cron_timeflow/plugins/server_flow/presentation/providers/server_flow_providers.dart';
import 'package:cron_timeflow/plugins/server_flow/presentation/providers/display_mode_provider.dart';
import 'package:cron_timeflow/plugins/server_flow/presentation/csv_upload_screen.dart';

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
          subtitle:
              Text('$jobCount cron job${jobCount == 1 ? '' : 's'} imported'),
          trailing: const Icon(Icons.chevron_right),
          contentPadding: EdgeInsets.zero,
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const CsvUploadScreen(),
              ),
            );
          },
        ),
        const Divider(),

        // Display Mode
        Padding(
          padding: const EdgeInsets.only(top: 8, bottom: 8),
          child: Text(
            'Display Mode',
            style: Theme.of(context).textTheme.titleSmall,
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            ChoiceChip(
              avatar: const Icon(Icons.scatter_plot, size: 18),
              label: const Text('Individual'),
              selected: displayState.mode == DisplayMode.individualDots,
              onSelected: (_) => ref
                  .read(displayModeProvider.notifier)
                  .setMode(DisplayMode.individualDots),
            ),
            ChoiceChip(
              avatar: const Icon(Icons.dns_outlined, size: 18),
              label: const Text('By Host'),
              selected: displayState.mode == DisplayMode.hostSummary,
              onSelected: (_) => ref
                  .read(displayModeProvider.notifier)
                  .setMode(DisplayMode.hostSummary),
            ),
            ChoiceChip(
              avatar: const Icon(Icons.bubble_chart, size: 18),
              label: const Text('Clustered'),
              selected: displayState.mode == DisplayMode.timeClusters,
              onSelected: (_) => ref
                  .read(displayModeProvider.notifier)
                  .setMode(DisplayMode.timeClusters),
            ),
          ],
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
                .map((w) => ButtonSegment(
                      value: w,
                      label: Text(w.label),
                    ))
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
