import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cron_timeflow/core/plugins/plugin_interface.dart';
import 'package:cron_timeflow/core/plugins/widgets/event_detail_popup.dart';
import 'package:cron_timeflow/plugins/weather_flow/data/static_weather_data.dart';
import 'package:cron_timeflow/plugins/weather_flow/presentation/weather_config.dart';
import 'package:cron_timeflow/presentation/providers/task_provider.dart'
    show DateRange;

/// Provider family that generates weather events for a date range.
final _weatherEventsProvider =
    FutureProvider.family<List<TimelineEvent>, DateRange>((ref, range) async {
  final useCelsius = ref.watch(weatherUnitProvider);
  final data = StaticWeatherData(useCelsius: useCelsius);
  return data.generate(range.start, range.end);
});

/// Demo plugin that shows weather data on the timeline.
class WeatherFlowPlugin implements TimeFlowPlugin {
  @override
  String get id => 'weather_flow';

  @override
  String get name => 'WeatherFlow';

  @override
  PluginMetadata get metadata => PluginMetadata(
        shortDescription: 'Demo weather data on the timeline',
        fullDescription:
            'WeatherFlow generates simulated weather events every 3 hours, '
            'showing temperature, conditions, and humidity on the timeline. '
            'Great for demonstrating the plugin system.',
        author: 'TimeFlow',
        version: '1.0.0',
        icon: Icons.wb_sunny,
        accentColor: Colors.amber,
        tags: ['weather', 'environment'],
        configScreenBuilder: (context, ref) => const WeatherConfigWidget(),
      );

  @override
  List<DataSourceDescriptor> get dataSources => [
        const DataSourceDescriptor(
          id: 'static_weather',
          label: 'Simulated Weather',
          description: 'Generated weather data based on time of day',
        ),
      ];

  @override
  List<UIExtensionDescriptor> get uiExtensions => [];

  @override
  TimelineEvent Function(dynamic raw) get eventMapper => (raw) => TimelineEvent(
        id: '',
        pluginId: id,
        title: raw.toString(),
        startTime: DateTime.now(),
      );

  @override
  List<Object> get providerOverrides => [];

  @override
  FutureProvider<List<TimelineEvent>>? eventsProviderFor(DateRange range) {
    return _weatherEventsProvider(range);
  }

  @override
  void Function(BuildContext, TimelineEvent)? get onEventTap =>
      showEventDetailPopup;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}
}
