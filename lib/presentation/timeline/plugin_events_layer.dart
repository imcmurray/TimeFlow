import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/core/plugins/plugin_state_provider.dart';
import 'package:timeflow/core/plugins/widgets/timeline_event_dot.dart';
import 'package:timeflow/presentation/providers/task_provider.dart';
import 'package:timeflow/presentation/timeline/timeline_geometry.dart';
import 'package:timeflow/presentation/timeline/timeline_tasks.dart';

/// Events from enabled plugins (cron jobs, quotes, ...) as dots and bars at
/// the left edge of the task area, for the visible [days].
class PluginEventsLayer extends ConsumerWidget {
  final TimelineGeometry geometry;
  final DayRange days;

  const PluginEventsLayer({
    super.key,
    required this.geometry,
    required this.days,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plugins = ref.watch(enabledPluginsProvider);
    if (plugins.isEmpty) return const SizedBox.shrink();
    final window = taskWindowFor(days);
    final from = days.start;
    final to = days.end;
    final dots = <Widget>[];

    for (final plugin in plugins) {
      final provider = plugin.eventsProviderFor(window);
      if (provider == null) continue;
      final events = ref.watch(provider).value ?? const [];
      for (final event in events) {
        final end = event.endTime ?? event.startTime;
        if (!event.startTime.isBefore(to) || end.isBefore(from)) continue;
        final span = geometry.spanOf(event.startTime, end);
        final bar = span.height >= 2 ? span.height : null;
        dots.add(
          TimelineEventDot(
            event: event,
            top: span.top,
            barHeight: bar,
            onTap: () => plugin.onEventTap?.call(context, event),
          ),
        );
      }
    }
    if (dots.isEmpty) return const SizedBox.shrink();
    return Stack(clipBehavior: Clip.none, children: dots);
  }
}
