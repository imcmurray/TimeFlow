/// Domain entity representing a Task in TimeFlow.
///
/// Tasks are the core data model, representing scheduled activities
/// that flow through the timeline.
class Task {
  /// Unique identifier for the task.
  final String id;

  /// Task name/title.
  final String title;

  /// Optional detailed description.
  final String? description;

  /// Task start time.
  final DateTime startTime;

  /// Task end time.
  final DateTime endTime;

  /// Whether this task is marked as important/high priority.
  final bool isImportant;

  /// Whether the task has been completed.
  final bool isCompleted;

  /// Minutes before task to trigger reminder notification.
  /// Null if no reminder is set.
  final int? reminderMinutes;

  /// Recurrence rule string (e.g., 'daily', 'weekly', null for one-time).
  final String? recurringPattern;

  /// Template ID linking recurring task instances together.
  /// Null for non-recurring tasks. For recurring tasks, all instances
  /// share the same templateId to enable "edit all" functionality.
  final String? recurringTemplateId;

  /// Additional notes for the task.
  final String? notes;

  /// Local path to an attached file/photo.
  final String? attachmentPath;

  /// Custom color override for the task card (hex string).
  final String? color;

  /// Timestamp when the task was created.
  final DateTime createdAt;

  /// Timestamp when the task was last updated.
  final DateTime updatedAt;

  const Task({
    required this.id,
    required this.title,
    this.description,
    required this.startTime,
    required this.endTime,
    this.isImportant = false,
    this.isCompleted = false,
    this.reminderMinutes,
    this.recurringPattern,
    this.recurringTemplateId,
    this.notes,
    this.attachmentPath,
    this.color,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Duration of the task.
  Duration get duration => endTime.difference(startTime);

  /// Whether the task is currently active (now is between start and end).
  bool get isCurrent {
    final now = DateTime.now();
    return now.isAfter(startTime) && now.isBefore(endTime);
  }

  /// Whether the task is in the future.
  bool get isUpcoming => DateTime.now().isBefore(startTime);

  /// Whether the task is in the past.
  bool get isPast => DateTime.now().isAfter(endTime);

  /// Creates a copy of this task with the given fields replaced.
  Task copyWith({
    String? id,
    String? title,
    String? description,
    DateTime? startTime,
    DateTime? endTime,
    bool? isImportant,
    bool? isCompleted,
    int? reminderMinutes,
    String? recurringPattern,
    String? recurringTemplateId,
    String? notes,
    String? attachmentPath,
    String? color,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isImportant: isImportant ?? this.isImportant,
      isCompleted: isCompleted ?? this.isCompleted,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      recurringPattern: recurringPattern ?? this.recurringPattern,
      recurringTemplateId: recurringTemplateId ?? this.recurringTemplateId,
      notes: notes ?? this.notes,
      attachmentPath: attachmentPath ?? this.attachmentPath,
      color: color ?? this.color,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Task && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Task(id: $id, title: $title, startTime: $startTime, endTime: $endTime)';
  }
}
