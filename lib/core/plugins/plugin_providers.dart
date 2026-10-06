import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/core/plugins/plugin_registry.dart';
import 'package:timeflow/plugins/quote_flow/quote_flow_plugin.dart';
import 'package:timeflow/plugins/server_flow/server_flow_plugin.dart';

/// Every plugin the marketplace offers. Whether each is switched on is
/// [pluginStateProvider]'s business; all are off until the user enables them.
final pluginRegistryProvider = Provider<PluginRegistry>((ref) {
  return PluginRegistry()
    ..register(ServerFlowPlugin())
    ..register(QuoteFlowPlugin());
});
