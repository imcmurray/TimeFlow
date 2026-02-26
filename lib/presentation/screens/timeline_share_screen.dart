import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cron_timeflow/core/plugins/plugin_interface.dart';
import 'package:cron_timeflow/core/plugins/plugin_providers.dart';
import 'package:cron_timeflow/core/plugins/plugin_state_provider.dart';
import 'package:cron_timeflow/presentation/helpers/image_share.dart';
import 'package:cron_timeflow/presentation/providers/timeline_share_provider.dart';

/// Screen for sharing timeline data from all enabled plugins.
///
/// Supports date/time range filtering, per-plugin toggling, privacy mode,
/// and sharing as text, image, or clipboard.
class TimelineShareScreen extends ConsumerStatefulWidget {
  /// Optional plugin ID to pre-select only that plugin.
  final String? initialPluginId;

  const TimelineShareScreen({super.key, this.initialPluginId});

  @override
  ConsumerState<TimelineShareScreen> createState() =>
      _TimelineShareScreenState();
}

class _TimelineShareScreenState extends ConsumerState<TimelineShareScreen> {
  final GlobalKey _previewKey = GlobalKey();
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    // Defer initial plugin selection to first build so providers are ready.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_initialized && widget.initialPluginId != null) {
        _initialized = true;
        final notifier = ref.read(timelineShareProvider.notifier);
        // Deselect all, then select only the initial plugin
        final enabledPlugins = ref.read(enabledPluginsProvider);
        for (final plugin in enabledPlugins) {
          if (plugin.id != widget.initialPluginId) {
            final selected = ref.read(timelineShareProvider).selectedPluginIds;
            if (selected.contains(plugin.id)) {
              notifier.togglePlugin(plugin.id);
            }
          }
        }
      }
    });
  }

  String _formatDate(DateTime date) {
    const weekdays = [
      'Monday',
      'Tuesday',
      'Wednesday',
      'Thursday',
      'Friday',
      'Saturday',
      'Sunday',
    ];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${weekdays[date.weekday - 1]}, ${months[date.month - 1]} ${date.day}';
  }

  String _formatHour(int hour) {
    if (hour == 0 || hour == 24) return '12:00 AM';
    if (hour == 12) return '12:00 PM';
    if (hour < 12) return '$hour:00 AM';
    return '${hour - 12}:00 PM';
  }

  String _formatEventTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:'
        '${time.minute.toString().padLeft(2, '0')}';
  }

  String _generateShareText(
    TimelineShareState shareState,
    List<TimelineEvent> events,
    List<TimeFlowPlugin> enabledPlugins,
  ) {
    final buffer = StringBuffer();

    final isSameDay = shareState.startDate.year == shareState.endDate.year &&
        shareState.startDate.month == shareState.endDate.month &&
        shareState.startDate.day == shareState.endDate.day;

    if (isSameDay) {
      buffer.writeln('Timeline for ${_formatDate(shareState.startDate)}');
    } else {
      buffer.writeln(
        'Timeline for ${_formatDate(shareState.startDate)} – '
        '${_formatDate(shareState.endDate)}',
      );
    }
    buffer.writeln(
      '${_formatHour(shareState.startHour)} – '
      '${_formatHour(shareState.endHour)}',
    );
    buffer.writeln();

    // Group events by plugin
    final selectedPlugins = enabledPlugins.where(
      (p) => shareState.selectedPluginIds.contains(p.id),
    );

    for (final plugin in selectedPlugins) {
      final pluginEvents =
          events.where((e) => e.pluginId == plugin.id).toList();
      if (pluginEvents.isEmpty) continue;

      buffer.writeln('── ${plugin.name} ──');
      for (final event in pluginEvents) {
        final time = _formatEventTime(event.startTime);
        if (shareState.hideDetails) {
          buffer.writeln('$time: ${event.title}');
        } else {
          final subtitle = event.subtitle != null ? ' (${event.subtitle})' : '';
          buffer.writeln('$time: ${event.title}$subtitle');
        }
      }
      buffer.writeln();
    }

    return buffer.toString().trimRight();
  }

  Future<Uint8List?> _capturePreview() async {
    final boundary = _previewKey.currentContext?.findRenderObject()
        as RenderRepaintBoundary?;
    if (boundary == null) return null;

    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> _shareAsText(String text) async {
    // Use Clipboard as a fallback-safe text sharing mechanism
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Timeline text copied — paste to share'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _shareAsImage(String subject) async {
    final imageBytes = await _capturePreview();
    if (imageBytes == null) return;

    final shareState = ref.read(timelineShareProvider);
    final fileName =
        'timeline_${shareState.startDate.toIso8601String().split('T')[0]}.png';

    await shareImageBytes(imageBytes, fileName, subject, context);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Timeline image shared'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _copyToClipboard(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Timeline copied to clipboard'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final shareState = ref.watch(timelineShareProvider);
    final eventsAsync = ref.watch(sharedTimelineEventsProvider);
    final registry = ref.watch(pluginRegistryProvider);
    final enabledPlugins = ref.watch(enabledPluginsProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Timeline'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Date Range
            Card(
              child: InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: () async {
                  final picked = await showDateRangePicker(
                    context: context,
                    firstDate:
                        DateTime.now().subtract(const Duration(days: 365)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                    initialDateRange: DateTimeRange(
                      start: shareState.startDate,
                      end: shareState.endDate,
                    ),
                  );
                  if (picked != null) {
                    ref.read(timelineShareProvider.notifier).setDateRange(
                          picked.start,
                          picked.end,
                        );
                  }
                },
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(
                        Icons.calendar_today,
                        color: colorScheme.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Date Range',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _isSameDay(
                                      shareState.startDate, shareState.endDate)
                                  ? _formatDate(shareState.startDate)
                                  : '${_formatDate(shareState.startDate)} – '
                                      '${_formatDate(shareState.endDate)}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodyMedium
                                  ?.copyWith(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.chevron_right,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Time Range
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Time Range',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: shareState.startHour,
                            decoration: const InputDecoration(
                              labelText: 'From',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: List.generate(24, (i) => i).map((hour) {
                              return DropdownMenuItem(
                                value: hour,
                                child: Text(_formatHour(hour)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                final endHour = shareState.endHour <= value
                                    ? (value + 1).clamp(1, 24)
                                    : shareState.endHour;
                                ref
                                    .read(timelineShareProvider.notifier)
                                    .setTimeRange(value, endHour);
                              }
                            },
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 12),
                          child: Text('to'),
                        ),
                        Expanded(
                          child: DropdownButtonFormField<int>(
                            value: shareState.endHour,
                            decoration: const InputDecoration(
                              labelText: 'To',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            items: List.generate(24, (i) => i + 1).map((hour) {
                              return DropdownMenuItem(
                                value: hour,
                                child: Text(
                                  hour == 24 ? '12:00 AM' : _formatHour(hour),
                                ),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null &&
                                  value > shareState.startHour) {
                                ref
                                    .read(timelineShareProvider.notifier)
                                    .setTimeRange(shareState.startHour, value);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Plugin Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        'Include Plugins',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    ...enabledPlugins.map((plugin) {
                      final meta = plugin.metadata;
                      final accentColor =
                          meta.accentColor ?? colorScheme.primary;
                      return CheckboxListTile(
                        value: shareState.selectedPluginIds.contains(plugin.id),
                        onChanged: (_) => ref
                            .read(timelineShareProvider.notifier)
                            .togglePlugin(plugin.id),
                        secondary: Icon(
                          meta.icon,
                          color: accentColor,
                        ),
                        title: Text(plugin.name),
                      );
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Privacy Toggle
            Card(
              child: SwitchListTile(
                title: const Text('Hide event details'),
                subtitle: const Text('Only share event titles and times'),
                value: shareState.hideDetails,
                onChanged: (value) => ref
                    .read(timelineShareProvider.notifier)
                    .setHideDetails(value),
              ),
            ),
            const SizedBox(height: 16),

            // Preview
            Text(
              'Preview',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),

            RepaintBoundary(
              key: _previewKey,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: colorScheme.surface,
                  border: Border.all(color: colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: eventsAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (err, _) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(
                      child: Text('Error loading events: $err'),
                    ),
                  ),
                  data: (events) => _buildPreviewContent(
                    shareState,
                    events,
                    enabledPlugins,
                    registry,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Share Buttons
            eventsAsync.when(
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
              data: (events) {
                final text = _generateShareText(
                  shareState,
                  events,
                  enabledPlugins,
                );
                final subject =
                    'Timeline for ${_formatDate(shareState.startDate)}';
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _shareAsText(text),
                            icon: const Icon(Icons.text_fields),
                            label: const Text('Share Text'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () => _shareAsImage(subject),
                            icon: const Icon(Icons.image_outlined),
                            label: const Text('Share Image'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _copyToClipboard(text),
                      icon: const Icon(Icons.copy),
                      label: const Text('Copy to Clipboard'),
                    ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewContent(
    TimelineShareState shareState,
    List<TimelineEvent> events,
    List<TimeFlowPlugin> enabledPlugins,
    dynamic registry,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    final isSameDay = _isSameDay(shareState.startDate, shareState.endDate);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          isSameDay
              ? _formatDate(shareState.startDate)
              : '${_formatDate(shareState.startDate)} – '
                  '${_formatDate(shareState.endDate)}',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        Text(
          '${_formatHour(shareState.startHour)} – '
          '${_formatHour(shareState.endHour)}',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: colorScheme.onSurfaceVariant,
              ),
        ),
        const SizedBox(height: 16),
        if (events.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Center(
              child: Text(
                'No events in this range',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: colorScheme.onSurfaceVariant,
                    ),
              ),
            ),
          )
        else
          ..._buildPluginSections(
            shareState,
            events,
            enabledPlugins,
          ),
      ],
    );
  }

  List<Widget> _buildPluginSections(
    TimelineShareState shareState,
    List<TimelineEvent> events,
    List<TimeFlowPlugin> enabledPlugins,
  ) {
    final colorScheme = Theme.of(context).colorScheme;
    final widgets = <Widget>[];
    const maxPerPlugin = 20;

    final selectedPlugins = enabledPlugins.where(
      (p) => shareState.selectedPluginIds.contains(p.id),
    );

    for (final plugin in selectedPlugins) {
      final pluginEvents =
          events.where((e) => e.pluginId == plugin.id).toList();
      if (pluginEvents.isEmpty) continue;

      final meta = plugin.metadata;
      final accentColor = meta.accentColor ?? colorScheme.primary;

      // Section header
      widgets.add(Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 8),
        child: Row(
          children: [
            Icon(meta.icon, size: 18, color: accentColor),
            const SizedBox(width: 8),
            Text(
              plugin.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: accentColor,
                  ),
            ),
          ],
        ),
      ));

      // Events (capped at maxPerPlugin)
      final displayEvents = pluginEvents.take(maxPerPlugin);
      for (final event in displayEvents) {
        widgets.add(_buildEventPreviewItem(
          event,
          accentColor,
          shareState.hideDetails,
        ));
      }

      if (pluginEvents.length > maxPerPlugin) {
        widgets.add(Padding(
          padding: const EdgeInsets.only(left: 16, bottom: 8),
          child: Text(
            '...and ${pluginEvents.length - maxPerPlugin} more',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
          ),
        ));
      }
    }

    return widgets;
  }

  Widget _buildEventPreviewItem(
    TimelineEvent event,
    Color accentColor,
    bool hideDetails,
  ) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 36,
            decoration: BoxDecoration(
              color: event.color ?? accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatEventTime(event.startTime),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                Text(
                  event.title,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                if (!hideDetails &&
                    event.subtitle != null &&
                    event.subtitle!.isNotEmpty)
                  Text(
                    event.subtitle!,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  bool _isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
