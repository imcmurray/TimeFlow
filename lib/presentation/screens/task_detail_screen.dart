import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/domain/entities/task.dart';

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
    } else {
      // Default to next hour, 1 hour duration
      final nextHour = DateTime(
        initialDate.year,
        initialDate.month,
        initialDate.day,
        now.hour + 1,
      );
      _startTime = nextHour;
      _endTime = nextHour.add(const Duration(hours: 1));
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
          // Auto-adjust end time if it's before start
          if (_endTime.isBefore(_startTime)) {
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
    final hour = time.hour == 0
        ? 12
        : time.hour > 12
            ? time.hour - 12
            : time.hour;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  void _save() {
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

    // TODO: Save task via repository/provider
    // For now, just pop and show success
    Navigator.of(context).pop();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_isEditing ? 'Task updated' : 'Task created'),
        behavior: SnackBarBehavior.floating,
      ),
    );
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
            onPressed: () {
              Navigator.of(context).pop(); // Close dialog
              Navigator.of(context).pop(); // Close detail screen
              // TODO: Delete via repository/provider
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Task deleted'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
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

            // Time selection row
            Row(
              children: [
                Expanded(
                  child: _TimePickerTile(
                    label: 'Start',
                    time: _formatTime(_startTime),
                    onTap: () => _selectTime(true),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _TimePickerTile(
                    label: 'End',
                    time: _formatTime(_endTime),
                    onTap: () => _selectTime(false),
                  ),
                ),
              ],
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
                DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                DropdownMenuItem(value: 'weekdays', child: Text('Weekdays')),
                DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
              ],
              onChanged: (value) {
                setState(() => _recurringPattern = value);
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
