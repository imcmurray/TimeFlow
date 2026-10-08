import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/domain/entities/recurrence_rule.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/domain/entities/task_category.dart';
import 'package:timeflow/presentation/widgets/category_widgets.dart';
import 'package:timeflow/domain/time/local_date.dart';
import 'package:timeflow/domain/time/wall_clock.dart';
import 'package:timeflow/presentation/helpers/photo_picker.dart';
import 'package:timeflow/presentation/helpers/task_actions.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';
import 'package:timeflow/presentation/providers/task_provider.dart';
import 'package:timeflow/presentation/utils/time_formatter.dart';
import 'package:timeflow/presentation/widgets/edit_scope_dialog.dart';
import 'package:timeflow/presentation/widgets/recurrence_picker.dart';
import 'package:timeflow/presentation/widgets/task_photo.dart';
import 'package:timeflow/services/reminder_coordinator.dart';
import 'package:timeflow/services/task_service.dart';

/// Creates or edits a task.
class TaskDetailScreen extends ConsumerStatefulWidget {
  /// The task (or occurrence) to edit; null creates a new task.
  final Task? task;

  /// Day for a new task; it starts at the next whole hour.
  final DateTime? initialDate;

  /// Exact times for a new task (from long-pressing the timeline).
  final DateTime? initialStartTime;
  final DateTime? initialEndTime;

  const TaskDetailScreen({
    super.key,
    this.task,
    this.initialDate,
    this.initialStartTime,
    this.initialEndTime,
  });

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  static const _reminderOptions = [0, 5, 10, 15, 30, 60, 120, 1440];

  late final TextEditingController _title;
  late final TextEditingController _description;
  late final TextEditingController _notes;

  late DateTime _start;
  late DateTime _end;
  bool _important = false;
  bool _completed = false;
  int? _reminderMinutes;
  RecurrenceRule? _recurrence;
  String _categoryId = TaskCategory.noneId;
  String? _attachment;
  bool _saving = false;

  late final Task _initial;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    _title = TextEditingController(text: task?.title ?? '');
    _description = TextEditingController(text: task?.description ?? '');
    _notes = TextEditingController(text: task?.notes ?? '');

    if (task != null) {
      _start = task.startTime;
      _end = task.endTime;
      _important = task.isImportant;
      _completed = task.isCompleted;
      _reminderMinutes = task.reminderMinutes;
      _recurrence = task.recurrence;
      _categoryId = task.categoryId;
      _attachment = task.attachmentPath;
    } else {
      if (widget.initialStartTime != null && widget.initialEndTime != null) {
        _start = widget.initialStartTime!;
        _end = widget.initialEndTime!;
      } else {
        final now = DateTime.now();
        final day = LocalDate.of(widget.initialDate ?? now);
        _start = day.at(now.hour + 1, 0);
        if (LocalDate.of(_start) != day) _start = day.at(9, 0);
        _end = addWallMinutes(_start, 60);
      }
      final settings = ref.read(settingsProvider);
      _reminderMinutes = settings.notificationsEnabled
          ? settings.defaultReminderMinutes
          : null;
    }
    _initial = _draft();
  }

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    _notes.dispose();
    super.dispose();
  }

  String? _trimmed(TextEditingController c) {
    final t = c.text.trim();
    return t.isEmpty ? null : t;
  }

  /// The task as currently entered.
  Task _draft() {
    final now = DateTime.now();
    final base =
        widget.task ??
        Task(
          id: 'new',
          title: '',
          startTime: _start,
          endTime: _end,
          createdAt: now,
          updatedAt: now,
        );
    return base.copyWith(
      title: _title.text.trim(),
      description: _trimmed(_description),
      notes: _trimmed(_notes),
      startTime: _start,
      endTime: _end,
      isImportant: _important,
      isCompleted: _completed,
      reminderMinutes: _reminderMinutes,
      recurrence: _recurrence,
      categoryId: _categoryId,
      attachmentPath: _attachment,
    );
  }

  Future<void> _addPhoto() async {
    try {
      final photo = await pickPhoto(context);
      if (photo == null) return;
      final reference = await ref
          .read(taskRepositoryProvider)
          .saveAttachment(photo.bytes, photo.mimeType);
      if (mounted) setState(() => _attachment = reference);
    } catch (e) {
      _snack('Couldn\'t add that photo');
    }
  }

  bool get _isDirty {
    final d = _draft();
    return !d.sameContentAs(_initial) || d.recurrence != _initial.recurrence;
  }

  // ----------------------------------------------------------- date & time

  void _setStart(DateTime start) {
    final length = wallMinutesBetween(_start, _end);
    setState(() {
      _start = start;
      _end = addWallMinutes(start, length > 0 ? length : 60);
    });
  }

  void _setEnd(DateTime end) {
    setState(() {
      _end = end;
      if (!_end.isAfter(_start)) _end = addWallMinutes(_start, 15);
    });
  }

  DateTime _withDate(DateTime t, LocalDate date) => date.at(t.hour, t.minute);

  Future<void> _pickDate({required bool start}) async {
    final current = start ? _start : _end;
    final now = DateTime.now();
    DateTime earlier(DateTime a, DateTime b) => a.isBefore(b) ? a : b;
    DateTime later(DateTime a, DateTime b) => a.isAfter(b) ? a : b;
    final picked = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: earlier(current, DateTime(now.year - 5)),
      lastDate: later(current, DateTime(now.year + 10)),
    );
    if (picked == null) return;
    final date = LocalDate.of(picked);
    start ? _setStart(_withDate(_start, date)) : _setEnd(_withDate(_end, date));
  }

  Future<void> _pickTime({required bool start}) async {
    final current = start ? _start : _end;
    final picked = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(current),
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          alwaysUse24HourFormat: ref.read(settingsProvider).use24HourFormat,
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    final t = LocalDate.of(current).at(picked.hour, picked.minute);
    start ? _setStart(t) : _setEnd(t);
  }

  void _shiftDay(int days, {required bool start}) {
    final current = start ? _start : _end;
    final t = _withDate(current, LocalDate.of(current).addDays(days));
    start ? _setStart(t) : _setEnd(t);
  }

  // ----------------------------------------------------------------- save

  void _snack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }

  Future<void> _save() async {
    if (_saving) return;
    final draft = _draft();
    if (draft.title.isEmpty) {
      _snack('Give the task a name');
      return;
    }
    if (!draft.endTime.isAfter(draft.startTime)) {
      _snack('The task has to end after it starts');
      return;
    }

    final service = ref.read(taskServiceProvider);
    final original = widget.task;
    setState(() => _saving = true);
    if (draft.reminderMinutes != null &&
        ref.read(settingsProvider).notificationsEnabled) {
      // First reminder: this is when the system asks for permission.
      await ref.read(reminderCoordinatorProvider).ensurePermission();
      if (!mounted) return;
    }
    try {
      if (original == null) {
        await service.create(draft);
      } else {
        var scope = EditScope.all;
        if (original.isOccurrence) {
          final ruleChanged = draft.recurrence != original.recurrence;
          final chosen = await showEditScopeDialog(
            context,
            verb: 'change',
            allowAll: true,
          );
          if (chosen == null) return;
          scope = chosen;
          if (scope == EditScope.thisOnly && ruleChanged) {
            // A single occurrence can't have its own pattern.
            scope = EditScope.thisAndFuture;
          }
        }
        await service.update(original, draft, scope);
      }
      if (!mounted) return;
      Navigator.of(context).pop();
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final deleted = await TaskActions(ref).delete(context, widget.task!);
    if (deleted && mounted) Navigator.of(context).pop();
  }

  Future<bool> _confirmDiscard() async {
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Discard changes?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep editing'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Discard'),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  String _reminderLabel(int minutes) => switch (minutes) {
    0 => 'At start time',
    60 => '1 hour before',
    120 => '2 hours before',
    1440 => '1 day before',
    _ => '$minutes minutes before',
  };

  @override
  Widget build(BuildContext context) {
    final use24Hour = ref.watch(
      settingsProvider.select((s) => s.use24HourFormat),
    );
    final occurrence = widget.task?.isOccurrence ?? false;
    final reminderChoices = {..._reminderOptions, ?_reminderMinutes}.toList()
      ..sort();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (!_isDirty || await _confirmDiscard()) {
          if (context.mounted) Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(_isEditing ? 'Edit task' : 'New task'),
          actions: [
            if (_isEditing)
              IconButton(
                icon: const Icon(Icons.delete_outline),
                onPressed: _delete,
                tooltip: 'Delete task',
              ),
            TextButton(
              onPressed: _saving ? null : _save,
              child: const Text('Save'),
            ),
          ],
        ),
        body: SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              TextField(
                controller: _title,
                decoration: const InputDecoration(
                  labelText: 'Title',
                  hintText: 'What needs to happen?',
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                textInputAction: TextInputAction.done,
                autofocus: !_isEditing,
                onSubmitted: (_) => _save(),
              ),
              const SizedBox(height: 16),
              _DateTimeGroup(
                label: 'Starts',
                time: _start,
                use24Hour: use24Hour,
                onShiftDay: (d) => _shiftDay(d, start: true),
                onDateTap: () => _pickDate(start: true),
                onTimeTap: () => _pickTime(start: true),
              ),
              const SizedBox(height: 12),
              _DateTimeGroup(
                label: 'Ends',
                time: _end,
                use24Hour: use24Hour,
                onShiftDay: (d) => _shiftDay(d, start: false),
                onDateTap: () => _pickDate(start: false),
                onTimeTap: () => _pickTime(start: false),
              ),
              const SizedBox(height: 16),
              RecurrencePicker(
                value: _recurrence,
                start: LocalDate.of(_start),
                onChanged: (r) => setState(() => _recurrence = r),
              ),
              if (occurrence)
                Padding(
                  padding: const EdgeInsets.only(top: 4, left: 12),
                  child: Text(
                    'You\'ll be asked whether changes apply to just this '
                    'task or the rest of the series.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              const SizedBox(height: 16),
              DropdownButtonFormField<int?>(
                initialValue: _reminderMinutes,
                decoration: const InputDecoration(
                  labelText: 'Reminder',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.notifications_outlined),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('No reminder'),
                  ),
                  for (final m in reminderChoices)
                    DropdownMenuItem(value: m, child: Text(_reminderLabel(m))),
                ],
                onChanged: (v) => setState(() => _reminderMinutes = v),
              ),
              const SizedBox(height: 16),
              CategoryPickerField(
                value: _categoryId,
                onChanged: (v) => setState(() => _categoryId = v),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Important'),
                value: _important,
                onChanged: (v) => setState(() => _important = v),
                secondary: Icon(
                  _important ? Icons.star : Icons.star_border,
                  color: _important
                      ? Theme.of(context).colorScheme.tertiary
                      : null,
                ),
              ),
              if (_isEditing)
                SwitchListTile(
                  title: const Text('Done'),
                  value: _completed,
                  onChanged: (v) => setState(() => _completed = v),
                  secondary: Icon(
                    _completed
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                  ),
                ),
              const SizedBox(height: 8),
              TextField(
                controller: _description,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  border: OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 5,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _notes,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Instructions for whoever picks this up',
                  border: OutlineInputBorder(),
                ),
                minLines: 2,
                maxLines: 8,
                textCapitalization: TextCapitalization.sentences,
              ),
              const SizedBox(height: 16),
              if (_attachment != null)
                TaskPhotoThumbnail(
                  reference: _attachment!,
                  onRemove: () => setState(() => _attachment = null),
                )
              else
                OutlinedButton.icon(
                  onPressed: _addPhoto,
                  icon: const Icon(Icons.add_a_photo_outlined),
                  label: const Text('Add a photo'),
                ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _saving ? null : _save,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    _isEditing ? 'Save changes' : 'Create task',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateTimeGroup extends StatelessWidget {
  final String label;
  final DateTime time;
  final bool use24Hour;
  final ValueChanged<int> onShiftDay;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;

  const _DateTimeGroup({
    required this.label,
    required this.time,
    required this.use24Hour,
    required this.onShiftDay,
    required this.onDateTap,
    required this.onTimeTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final date = TimeFormatter.formatDateCompact(time);
    final clock = TimeFormatter.formatTime(time, use24HourFormat: use24Hour);
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: theme.dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 4),
            child: Text(
              label,
              style: theme.textTheme.labelLarge?.copyWith(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                tooltip: 'Previous day',
                visualDensity: VisualDensity.compact,
                onPressed: () => onShiftDay(-1),
              ),
              Expanded(
                child: Semantics(
                  button: true,
                  label: '$label date, $date',
                  excludeSemantics: true,
                  child: InkWell(
                    onTap: onDateTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today, size: 18),
                          const SizedBox(width: 8),
                          Flexible(
                            child: Text(
                              date,
                              style: theme.textTheme.titleMedium,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                tooltip: 'Next day',
                visualDensity: VisualDensity.compact,
                onPressed: () => onShiftDay(1),
              ),
              Container(width: 1, height: 32, color: theme.dividerColor),
              // The time is never shortened; the date gives way instead.
              Semantics(
                button: true,
                label: '$label time, $clock',
                excludeSemantics: true,
                child: InkWell(
                  onTap: onTimeTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: 10,
                      horizontal: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.access_time, size: 18),
                        const SizedBox(width: 6),
                        Text(clock, style: theme.textTheme.titleMedium),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
