import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cron_timeflow/plugins/server_flow/presentation/helpers/csv_file_picker.dart';
import 'package:cron_timeflow/plugins/server_flow/presentation/providers/server_flow_providers.dart';
import 'package:cron_timeflow/plugins/server_flow/presentation/widgets/csv_format_help.dart';

/// Screen for importing cron jobs from CSV files.
class CsvUploadScreen extends ConsumerStatefulWidget {
  const CsvUploadScreen({super.key});

  @override
  ConsumerState<CsvUploadScreen> createState() => _CsvUploadScreenState();
}

class _CsvUploadScreenState extends ConsumerState<CsvUploadScreen> {
  String? _previewText;
  List<List<String>>? _previewRows;

  @override
  Widget build(BuildContext context) {
    final importState = ref.watch(csvImportProvider);
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Import CSV'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // File picker button
            FilledButton.icon(
              onPressed: importState.isActive ? null : _pickFile,
              icon: const Icon(Icons.upload_file),
              label: const Text('Select CSV File'),
            ),
            const SizedBox(height: 16),

            // CSV format help
            const CsvFormatHelp(),
            const SizedBox(height: 16),

            // Preview table
            if (_previewRows != null && _previewRows!.isNotEmpty) ...[
              Text(
                'Preview (first ${_previewRows!.length - 1} rows)',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Expanded(
                flex: 2,
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: SingleChildScrollView(
                    child: _buildPreviewTable(),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Import button
            if (_previewText != null &&
                importState.status != CsvImportStatus.done)
              FilledButton.icon(
                onPressed: importState.isActive ? null : _importCsv,
                icon: importState.isActive
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.download_done),
                label: Text(importState.isActive ? 'Importing...' : 'Import'),
              ),

            // Status messages
            if (importState.status == CsvImportStatus.done &&
                importState.result != null) ...[
              const SizedBox(height: 16),
              Card(
                color: colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Import complete',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: colorScheme.onPrimaryContainer,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${importState.result!.jobs.length} jobs imported '
                        '(${importState.result!.errors.length} errors)',
                        style: TextStyle(color: colorScheme.onPrimaryContainer),
                      ),
                    ],
                  ),
                ),
              ),
            ],

            if (importState.status == CsvImportStatus.error) ...[
              const SizedBox(height: 16),
              Card(
                color: colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    importState.errorMessage ?? 'Unknown error',
                    style: TextStyle(color: colorScheme.onErrorContainer),
                  ),
                ),
              ),
            ],

            // Error list from parsing
            if (importState.result != null &&
                importState.result!.errors.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text(
                'Parsing errors',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  itemCount: importState.result!.errors.length,
                  itemBuilder: (context, index) {
                    final error = importState.result!.errors[index];
                    return ListTile(
                      dense: true,
                      leading: Icon(Icons.warning_amber,
                          color: colorScheme.error, size: 20),
                      title: Text('Row ${error.row}'),
                      subtitle: Text(error.message),
                    );
                  },
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _pickFile() async {
    final text = await pickCsvFile();
    if (text == null) return;

    setState(() {
      _previewText = text;
      _previewRows = _parsePreview(text);
    });
  }

  void _importCsv() {
    if (_previewText == null) return;
    ref.read(csvImportProvider.notifier).importCsv(_previewText!);
  }

  List<List<String>> _parsePreview(String text) {
    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    final previewLines = lines.take(11).toList(); // header + 10 rows

    return previewLines.map((line) {
      // Simple split — actual parsing uses csv package
      if (line.contains('\t')) return line.split('\t');
      if (line.contains(';')) return line.split(';');
      return line.split(',');
    }).toList();
  }

  Widget _buildPreviewTable() {
    if (_previewRows == null || _previewRows!.isEmpty) {
      return const SizedBox.shrink();
    }

    final headers = _previewRows!.first;
    final dataRows = _previewRows!.skip(1).toList();

    return DataTable(
      columns: headers
          .map((h) => DataColumn(
                label: Text(
                  h.trim(),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ))
          .toList(),
      rows: dataRows
          .map((row) => DataRow(
                cells: List.generate(
                  headers.length,
                  (i) => DataCell(Text(
                    i < row.length ? row[i].trim() : '',
                    overflow: TextOverflow.ellipsis,
                  )),
                ),
              ))
          .toList(),
    );
  }
}
