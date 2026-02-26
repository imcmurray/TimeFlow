import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cron_timeflow/core/plugins/plugin_registry.dart';

/// Provides the [PluginRegistry] to the widget tree.
///
/// Must be overridden in main.dart's ProviderScope — throws if accessed
/// without an override.
final pluginRegistryProvider = Provider<PluginRegistry>((ref) {
  throw UnimplementedError(
    'pluginRegistryProvider must be overridden in ProviderScope',
  );
});
