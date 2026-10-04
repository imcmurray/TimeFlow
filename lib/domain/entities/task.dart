import 'package:timeflow/domain/entities/recurrence_rule.dart';
import 'package:timeflow/domain/entities/task_category.dart';
import 'package:timeflow/domain/time/local_date.dart';
import 'package:timeflow/domain/time/wall_clock.dart';

/// A task on the timeline.
///
/// A Task is one of:
/// - a **standalone** task (`seriesId == null`, `recurrence == null`);
/// - a **series** definition (`recurrence != null`, `seriesId == null`). The
///   timeline never shows these directly, only their occurrences;
/// - an **occurrence** of a series (`seriesId != null`). Occurrences that
///   nobody has completed or edited are generated on the fly
///   ([isVirtual] is true, nothing is stored for them). Completing or editing
///   one stores it as an override for its [occurrenceDate].
///
/// Start and end are local wall-clock times.
class Task {
  final String id;
  final String title;
  final String? description;
  final DateTime startTime;
  final DateTime endTime;
  final bool isImportant;
  final bool isCompleted;

  /// Minutes before [startTime] to remind; null for no reminder.
  final int? reminderMinutes;
  final String? notes;

  /// Path of an attached photo inside the app's storage.
  final String? attachmentPath;

  /// Custom card color override (hex string).
  final String? color;
  final TaskCategory category;

  /// The repeat rule. Set on series definitions and copied onto their
  /// occurrences so the UI can say how a task repeats.
  final RecurrenceRule? recurrence;

  /// For occurrences: the id of the series they belong to.
  final String? seriesId;

  /// For occurrences: the date the series scheduled this occurrence on. Stays
  /// the same if the occurrence is later moved to another time or day.
  final LocalDate? occurrenceDate;

  /// True for an occurrence that is generated, not stored.
  final bool isVirtual;

  final DateTime createdAt;
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
    this.notes,
    this.attachmentPath,
    this.color,
    this.category = TaskCategory.none,
    this.recurrence,
    this.seriesId,
    this.occurrenceDate,
    this.isVirtual = false,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Whether this task belongs to a repeating series (as definition or occurrence).
  bool get isRecurring => recurrence != null || seriesId != null;

  /// Whether this is an occurrence of a series.
  bool get isOccurrence => seriesId != null;

  /// Length in wall-clock minutes.
  int get durationMinutes => wallMinutesBetween(startTime, endTime);

  Duration get duration => Duration(minutes: durationMinutes);

  /// Whether the task is happening at [now].
  bool isCurrentAt(DateTime now) =>
      !now.isBefore(startTime) && now.isBefore(endTime);

  bool get isCurrent => isCurrentAt(DateTime.now());
  bool get isUpcoming => DateTime.now().isBefore(startTime);
  bool get isPast => !DateTime.now().isBefore(endTime);

  /// When the reminder should fire, or null if there is no reminder.
  DateTime? get reminderTime => reminderMinutes == null
      ? null
      : addWallMinutes(startTime, -reminderMinutes!);

  static const _keep = Object();

  /// Returns a copy with the given fields replaced. Nullable fields can be
  /// cleared by passing null explicitly.
  Task copyWith({
    String? id,
    String? title,
    Object? description = _keep,
    DateTime? startTime,
    DateTime? endTime,
    bool? isImportant,
    bool? isCompleted,
    Object? reminderMinutes = _keep,
    Object? notes = _keep,
    Object? attachmentPath = _keep,
    Object? color = _keep,
    TaskCategory? category,
    Object? recurrence = _keep,
    Object? seriesId = _keep,
    Object? occurrenceDate = _keep,
    bool? isVirtual,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Task(
      id: id ?? this.id,
      title: title ?? this.title,
      description: identical(description, _keep)
          ? this.description
          : description as String?,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      isImportant: isImportant ?? this.isImportant,
      isCompleted: isCompleted ?? this.isCompleted,
      reminderMinutes: identical(reminderMinutes, _keep)
          ? this.reminderMinutes
          : reminderMinutes as int?,
      notes: identical(notes, _keep) ? this.notes : notes as String?,
      attachmentPath: identical(attachmentPath, _keep)
          ? this.attachmentPath
          : attachmentPath as String?,
      color: identical(color, _keep) ? this.color : color as String?,
      category: category ?? this.category,
      recurrence: identical(recurrence, _keep)
          ? this.recurrence
          : recurrence as RecurrenceRule?,
      seriesId:
          identical(seriesId, _keep) ? this.seriesId : seriesId as String?,
      occurrenceDate: identical(occurrenceDate, _keep)
          ? this.occurrenceDate
          : occurrenceDate as LocalDate?,
      isVirtual: isVirtual ?? this.isVirtual,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  /// Whether the user-visible content (everything except identity, series
  /// bookkeeping and timestamps) equals [other]'s.
  bool sameContentAs(Task other) =>
      title == other.title &&
      description == other.description &&
      startTime == other.startTime &&
      endTime == other.endTime &&
      isImportant == other.isImportant &&
      isCompleted == other.isCompleted &&
      reminderMinutes == other.reminderMinutes &&
      notes == other.notes &&
      attachmentPath == other.attachmentPath &&
      color == other.color &&
      category == other.category;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Task &&
          other.id == id &&
          other.seriesId == seriesId &&
          other.occurrenceDate == occurrenceDate &&
          other.recurrence == recurrence &&
          other.isVirtual == isVirtual &&
          other.updatedAt == updatedAt &&
          sameContentAs(other);

  @override
  int get hashCode => Object.hash(id, updatedAt, startTime, isCompleted);

  @override
  String toString() =>
      'Task($id, "$title", $startTime–$endTime${isVirtual ? ', virtual' : ''})';
}
