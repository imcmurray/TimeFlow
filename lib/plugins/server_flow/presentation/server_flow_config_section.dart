import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cron_timeflow/plugins/server_flow/presentation/providers/server_flow_providers.dart';
import 'package:cron_timeflow/plugins/server_flow/presentation/csv_upload_screen.dart';

/// Inline configuration section for ServerFlow shown on the plugin detail page.
class ServerFlowConfigSection extends ConsumerWidget {
  const ServerFlowConfigSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final jobsAsync = ref.watch(allCronJobsProvider);
    final jobCount = jobsAsync.whenOrNull(data: (jobs) => jobs.length) ?? 0;

    return ListTile(
      leading: const Icon(Icons.upload_file),
      title: const Text('CSV Import'),
      subtitle: Text('$jobCount cron job${jobCount == 1 ? '' : 's'} imported'),
      trailing: const Icon(Icons.chevron_right),
      contentPadding: EdgeInsets.zero,
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (context) => const CsvUploadScreen(),
          ),
        );
      },
    );
  }
}
