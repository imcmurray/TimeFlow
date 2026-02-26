import 'package:flutter/material.dart';
import 'package:cron_timeflow/core/plugins/plugin_interface.dart';

/// Shows a bottom sheet with full details for a plugin timeline event.
void showEventDetailPopup(BuildContext context, TimelineEvent event) {
  final colorScheme = Theme.of(context).colorScheme;
  final meta = event.metadata;

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (context) => DraggableScrollableSheet(
      initialChildSize: 0.4,
      minChildSize: 0.2,
      maxChildSize: 0.6,
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
                color: colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Title
          Text(
            event.title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          if (event.subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              event.subtitle!,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
            ),
          ],
          const SizedBox(height: 16),
          const Divider(),
          const SizedBox(height: 8),

          // Time info
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

          // Dynamic metadata rows
          ...meta.entries
              .where((e) =>
                  e.key != 'id' &&
                  e.value != null &&
                  e.value.toString().isNotEmpty)
              .map((e) => _DetailRow(
                    icon: _iconForKey(e.key),
                    label: _formatKey(e.key),
                    value: e.value.toString(),
                  )),
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
