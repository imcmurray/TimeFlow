import 'package:flutter/material.dart';
import 'package:timeflow/core/plugins/plugin_interface.dart';

/// Shows a bottom sheet with full details for a plugin timeline event.
void showEventDetailPopup(BuildContext context, TimelineEvent event) {
  final meta = event.metadata;
  final mergedEvents = meta['_mergedEvents'];
  final isMerged = mergedEvents is List && mergedEvents.length > 1;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: isMerged ? 0.5 : 0.4,
      minChildSize: 0.2,
      maxChildSize: isMerged ? 0.8 : 0.6,
      expand: false,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(20),
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            event.title,
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
          ),
          if (event.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              event.subtitle!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          if (isMerged) ...[
            // Merged events list
            ...mergedEvents.cast<TimelineEvent>().map(
              (e) => _MergedEventTile(event: e),
            ),
          ] else ...[
            // Single event detail rows
            _DetailRow(
              icon: Icons.access_time,
              label: 'Start',
              value: _formatDateTime(event.startTime),
            ),
            if (event.endTime != null)
              _DetailRow(
                icon: Icons.access_time_filled,
                label: 'End',
                value: _formatDateTime(event.endTime!),
              ),

            // Dynamic metadata rows — filter internal _-prefixed keys
            ...meta.entries
                .where(
                  (e) =>
                      !e.key.startsWith('_') &&
                      e.key != 'id' &&
                      e.value != null &&
                      e.value.toString().isNotEmpty,
                )
                .map(
                  (e) => _DetailRow(
                    icon: _iconForKey(e.key),
                    label: _formatKey(e.key),
                    value: e.value.toString(),
                  ),
                ),
          ],
        ],
      ),
    ),
  );
}

IconData _iconForKey(String key) {
  return switch (key) {
    'host' => Icons.dns_outlined,
    'user' => Icons.person_outline,
    'schedule' => Icons.schedule,
    'category' => Icons.category_outlined,
    'os' => Icons.computer,
    'temperature' || 'temp' => Icons.thermostat,
    'condition' => Icons.wb_cloudy,
    'humidity' => Icons.water_drop,
    'author' => Icons.person,
    'quote' => Icons.format_quote,
    _ => Icons.info_outline,
  };
}

String _formatKey(String key) {
  return key
      .replaceAll('_', ' ')
      .split(' ')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

String _formatDateTime(DateTime dt) {
  return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-'
      '${dt.day.toString().padLeft(2, '0')} '
      '${dt.hour.toString().padLeft(2, '0')}:'
      '${dt.minute.toString().padLeft(2, '0')}';
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w400),
            ),
          ),
        ],
      ),
    );
  }
}

class _MergedEventTile extends StatelessWidget {
  final TimelineEvent event;

  const _MergedEventTile({required this.event});

  @override
  Widget build(BuildContext context) {
    final color = event.color ?? Theme.of(context).colorScheme.primary;
    final host = event.metadata['host']?.toString() ?? event.groupKey ?? '';
    final command = event.metadata['command']?.toString() ?? event.title;
    final user = event.metadata['user']?.toString() ?? '';
    final time = _formatDateTime(event.startTime);

    return Card(
      margin: const EdgeInsets.only(bottom: 6),
      child: ListTile(
        dense: true,
        leading: CircleAvatar(
          radius: 14,
          backgroundColor: color,
          child: const Icon(Icons.terminal, size: 14, color: Colors.white),
        ),
        title: Text(
          command,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 13),
        ),
        subtitle: Text(
          '$host  |  $user  |  $time',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 11),
        ),
      ),
    );
  }
}
