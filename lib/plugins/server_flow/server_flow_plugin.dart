import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cron_timeflow/core/plugins/plugin_interface.dart';
import 'package:cron_timeflow/core/plugins/widgets/event_detail_popup.dart';
import 'package:cron_timeflow/plugins/server_flow/presentation/providers/filter_provider.dart';
import 'package:cron_timeflow/plugins/server_flow/presentation/providers/server_flow_providers.dart';
import 'package:cron_timeflow/plugins/server_flow/presentation/server_flow_config_section.dart';
import 'package:cron_timeflow/plugins/server_flow/presentation/widgets/filter_modal.dart';
import 'package:cron_timeflow/presentation/providers/task_provider.dart'
    show DateRange;

/// The ServerFlow plugin for visualizing cron jobs and scheduled tasks.
///
/// Adds CSV upload, cron expansion, timeline dots, grouping/coloring,
/// and an impact filter to the TimeFlow app.
class ServerFlowPlugin implements TimeFlowPlugin {
  @override
  String get id => 'server_flow';

  @override
  String get name => 'ServerFlow';

  @override
  PluginMetadata get metadata => PluginMetadata(
        shortDescription:
            'Visualize cron jobs and scheduled tasks from CSV uploads',
        fullDescription:
            'ServerFlow lets you import CSV files containing cron jobs and '
            'scheduled tasks, then visualizes them on the timeline with '
            'grouping, coloring, and filtering by host, category, or user.',
        author: 'TimeFlow',
        version: '1.0.0',
        icon: Icons.dns_outlined,
        accentColor: Colors.blue,
        tags: ['servers', 'cron', 'csv', 'devops'],
        configSectionBuilder: (context, ref) => const ServerFlowConfigSection(),
      );

  @override
  List<DataSourceDescriptor> get dataSources => [
        const DataSourceDescriptor(
          id: 'csv_import',
          label: 'CSV Import',
          description: 'Import cron jobs and scheduled tasks from CSV files',
        ),
      ];

  @override
  List<UIExtensionDescriptor> get uiExtensions => [
        UIExtensionDescriptor(
          id: 'server_flow_filter',
          extensionPoint: UIExtensionPoint.appBarAction,
          builder: (context, ref) {
            final hasJobs =
                ref.watch(allCronJobsProvider).value?.isNotEmpty ?? false;
            if (!hasJobs) return const SizedBox.shrink();
            return IconButton(
              icon: Badge(
                isLabelVisible: ref.watch(serverFlowFilterProvider).isActive,
                child: const Icon(Icons.filter_list),
              ),
              onPressed: () => showFilterModal(context),
              tooltip: 'Filter events',
            );
          },
        ),
      ];

  @override
  TimelineEvent Function(dynamic raw) get eventMapper => (raw) {
        if (raw is Map<String, dynamic>) {
          return TimelineEvent(
            id: raw['id'] as String? ?? '',
            pluginId: id,
            title: raw['command'] as String? ?? '',
            subtitle: raw['host'] as String?,
            startTime: DateTime.tryParse(raw['start_time'] as String? ?? '') ??
                DateTime.now(),
            endTime: raw['end_time'] != null
                ? DateTime.tryParse(raw['end_time'] as String)
                : null,
            groupKey: raw['host'] as String?,
            categoryLabel: raw['category'] as String?,
            metadata: raw,
          );
        }
        return TimelineEvent(
          id: '',
          pluginId: id,
          title: raw.toString(),
          startTime: DateTime.now(),
        );
      };

  @override
  List<Object> get providerOverrides => [];

  @override
  FutureProvider<List<TimelineEvent>>? eventsProviderFor(DateRange range) {
    return serverFlowEventsForRangeProvider(range);
  }

  @override
  void Function(BuildContext, TimelineEvent)? get onEventTap =>
      showEventDetailPopup;

  @override
  Future<void> initialize() async {
    // Plugin initialization — data layer setup happens lazily via providers
  }

  @override
  Future<void> dispose() async {
    // Cleanup resources
  }
}
