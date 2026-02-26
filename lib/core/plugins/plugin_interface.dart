import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cron_timeflow/presentation/providers/task_provider.dart'
    show DateRange;

// Re-export DateRange so plugin implementations can use it.
export 'package:cron_timeflow/presentation/providers/task_provider.dart'
    show DateRange;

/// Marketplace-visible metadata for a plugin.
class PluginMetadata {
  final String shortDescription;
  final String fullDescription;
  final String author;
  final String version;
  final IconData icon;
  final Color? accentColor;
  final List<String> tags;
  final Widget Function(BuildContext, WidgetRef)? configSectionBuilder;

  const PluginMetadata({
    required this.shortDescription,
    required this.fullDescription,
    required this.author,
    required this.version,
    required this.icon,
    this.accentColor,
    this.tags = const [],
    this.configSectionBuilder,
  });
}

/// Describes a data source that a plugin can provide.
class DataSourceDescriptor {
  final String id;
  final String label;
  final String description;

  const DataSourceDescriptor({
    required this.id,
    required this.label,
    required this.description,
  });
}

/// Extension points where plugins can inject UI.
enum UIExtensionPoint {
  timelineLayer,
  appBarAction,
  bottomAction,
  settingsSection,
  navigationRoute,
}

/// Describes a UI extension provided by a plugin.
class UIExtensionDescriptor {
  final String id;
  final UIExtensionPoint extensionPoint;
  final Widget Function(BuildContext context, WidgetRef ref) builder;

  const UIExtensionDescriptor({
    required this.id,
    required this.extensionPoint,
    required this.builder,
  });
}

/// A timeline event produced by a plugin — display-only, separate from
/// upstream [Task] (no reminderMinutes, isCompleted, etc.).
class TimelineEvent {
  final String id;
  final String pluginId;
  final String title;
  final String? subtitle;
  final DateTime startTime;
  final DateTime? endTime;
  final String? groupKey;
  final String? categoryLabel;
  final Map<String, dynamic> metadata;
  final Color? color;

  const TimelineEvent({
    required this.id,
    required this.pluginId,
    required this.title,
    this.subtitle,
    required this.startTime,
    this.endTime,
    this.groupKey,
    this.categoryLabel,
    this.metadata = const {},
    this.color,
  });

  /// Duration of this event, or zero if no end time.
  Duration get duration =>
      endTime != null ? endTime!.difference(startTime) : Duration.zero;

  TimelineEvent copyWith({
    String? id,
    String? pluginId,
    String? title,
    String? subtitle,
    DateTime? startTime,
    DateTime? endTime,
    String? groupKey,
    String? categoryLabel,
    Map<String, dynamic>? metadata,
    Color? color,
  }) {
    return TimelineEvent(
      id: id ?? this.id,
      pluginId: pluginId ?? this.pluginId,
      title: title ?? this.title,
      subtitle: subtitle ?? this.subtitle,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      groupKey: groupKey ?? this.groupKey,
      categoryLabel: categoryLabel ?? this.categoryLabel,
      metadata: metadata ?? this.metadata,
      color: color ?? this.color,
    );
  }
}

/// Contract that all TimeFlow plugins must implement.
abstract class TimeFlowPlugin {
  /// Unique plugin identifier.
  String get id;

  /// Human-readable plugin name.
  String get name;

  /// Marketplace metadata for discovery and display.
  PluginMetadata get metadata;

  /// Data sources this plugin provides.
  List<DataSourceDescriptor> get dataSources;

  /// UI extensions this plugin injects.
  List<UIExtensionDescriptor> get uiExtensions;

  /// Converts raw plugin-specific data into a [TimelineEvent].
  TimelineEvent Function(dynamic raw) get eventMapper;

  /// Riverpod provider overrides to install in the app's ProviderScope.
  ///
  /// Returns objects produced by `.overrideWithValue()` or `.overrideWith()`.
  /// Typed as `List<Object>` because the `Override` sealed class is not
  /// exported from the riverpod package.
  List<Object> get providerOverrides;

  /// Returns a provider for timeline events in the given [range],
  /// or null if this plugin doesn't produce timeline events.
  FutureProvider<List<TimelineEvent>>? eventsProviderFor(DateRange range) {
    return null;
  }

  /// Callback invoked when a user taps a timeline event from this plugin.
  /// Return null if no tap handling is needed.
  void Function(BuildContext, TimelineEvent)? get onEventTap => null;

  /// Called once when the plugin is first loaded.
  Future<void> initialize();

  /// Called when the plugin is being unloaded.
  Future<void> dispose();
}
