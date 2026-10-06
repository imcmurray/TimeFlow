import 'package:flutter/material.dart';

/// Expandable card showing CSV format documentation for the upload screen.
///
/// Collapsed by default to keep the screen clean. When expanded, shows
/// required/optional columns, an example CSV snippet, and parsing notes.
class CsvFormatHelp extends StatelessWidget {
  const CsvFormatHelp({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        leading: Icon(Icons.info_outline, color: colorScheme.primary),
        title: const Text('CSV Format'),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildKeyRules(theme),
                const SizedBox(height: 16),
                _buildRequiredColumns(theme, colorScheme),
                const SizedBox(height: 16),
                _buildOptionalColumns(theme, colorScheme),
                const SizedBox(height: 16),
                _buildExample(theme, colorScheme),
                const SizedBox(height: 16),
                _buildNotes(theme, colorScheme),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeyRules(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Column order doesn\'t matter — just include the header names. '
          'Headers are case-insensitive. '
          'Delimiter is auto-detected (comma, semicolon, or tab).',
          style: theme.textTheme.bodyMedium,
        ),
      ],
    );
  }

  Widget _buildRequiredColumns(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Required Columns', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Table(
          border: TableBorder.all(
            color: colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(4),
          ),
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1.5),
            2: FlexColumnWidth(3),
          },
          children: [
            _headerRow(['Column', 'Type', 'Example'], colorScheme),
            _dataRow(['host', 'text', 'web-prod-01']),
            _dataRow(['command', 'text', '/usr/bin/backup']),
            _dataRow(['start_time', 'ISO 8601', '2025-01-15T02:30:00']),
            _dataRow(['user', 'text', 'root']),
          ],
        ),
      ],
    );
  }

  Widget _buildOptionalColumns(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Optional Columns', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Table(
          border: TableBorder.all(
            color: colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(4),
          ),
          columnWidths: const {
            0: FlexColumnWidth(2),
            1: FlexColumnWidth(1.5),
            2: FlexColumnWidth(1.5),
            3: FlexColumnWidth(3),
          },
          children: [
            _headerRow(['Column', 'Type', 'Default', 'Example'], colorScheme),
            _dataRow(['category', 'text', 'uncategorized', 'backups']),
            _dataRow(['duration', 'seconds', '0', '3600']),
            _dataRow(['schedule', 'cron/once', '\u2014', '0 2 * * *']),
            _dataRow(['os', 'text', 'linux', 'macos']),
            _dataRow(['end_time', 'ISO 8601', '\u2014', '2025-01-15T03:30:00']),
          ],
        ),
      ],
    );
  }

  Widget _buildExample(ThemeData theme, ColorScheme colorScheme) {
    const exampleCsv =
        'host,command,start_time,user,schedule\n'
        'web-01,/usr/bin/backup,2025-01-15T02:30:00,root,0 2 * * *\n'
        'db-01,/opt/vacuum.sh,2025-01-15T03:00:00,postgres,once';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Example', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            exampleCsv,
            style: theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
          ),
        ),
      ],
    );
  }

  Widget _buildNotes(ThemeData theme, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Notes', style: theme.textTheme.titleSmall),
        const SizedBox(height: 8),
        _buildNoteRow(
          Icons.info_outline,
          'end_time overrides duration when both are present',
          colorScheme,
        ),
        const SizedBox(height: 4),
        _buildNoteRow(
          Icons.schedule,
          'schedule accepts cron expressions (0 2 * * *) or "once"',
          colorScheme,
        ),
      ],
    );
  }

  Widget _buildNoteRow(IconData icon, String text, ColorScheme colorScheme) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 13, color: colorScheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }

  TableRow _headerRow(List<String> cells, ColorScheme colorScheme) {
    return TableRow(
      decoration: BoxDecoration(color: colorScheme.surfaceContainerHighest),
      children: cells
          .map(
            (cell) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(
                cell,
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          )
          .toList(),
    );
  }

  TableRow _dataRow(List<String> cells) {
    return TableRow(
      children: cells
          .map(
            (cell) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
              child: Text(cell),
            ),
          )
          .toList(),
    );
  }
}
