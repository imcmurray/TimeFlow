import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cron_timeflow/core/plugins/plugin_interface.dart';
import 'package:cron_timeflow/core/plugins/plugin_state_provider.dart';
import 'package:cron_timeflow/core/plugins/plugin_providers.dart';
import 'package:cron_timeflow/core/plugins/widgets/timeline_event_dot.dart';
import 'package:cron_timeflow/presentation/utils/timeline_offset.dart';

/// Renders plugin-provided [TimelineEvent]s as dots or bars on the timeline.
///
/// Iterates over all enabled plugins, calls [eventsProviderFor] on each,
/// and renders the combined events using [TimelineEventDot].
class PluginEventsLayer extends ConsumerWidget {
  final double hourHeight;
  final bool upcomingTasksAboveNow;
  final DateTime referenceDate;
  final int daysLoadedBefore;
  final int daysLoadedAfter;
  final DateRange loadedRange;

  const PluginEventsLayer({
    super.key,
    required this.hourHeight,
    required this.upcomingTasksAboveNow,
    required this.referenceDate,
    required this.daysLoadedBefore,
    required this.daysLoadedAfter,
    required this.loadedRange,
  });

  double _getOffsetForDateTime(DateTime time) {
    return TimelineOffset.forDateTime(
      dateTime: time,
      referenceDate: referenceDate,
      hourHeight: hourHeight,
      daysLoadedBefore: daysLoadedBefore,
      daysLoadedAfter: daysLoadedAfter,
      upcomingTasksAboveNow: upcomingTasksAboveNow,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plugins = ref.watch(enabledPluginsProvider);
    final registry = ref.watch(pluginRegistryProvider);
    final dots = <Widget>[];

    for (final plugin in plugins) {
      final provider = plugin.eventsProviderFor(loadedRange);
      if (provider == null) continue;

      final eventsAsync = ref.watch(provider);
      eventsAsync.whenData((events) {
        for (final event in events) {
          final top = _getOffsetForDateTime(event.startTime);
          double? barHeight;

          if (event.endTime != null &&
              event.endTime!.isAfter(event.startTime)) {
            final endTop = _getOffsetForDateTime(event.endTime!);
            barHeight = (top - endTop).abs();
            if (barHeight < 2) barHeight = null;
          }

          final ownerPlugin = registry.getById(event.pluginId) ?? plugin;

          dots.add(
            TimelineEventDot(
              event: event,
              top: barHeight != null
                  ? (upcomingTasksAboveNow ? top - barHeight : top)
                  : top,
              barHeight: barHeight,
              onTap: () => ownerPlugin.onEventTap?.call(context, event),
            ),
          );
        }
      });
    }

    if (dots.isEmpty) return const SizedBox.shrink();
    return Stack(clipBehavior: Clip.none, children: dots);
  }
}
