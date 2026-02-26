import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cron_timeflow/core/plugins/plugin_interface.dart';

/// A mock [TimeFlowPlugin] for testing the plugin registry.
class MockPlugin implements TimeFlowPlugin {
  @override
  final String id;

  @override
  final String name;

  bool initialized = false;
  bool disposed = false;

  MockPlugin({required this.id, required this.name});

  @override
  PluginMetadata get metadata => PluginMetadata(
        shortDescription: 'Mock plugin for testing',
        fullDescription: 'A mock plugin used in unit tests.',
        author: 'Test',
        version: '0.0.1',
        icon: Icons.extension,
        tags: ['test'],
      );

  @override
  List<DataSourceDescriptor> get dataSources => [];

  @override
  List<UIExtensionDescriptor> get uiExtensions => [];

  @override
  TimelineEvent Function(dynamic raw) get eventMapper => (raw) => TimelineEvent(
        id: 'mock-event',
        pluginId: id,
        title: raw.toString(),
        startTime: DateTime.now(),
      );

  @override
  List<Object> get providerOverrides => [];

  @override
  FutureProvider<List<TimelineEvent>>? eventsProviderFor(DateRange range) {
    return null;
  }

  @override
  void Function(BuildContext, TimelineEvent)? get onEventTap => null;

  @override
  Future<void> initialize() async {
    initialized = true;
  }

  @override
  Future<void> dispose() async {
    disposed = true;
  }
}
