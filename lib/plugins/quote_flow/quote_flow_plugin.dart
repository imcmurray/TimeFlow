import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/core/plugins/plugin_interface.dart';
import 'package:timeflow/core/plugins/widgets/event_detail_popup.dart';
import 'package:timeflow/plugins/quote_flow/data/quote_data.dart';

/// Provider family that generates quote events for a date range.
final _quoteEventsProvider = FutureProvider.autoDispose
    .family<List<TimelineEvent>, DayRange>((ref, range) async {
      final data = QuoteData();
      return data.generate(range.start, range.end);
    });

/// Demo plugin that shows inspirational quotes on the timeline.
class QuoteFlowPlugin implements TimeFlowPlugin {
  @override
  String get id => 'quote_flow';

  @override
  String get name => 'QuoteFlow';

  @override
  PluginMetadata get metadata => const PluginMetadata(
    shortDescription: 'Inspirational quotes throughout your day',
    fullDescription:
        'QuoteFlow places motivational and inspirational quotes on your '
        'timeline at morning, midday, and evening slots. A gentle '
        'reminder to stay positive and mindful.',
    author: 'TimeFlow',
    version: '1.0.0',
    icon: Icons.format_quote,
    accentColor: Colors.teal,
    tags: ['quotes', 'wellness', 'lifestyle'],
  );

  @override
  List<DataSourceDescriptor> get dataSources => [
    const DataSourceDescriptor(
      id: 'quote_library',
      label: 'Quote Library',
      description: 'Curated collection of inspirational quotes',
    ),
  ];

  @override
  List<UIExtensionDescriptor> get uiExtensions => [];

  @override
  TimelineEvent Function(dynamic raw) get eventMapper =>
      (raw) => TimelineEvent(
        id: '',
        pluginId: id,
        title: raw.toString(),
        startTime: DateTime.now(),
      );

  @override
  List<Object> get providerOverrides => [];

  @override
  FutureProvider<List<TimelineEvent>>? eventsProviderFor(DayRange range) {
    return _quoteEventsProvider(range);
  }

  @override
  void Function(BuildContext, TimelineEvent)? get onEventTap =>
      showEventDetailPopup;

  @override
  Future<void> initialize() async {}

  @override
  Future<void> dispose() async {}
}
