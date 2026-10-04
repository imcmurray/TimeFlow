import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cron_timeflow/core/plugins/plugin_interface.dart';
import 'package:cron_timeflow/core/plugins/plugin_state_provider.dart';

/// State for the timeline share screen.
@immutable
class TimelineShareState {
  final DateTime startDate;
  final DateTime endDate;
  final int startHour;
  final int endHour;
  final Set<String> selectedPluginIds;
  final bool hideDetails;

  const TimelineShareState({
    required this.startDate,
    required this.endDate,
    this.startHour = 0,
    this.endHour = 24,
    this.selectedPluginIds = const {},
    this.hideDetails = false,
  });

  TimelineShareState copyWith({
    DateTime? startDate,
    DateTime? endDate,
    int? startHour,
    int? endHour,
    Set<String>? selectedPluginIds,
    bool? hideDetails,
  }) {
    return TimelineShareState(
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      startHour: startHour ?? this.startHour,
      endHour: endHour ?? this.endHour,
      selectedPluginIds: selectedPluginIds ?? this.selectedPluginIds,
      hideDetails: hideDetails ?? this.hideDetails,
    );
  }
}

/// Manages the timeline share screen state.
class TimelineShareNotifier extends Notifier<TimelineShareState> {
  @override
  TimelineShareState build() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final enabledPlugins = ref.read(enabledPluginsProvider);

    return TimelineShareState(
      startDate: today,
      endDate: today,
      selectedPluginIds: enabledPlugins.map((p) => p.id).toSet(),
    );
  }

  void setDateRange(DateTime start, DateTime end) {
    state = state.copyWith(startDate: start, endDate: end);
  }

  void setTimeRange(int startHour, int endHour) {
    state = state.copyWith(startHour: startHour, endHour: endHour);
  }

  void togglePlugin(String pluginId) {
    final current = Set<String>.from(state.selectedPluginIds);
    if (current.contains(pluginId)) {
      current.remove(pluginId);
    } else {
      current.add(pluginId);
    }
    state = state.copyWith(selectedPluginIds: current);
  }

  void setHideDetails(bool value) {
    state = state.copyWith(hideDetails: value);
  }
}

/// Provides the [TimelineShareState].
final timelineShareProvider =
    NotifierProvider<TimelineShareNotifier, TimelineShareState>(
  TimelineShareNotifier.new,
);

/// Aggregates timeline events from all selected plugins within the
/// configured date and time range.
final sharedTimelineEventsProvider =
    FutureProvider.autoDispose<List<TimelineEvent>>((ref) async {
  final shareState = ref.watch(timelineShareProvider);
  final enabledPlugins = ref.watch(enabledPluginsProvider);

  final dateRange = DateRange(
    shareState.startDate,
    // End date is inclusive — extend to end of day
    DateTime(
      shareState.endDate.year,
      shareState.endDate.month,
      shareState.endDate.day,
      23,
      59,
      59,
    ),
  );

  final allEvents = <TimelineEvent>[];

  for (final plugin in enabledPlugins) {
    if (!shareState.selectedPluginIds.contains(plugin.id)) continue;

    final eventsProvider = plugin.eventsProviderFor(dateRange);
    if (eventsProvider == null) continue;

    final eventsAsync = await ref.watch(eventsProvider.future);
    allEvents.addAll(eventsAsync);
  }

  // Filter by time-of-day range
  final filtered = allEvents.where((event) {
    final hour = event.startTime.hour;
    return hour >= shareState.startHour && hour < shareState.endHour;
  }).toList();

  // Sort by start time
  filtered.sort((a, b) => a.startTime.compareTo(b.startTime));

  return filtered;
});
