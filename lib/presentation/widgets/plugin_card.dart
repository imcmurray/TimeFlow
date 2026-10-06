import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/core/plugins/plugin_interface.dart';
import 'package:timeflow/core/plugins/plugin_state_provider.dart';
import 'package:timeflow/presentation/screens/plugin_detail_screen.dart';

/// Card widget for displaying a plugin in the marketplace.
class PluginCard extends ConsumerWidget {
  final TimeFlowPlugin plugin;

  const PluginCard({super.key, required this.plugin});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEnabled = ref.watch(pluginStateProvider)[plugin.id] ?? false;
    final meta = plugin.metadata;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _openDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Icon in colored rounded square
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: (meta.accentColor ?? colorScheme.primary).withValues(
                    alpha: 0.15,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  meta.icon,
                  color: meta.accentColor ?? colorScheme.primary,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),

              // Name, description, tags
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plugin.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      meta.shortDescription,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (isEnabled && meta.configSectionBuilder != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: TextButton.icon(
                          onPressed: () => _openDetail(context),
                          icon: const Icon(Icons.tune, size: 18),
                          label: const Text('Settings'),
                          style: TextButton.styleFrom(
                            padding: EdgeInsets.zero,
                            visualDensity: VisualDensity.compact,
                          ),
                        ),
                      ),
                    if (meta.tags.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 4,
                        children: meta.tags.take(3).map((tag) {
                          return Chip(
                            label: Text(tag),
                            labelStyle: const TextStyle(fontSize: 10),
                            padding: EdgeInsets.zero,
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),

              // Enable/disable switch
              Switch(
                value: isEnabled,
                onChanged: (value) {
                  ref
                      .read(pluginStateProvider.notifier)
                      .setEnabled(plugin.id, value);
                  // A plugin with settings usually needs setting up first
                  // (ServerFlow needs a CSV), so go straight there.
                  if (value && meta.configSectionBuilder != null) {
                    _openDetail(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _openDetail(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => PluginDetailScreen(pluginId: plugin.id),
      ),
    );
  }
}
