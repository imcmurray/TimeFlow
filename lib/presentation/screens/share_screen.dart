import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/presentation/providers/task_provider.dart';

/// Screen for sharing the day's schedule as text or image.
class ShareScreen extends ConsumerStatefulWidget {
  final DateTime date;

  const ShareScreen({super.key, required this.date});

  @override
  ConsumerState<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends ConsumerState<ShareScreen> {
  int _startHour = 8;
  int _endHour = 18;
  bool _hideDetails = false;
  final GlobalKey _previewKey = GlobalKey();

  List<Task> _getFilteredTasks() {
    final tasks = ref.read(tasksForDateProvider(widget.date));
    return tasks.where((task) {
      final taskStartHour = task.startTime.hour;
      final taskEndHour = task.endTime.hour + (task.endTime.minute > 0 ? 1 : 0);
      return taskStartHour < _endHour && taskEndHour > _startHour;
    }).toList()
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
  }

  String _formatDate() {
    const weekdays = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];
    return '${weekdays[widget.date.weekday - 1]}, ${months[widget.date.month - 1]} ${widget.date.day}';
  }

  String _formatHour(int hour) {
    if (hour == 0) return '12:00 AM';
    if (hour == 12) return '12:00 PM';
    if (hour < 12) return '$hour:00 AM';
    return '${hour - 12}:00 PM';
  }

  String _formatTaskTime(DateTime time) {
    final hour = time.hour == 0
        ? 12
        : time.hour > 12
            ? time.hour - 12
            : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  String _generateShareText() {
    final tasks = _getFilteredTasks();
    final buffer = StringBuffer();

    buffer.writeln('Schedule for ${_formatDate()}');
    buffer.writeln('${_formatHour(_startHour)} - ${_formatHour(_endHour)}');
    buffer.writeln();

    if (tasks.isEmpty) {
      buffer.writeln('No tasks scheduled');
    } else {
      for (final task in tasks) {
        final timeStr = '${_formatTaskTime(task.startTime)} - ${_formatTaskTime(task.endTime)}';
        buffer.writeln('$timeStr: ${task.title}');
        if (!_hideDetails && task.description != null && task.description!.isNotEmpty) {
          buffer.writeln('  ${task.description}');
        }
      }
    }

    return buffer.toString();
  }

  Future<Uint8List?> _capturePreview() async {
    final boundary = _previewKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return null;

    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  Future<void> _shareAsText() async {
    final text = _generateShareText();
    await Share.share(text, subject: 'Schedule for ${_formatDate()}');
  }

  Future<void> _shareAsImage() async {
    final imageBytes = await _capturePreview();
    if (imageBytes == null) return;

    final fileName = 'schedule_${widget.date.toIso8601String().split('T')[0]}.png';

    if (Platform.isLinux) {
      final homeDir = Platform.environment['HOME'] ?? '/tmp';
      final picturesDir = Directory('$homeDir/Pictures');
      if (!await picturesDir.exists()) {
        await picturesDir.create(recursive: true);
      }
      final file = File('${picturesDir.path}/$fileName');
      await file.writeAsBytes(imageBytes);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Saved to ${file.path}'),
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Open Folder',
              onPressed: () => Process.run('xdg-open', [picturesDir.path]),
            ),
          ),
        );
      }
    } else {
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$fileName');
      await file.writeAsBytes(imageBytes);

      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Schedule for ${_formatDate()}',
      );
    }
  }

  Future<void> _copyToClipboard() async {
    final text = _generateShareText();
    await Clipboard.setData(ClipboardData(text: text));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Schedule copied to clipboard'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final tasks = _getFilteredTasks();
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Share Schedule'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Time Range Section
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
                            initialValue: _startHour,
                            decoration: const InputDecoration(
                              labelText: 'From',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: List.generate(24, (i) => i).map((hour) {
                              return DropdownMenuItem(
                                value: hour,
                                child: Text(_formatHour(hour)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null) {
                                setState(() {
                                  _startHour = value;
                                  if (_endHour <= _startHour) {
                                    _endHour = (_startHour + 1).clamp(0, 24);
                                  }
                                });
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
                            initialValue: _endHour,
                            decoration: const InputDecoration(
                              labelText: 'To',
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            items: List.generate(24, (i) => i + 1).map((hour) {
                              return DropdownMenuItem(
                                value: hour,
                                child: Text(hour == 24 ? '12:00 AM' : _formatHour(hour)),
                              );
                            }).toList(),
                            onChanged: (value) {
                              if (value != null && value > _startHour) {
                                setState(() => _endHour = value);
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

            // Privacy Toggle
            Card(
              child: SwitchListTile(
                title: const Text('Hide task details'),
                subtitle: const Text('Only share task titles and times'),
                value: _hideDetails,
                onChanged: (value) => setState(() => _hideDetails = value),
              ),
            ),
            const SizedBox(height: 16),

            // Preview Section
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatDate(),
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    Text(
                      '${_formatHour(_startHour)} - ${_formatHour(_endHour)}',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                    ),
                    const SizedBox(height: 16),
                    if (tasks.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Center(
                          child: Text(
                            'No tasks in this time range',
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ),
                      )
                    else
                      ...tasks.map((task) => _buildTaskPreviewItem(task)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Share Buttons
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _shareAsText,
                    icon: const Icon(Icons.text_fields),
                    label: const Text('Share Text'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: _shareAsImage,
                    icon: const Icon(Icons.image_outlined),
                    label: const Text('Share Image'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _copyToClipboard,
              icon: const Icon(Icons.copy),
              label: const Text('Copy to Clipboard'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaskPreviewItem(Task task) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: task.isImportant ? colorScheme.tertiary : colorScheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_formatTaskTime(task.startTime)} - ${_formatTaskTime(task.endTime)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                ),
                Text(
                  task.title,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w500,
                      ),
                ),
                if (!_hideDetails && task.description != null && task.description!.isNotEmpty)
                  Text(
                    task.description!,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
          if (task.isImportant)
            Icon(
              Icons.star,
              size: 16,
              color: colorScheme.tertiary,
            ),
        ],
      ),
    );
  }
}
