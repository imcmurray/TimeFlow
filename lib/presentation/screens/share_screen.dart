import 'dart:ui' as ui;

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:timeflow/core/app_links.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/domain/entities/task_category.dart';
import 'package:timeflow/domain/sharing/share_codec.dart';
import 'package:timeflow/domain/time/local_date.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';
import 'package:timeflow/presentation/providers/task_provider.dart';
import 'package:timeflow/presentation/utils/time_formatter.dart';

/// Shares part of the schedule with someone else: as a link that opens a
/// live, read-only TimeFlow in their browser, as text, or as an image.
class ShareScreen extends ConsumerStatefulWidget {
  /// First day to share.
  final DateTime date;

  const ShareScreen({super.key, required this.date});

  @override
  ConsumerState<ShareScreen> createState() => _ShareScreenState();
}

class _ShareScreenState extends ConsumerState<ShareScreen> {
  int _days = 1;
  bool _wholeDay = true;
  int _fromHour = 8;
  int _toHour = 18;
  bool _includeDetails = true;
  final _title = TextEditingController();
  final _previewKey = GlobalKey();

  LocalDate get _first => LocalDate.of(widget.date);

  @override
  void dispose() {
    _title.dispose();
    super.dispose();
  }

  List<Task> _tasks() {
    final range = DayRange(_first, _first.addDays(_days - 1));
    final tasks = ref.watch(tasksInRangeProvider(range)).value ?? const [];
    return [
      for (final t in tasks)
        if (_wholeDay || _inHours(t))
          _includeDetails ? t : t.copyWith(description: null, notes: null),
    ];
  }

  bool _inHours(Task t) {
    // Keep tasks that overlap the chosen hours on any of their days.
    final startMinute = t.startTime.hour * 60 + t.startTime.minute;
    final endMinute = LocalDate.of(t.endTime) == LocalDate.of(t.startTime)
        ? t.endTime.hour * 60 + t.endTime.minute
        : 24 * 60;
    return startMinute < _toHour * 60 && endMinute > _fromHour * 60;
  }

  String? get _heading {
    final t = _title.text.trim();
    return t.isEmpty ? null : t;
  }

  bool get _use24Hour => ref.read(settingsProvider).use24HourFormat;

  String _time(DateTime t) =>
      TimeFormatter.formatTime(t, use24HourFormat: _use24Hour);

  String _rangeLabel() {
    if (_days == 1) return TimeFormatter.formatDateFull(_first.startOfDay);
    final last = _first.addDays(_days - 1);
    return '${TimeFormatter.formatDateCompact(_first.startOfDay)} – '
        '${TimeFormatter.formatDateCompact(last.startOfDay)}';
  }

  Uri _link(List<Task> tasks) => ShareCodec.link(
    webAppUrl(),
    SharedSchedule(title: _heading, tasks: tasks),
  );

  String _text(List<Task> tasks) {
    final b = StringBuffer()
      ..writeln(_heading ?? 'Schedule for ${_rangeLabel()}');
    LocalDate? day;
    for (final t in tasks) {
      final d = LocalDate.of(t.startTime);
      if (_days > 1 && d != day) {
        b
          ..writeln()
          ..writeln(TimeFormatter.formatDateFull(d.startOfDay));
        day = d;
      }
      b.writeln('${_time(t.startTime)}–${_time(t.endTime)}  ${t.title}');
      if (t.description != null) b.writeln('    ${t.description}');
      if (t.notes != null) b.writeln('    ${t.notes}');
    }
    if (tasks.isEmpty) b.writeln('Nothing scheduled.');
    return b.toString();
  }

  void _snack(String message) => ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
  );

  Rect? _shareOrigin() {
    final box = context.findRenderObject() as RenderBox?;
    return box == null ? null : box.localToGlobal(Offset.zero) & box.size;
  }

  Future<void> _shareLink(List<Task> tasks) async {
    final link = _link(tasks).toString();
    final result = await SharePlus.instance.share(
      ShareParams(
        text: '${_heading ?? 'My schedule for ${_rangeLabel()}'}\n$link',
        subject: _heading ?? 'Schedule for ${_rangeLabel()}',
        sharePositionOrigin: _shareOrigin(),
      ),
    );
    if (result.status == ShareResultStatus.unavailable) {
      await _copy(link, 'Link copied');
    }
  }

  Future<void> _copy(String text, String message) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (mounted) _snack(message);
  }

  Future<void> _shareImage() async {
    final boundary =
        _previewKey.currentContext?.findRenderObject()
            as RenderRepaintBoundary?;
    if (boundary == null) return;
    final image = await boundary.toImage(pixelRatio: 3);
    final bytes = (await image.toByteData(
      format: ui.ImageByteFormat.png,
    ))!.buffer.asUint8List();
    final name = 'timeflow-${_first.toIso()}.png';
    final desktop =
        !kIsWeb &&
        const {
          TargetPlatform.linux,
          TargetPlatform.windows,
          TargetPlatform.macOS,
        }.contains(defaultTargetPlatform);
    if (desktop) {
      final saved = await FilePicker.saveFile(
        fileName: name,
        bytes: bytes,
        mimeType: 'image/png',
        type: FileType.image,
      );
      if (saved != null && mounted) _snack('Image saved');
      return;
    }
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile.fromData(bytes, mimeType: 'image/png', name: name)],
        fileNameOverrides: [name],
        subject: _heading ?? 'Schedule for ${_rangeLabel()}',
        sharePositionOrigin: _shareOrigin(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tasks = _tasks();
    final theme = Theme.of(context);
    String hour(int h) =>
        TimeFormatter.formatHour(h, use24HourFormat: _use24Hour);

    return Scaffold(
      appBar: AppBar(title: const Text('Share schedule')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Days', style: theme.textTheme.titleSmall),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 1, label: Text('This day')),
                ButtonSegment(value: 3, label: Text('3 days')),
                ButtonSegment(value: 7, label: Text('A week')),
              ],
              selected: {_days},
              onSelectionChanged: (s) => setState(() => _days = s.single),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Whole day'),
              value: _wholeDay,
              onChanged: (v) => setState(() => _wholeDay = v),
            ),
            if (!_wholeDay)
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _fromHour,
                      decoration: const InputDecoration(
                        labelText: 'From',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (var h = 0; h < 24; h++)
                          DropdownMenuItem(value: h, child: Text(hour(h))),
                      ],
                      onChanged: (v) => setState(() {
                        _fromHour = v!;
                        if (_toHour <= _fromHour) _toHour = _fromHour + 1;
                      }),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      key: ValueKey(_toHour),
                      initialValue: _toHour,
                      decoration: const InputDecoration(
                        labelText: 'To',
                        border: OutlineInputBorder(),
                      ),
                      items: [
                        for (var h = _fromHour + 1; h <= 24; h++)
                          DropdownMenuItem(value: h, child: Text(hour(h % 24))),
                      ],
                      onChanged: (v) => setState(() => _toHour = v!),
                    ),
                  ),
                ],
              ),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Include descriptions and notes'),
              subtitle: const Text('Turn off to share only titles and times'),
              value: _includeDetails,
              onChanged: (v) => setState(() => _includeDetails = v),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _title,
              decoration: const InputDecoration(
                labelText: 'Heading (optional)',
                hintText: "e.g. Biscuit's routine",
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            RepaintBoundary(
              key: _previewKey,
              child: _Preview(
                heading: _heading ?? _rangeLabel(),
                tasks: tasks,
                showDays: _days > 1,
                time: _time,
              ),
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: () => _shareLink(tasks),
              icon: const Icon(Icons.link),
              label: const Text('Share link'),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(
                'Opens a live, read-only timeline in any browser. The schedule '
                'travels inside the link; it isn\'t uploaded anywhere.',
                style: theme.textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 8,
              children: [
                OutlinedButton.icon(
                  onPressed: () =>
                      _copy(_link(tasks).toString(), 'Link copied'),
                  icon: const Icon(Icons.copy),
                  label: const Text('Copy link'),
                ),
                OutlinedButton.icon(
                  onPressed: () => SharePlus.instance.share(
                    ShareParams(
                      text: _text(tasks),
                      sharePositionOrigin: _shareOrigin(),
                    ),
                  ),
                  icon: const Icon(Icons.notes),
                  label: const Text('Text'),
                ),
                OutlinedButton.icon(
                  onPressed: _shareImage,
                  icon: const Icon(Icons.image_outlined),
                  label: const Text('Image'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// The schedule as it will look in the shared image.
class _Preview extends StatelessWidget {
  final String heading;
  final List<Task> tasks;
  final bool showDays;
  final String Function(DateTime) time;

  const _Preview({
    required this.heading,
    required this.tasks,
    required this.showDays,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final rows = <Widget>[];
    LocalDate? day;
    for (final t in tasks) {
      final d = LocalDate.of(t.startTime);
      if (showDays && d != day) {
        rows.add(
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 4),
            child: Text(
              TimeFormatter.formatDateFull(d.startOfDay),
              style: theme.textTheme.labelLarge,
            ),
          ),
        );
        day = d;
      }
      final color = t.category != TaskCategory.none
          ? t.category.color
          : theme.colorScheme.primary;
      rows.add(
        Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(10),
            border: Border(left: BorderSide(color: color, width: 4)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: 92,
                child: Text(
                  '${time(t.startTime)}\n${time(t.endTime)}',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      t.title,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (t.description != null)
                      Text(t.description!, style: theme.textTheme.bodySmall),
                    if (t.notes != null)
                      Text(
                        t.notes!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.water, color: theme.colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(heading, style: theme.textTheme.titleMedium),
              ),
            ],
          ),
          if (tasks.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 12),
              child: Text('Nothing scheduled.'),
            ),
          ...rows,
          const SizedBox(height: 8),
          Text(
            'Made with TimeFlow',
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
