import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/domain/entities/task_category.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';
import 'package:timeflow/presentation/providers/task_provider.dart';
import 'package:timeflow/services/recurring_task_service.dart';
import 'package:uuid/uuid.dart';

/// Full-screen modal for task creation and editing.
///
/// Provides comprehensive task management with all available fields:
/// title, times, priority, description, reminders, recurrence, and attachments.
class TaskDetailScreen extends ConsumerStatefulWidget {
  /// The task to edit, or null for creating a new task.
  final Task? task;

  /// The initial date for new tasks.
  final DateTime? initialDate;

  const TaskDetailScreen({
    super.key,
    this.task,
    this.initialDate,
  });

  @override
  ConsumerState<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends ConsumerState<TaskDetailScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _notesController;

  late DateTime _startTime;
  late DateTime _endTime;
  bool _isImportant = false;
  int? _reminderMinutes;
  String? _recurringPattern;
  TaskCategory _category = TaskCategory.none;

  bool get _isEditing => widget.task != null;

  @override
  void initState() {
    super.initState();
    final task = widget.task;
    final now = DateTime.now();
    final initialDate = widget.initialDate ?? now;

    _titleController = TextEditingController(text: task?.title ?? '');
    _descriptionController = TextEditingController(text: task?.description ?? '');
    _notesController = TextEditingController(text: task?.notes ?? '');

    if (task != null) {
      _startTime = task.startTime;
      _endTime = task.endTime;
      _isImportant = task.isImportant;
      _reminderMinutes = task.reminderMinutes;
      _recurringPattern = task.recurringPattern;
      _category = task.category;
    } else {
      final taskDate = DateTime(initialDate.year, initialDate.month, initialDate.day);
      final nextHour = (now.hour + 1).clamp(0, 23);
      _startTime = DateTime(taskDate.year, taskDate.month, taskDate.day, nextHour);
      _endTime = _startTime.add(const Duration(hours: 1));
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectTime(bool isStart) async {
    final initialTime = TimeOfDay.fromDateTime(isStart ? _startTime : _endTime);
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );

    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = DateTime(
            _startTime.year,
            _startTime.month,
            _startTime.day,
            picked.hour,
            picked.minute,
          );
          if (_endTime.isBefore(_startTime) || _endTime.isAtSameMomentAs(_startTime)) {
            _endTime = _startTime.add(const Duration(hours: 1));
          }
        } else {
          _endTime = DateTime(
            _endTime.year,
            _endTime.month,
            _endTime.day,
            picked.hour,
            picked.minute,
          );
        }
      });
    }
  }

  String _formatTime(DateTime time) {
    final use24Hour = ref.read(settingsProvider).use24HourFormat;
    if (use24Hour) {
      return DateFormat('HH:mm').format(time);
    }
    final hour = time.hour == 0
        ? 12
        : time.hour > 12
            ? time.hour - 12
            : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  void _adjustDate(int days, {required bool isStart}) {
    setState(() {
      if (isStart) {
        _startTime = _startTime.add(Duration(days: days));
        if (_endTime.isBefore(_startTime) || _endTime.isAtSameMomentAs(_startTime)) {
          _endTime = _startTime.add(const Duration(hours: 1));
        }
      } else {
        _endTime = _endTime.add(Duration(days: days));
        if (_endTime.isBefore(_startTime) || _endTime.isAtSameMomentAs(_startTime)) {
          _endTime = _startTime.add(const Duration(hours: 1));
        }
      }
    });
  }

  Future<void> _showDatePicker({required bool isStart}) async {
    final currentDate = isStart ? _startTime : _endTime;
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (picked != null) {
      final currentDateOnly = DateTime(currentDate.year, currentDate.month, currentDate.day);
      final diff = picked.difference(currentDateOnly).inDays;
      if (diff != 0) {
        _adjustDate(diff, isStart: isStart);
      }
    }
  }

  Future<bool?> _showEditRecurringDialog() {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Recurring Task'),
        content: const Text(
          'Do you want to edit only this instance or all future instances?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('This instance only'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('All future instances'),
          ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final title = _titleController.text.trim();

    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a task title'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_endTime.isBefore(_startTime) || _endTime.isAtSameMomentAs(_startTime)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('End time must be after start time'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final now = DateTime.now();
    final repository = ref.read(taskRepositoryProvider);
    final description = _descriptionController.text.trim();
    final notes = _notesController.text.trim();

    if (_isEditing && widget.task!.recurringTemplateId != null) {
      final editAll = await _showEditRecurringDialog();
      if (editAll == null) return;

      if (editAll) {
        final templateId = widget.task!.recurringTemplateId!;
        final originalStartTime = widget.task!.startTime;
        await repository.updateFutureByTemplateId(
          templateId,
          originalStartTime,
          (existingTask) {
            final taskDuration = _endTime.difference(_startTime);
            final newEndTime = DateTime(
              existingTask.startTime.year,
              existingTask.startTime.month,
              existingTask.startTime.day,
              _startTime.hour,
              _startTime.minute,
            ).add(taskDuration);

            return existingTask.copyWith(
              title: title,
              description: description.isEmpty ? null : description,
              startTime: DateTime(
                existingTask.startTime.year,
                existingTask.startTime.month,
                existingTask.startTime.day,
                _startTime.hour,
                _startTime.minute,
              ),
              endTime: newEndTime,
              isImportant: _isImportant,
              reminderMinutes: _reminderMinutes,
              notes: notes.isEmpty ? null : notes,
              category: _category,
              updatedAt: now,
            );
          },
        );
        ref.read(taskNotifierProvider.notifier).notifyTasksChanged();

        if (mounted) {
          Navigator.of(context).pop();
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('All future instances updated'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }

    final task = Task(
      id: widget.task?.id ?? const Uuid().v4(),
      title: title,
      description: description.isEmpty ? null : description,
      startTime: _startTime,
      endTime: _endTime,
      isImportant: _isImportant,
      isCompleted: widget.task?.isCompleted ?? false,
      reminderMinutes: _reminderMinutes,
      recurringPattern: _recurringPattern,
      recurringTemplateId: widget.task?.recurringTemplateId,
      notes: notes.isEmpty ? null : notes,
      attachmentPath: widget.task?.attachmentPath,
      color: widget.task?.color,
      category: _category,
      createdAt: widget.task?.createdAt ?? now,
      updatedAt: now,
    );

    if (!_isEditing && _recurringPattern != null) {
      final instances = RecurringTaskService.generateInstances(task);
      await repository.saveAll(instances);
      ref.read(taskNotifierProvider.notifier).notifyTasksChanged();

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Created ${instances.length} recurring tasks'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
      return;
    }

    await repository.save(task);
    ref.read(taskNotifierProvider.notifier).notifyTasksChanged();

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEditing ? 'Task updated' : 'Task created'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _delete() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Task'),
        content: const Text('Are you sure you want to delete this task?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await ref.read(taskRepositoryProvider).delete(widget.task!.id);
              ref.read(taskNotifierProvider.notifier).notifyTasksChanged();

              if (context.mounted) {
                Navigator.of(context).pop(); // Close dialog
                Navigator.of(context).pop(); // Close detail screen
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Task deleted'),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Task' : 'New Task'),
        actions: [
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
              tooltip: 'Delete task',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Title field
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(
                labelText: 'Title',
                hintText: 'Enter task title',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.sentences,
              autofocus: !_isEditing,
            ),
            const SizedBox(height: 16),

            // Start date & time group
            _DateTimeGroup(
              label: 'Start',
              date: _startTime,
              formattedTime: _formatTime(_startTime),
              onDateChanged: (days) => _adjustDate(days, isStart: true),
              onDateTap: () => _showDatePicker(isStart: true),
              onTimeTap: () => _selectTime(true),
            ),
            const SizedBox(height: 12),

            // End date & time group
            _DateTimeGroup(
              label: 'End',
              date: _endTime,
              formattedTime: _formatTime(_endTime),
              onDateChanged: (days) => _adjustDate(days, isStart: false),
              onDateTap: () => _showDatePicker(isStart: false),
              onTimeTap: () => _selectTime(false),
            ),
            const SizedBox(height: 16),

            // Priority toggle
            SwitchListTile(
              title: const Text('Important'),
              subtitle: const Text('Mark this task as high priority'),
              value: _isImportant,
              onChanged: (value) {
                setState(() => _isImportant = value);
              },
              secondary: Icon(
                _isImportant ? Icons.star : Icons.star_border,
                color: _isImportant
                    ? Theme.of(context).colorScheme.tertiary
                    : null,
              ),
            ),
            const Divider(),

            // Description field
            TextField(
              controller: _descriptionController,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Add more details (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Reminder dropdown
            DropdownButtonFormField<int?>(
              value: _reminderMinutes,
              decoration: const InputDecoration(
                labelText: 'Reminder',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notifications_outlined),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('No reminder')),
                DropdownMenuItem(value: 5, child: Text('5 minutes before')),
                DropdownMenuItem(value: 10, child: Text('10 minutes before')),
                DropdownMenuItem(value: 15, child: Text('15 minutes before')),
                DropdownMenuItem(value: 30, child: Text('30 minutes before')),
                DropdownMenuItem(value: 60, child: Text('1 hour before')),
              ],
              onChanged: (value) {
                setState(() => _reminderMinutes = value);
              },
            ),
            const SizedBox(height: 16),

            // Recurring dropdown
            DropdownButtonFormField<String?>(
              value: _recurringPattern,
              decoration: const InputDecoration(
                labelText: 'Repeat',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.repeat),
              ),
              items: const [
                DropdownMenuItem(value: null, child: Text('Does not repeat')),
                DropdownMenuItem(value: 'daily', child: Text('Daily')),
                DropdownMenuItem(value: 'weekdays', child: Text('Weekdays')),
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'fortnightly', child: Text('Fortnightly')),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                DropdownMenuItem(value: 'bimonthly', child: Text('Every 2 Months')),
                DropdownMenuItem(value: 'quarterly', child: Text('Quarterly')),
                DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
              ],
              onChanged: (value) {
                setState(() => _recurringPattern = value);
              },
            ),
            const SizedBox(height: 16),

            // Category selector
            CategorySelector(
              value: _category,
              onChanged: (value) {
                setState(() => _category = value ?? TaskCategory.none);
              },
            ),
            const SizedBox(height: 16),

            // Notes field
            TextField(
              controller: _notesController,
              decoration: const InputDecoration(
                labelText: 'Notes',
                hintText: 'Additional notes (optional)',
                border: OutlineInputBorder(),
              ),
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 16),

            // Attachment button
            OutlinedButton.icon(
              onPressed: () {
                // TODO: Implement image picker
              },
              icon: const Icon(Icons.attach_file),
              label: const Text('Add attachment'),
            ),
            const SizedBox(height: 24),

            // Save button
            FilledButton(
              onPressed: _save,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Text(
                  _isEditing ? 'Save Changes' : 'Create Task',
                  style: const TextStyle(fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _TimePickerTile extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onTap;

  const _TimePickerTile({
    required this.label,
    required this.time,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class _DateSelector extends StatelessWidget {
  final String label;
  final DateTime date;
  final void Function(int days) onDateChanged;
  final VoidCallback onTap;

  const _DateSelector({
    required this.label,
    required this.date,
    required this.onDateChanged,
    required this.onTap,
  });

  String _formatDateCompact(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final difference = targetDate.difference(today).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference == -1) return 'Yesterday';

    return DateFormat('EEE, MMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          border: Border.all(color: Theme.of(context).dividerColor),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: Theme.of(context).textTheme.labelMedium?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatDateCompact(date),
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                InkWell(
                  onTap: () => onDateChanged(-1),
                  borderRadius: BorderRadius.circular(16),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.chevron_left, size: 20),
                  ),
                ),
                InkWell(
                  onTap: () => onDateChanged(1),
                  borderRadius: BorderRadius.circular(16),
                  child: const Padding(
                    padding: EdgeInsets.all(4),
                    child: Icon(Icons.chevron_right, size: 20),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DateTimeGroup extends StatelessWidget {
  final String label;
  final DateTime date;
  final String formattedTime;
  final void Function(int days) onDateChanged;
  final VoidCallback onDateTap;
  final VoidCallback onTimeTap;

  const _DateTimeGroup({
    required this.label,
    required this.date,
    required this.formattedTime,
    required this.onDateChanged,
    required this.onDateTap,
    required this.onTimeTap,
  });

  String _formatDateCompact(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final targetDate = DateTime(date.year, date.month, date.day);
    final difference = targetDate.difference(today).inDays;

    if (difference == 0) return 'Today';
    if (difference == 1) return 'Tomorrow';
    if (difference == -1) return 'Yesterday';

    return DateFormat('EEE, MMM d').format(date);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).dividerColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
            child: Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: Row(
              children: [
                // Date section
                Expanded(
                  flex: 3,
                  child: InkWell(
                    onTap: onDateTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _formatDateCompact(date),
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ),
                          InkWell(
                            onTap: () => onDateChanged(-1),
                            borderRadius: BorderRadius.circular(16),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.chevron_left, size: 20),
                            ),
                          ),
                          InkWell(
                            onTap: () => onDateChanged(1),
                            borderRadius: BorderRadius.circular(16),
                            child: const Padding(
                              padding: EdgeInsets.all(4),
                              child: Icon(Icons.chevron_right, size: 20),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: Theme.of(context).dividerColor,
                ),
                // Time section
                Expanded(
                  flex: 2,
                  child: InkWell(
                    onTap: onTimeTap,
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.access_time, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            formattedTime,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
