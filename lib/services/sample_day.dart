import 'package:timeflow/domain/entities/recurrence_rule.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/domain/entities/task_category.dart';
import 'package:timeflow/domain/time/local_date.dart';
import 'package:timeflow/domain/time/wall_clock.dart';
import 'package:timeflow/services/task_service.dart';

/// Fills today with a few example tasks around the current time, so a new
/// user sees the river moving straight away.
Future<void> addSampleDay(TaskService service, {DateTime? now}) async {
  final t = now ?? DateTime.now();
  // Round to the half hour so the examples line up with the grid.
  final base = DateTime(t.year, t.month, t.day, t.hour, t.minute < 30 ? 0 : 30);
  final created = DateTime.now();

  Task task(
    String title,
    int offsetMinutes,
    int minutes, {
    String category = TaskCategory.noneId,
    bool done = false,
    bool important = false,
    int? reminder,
    String? notes,
    RecurrenceRule? rule,
  }) => Task(
    id: 'sample',
    title: title,
    startTime: addWallMinutes(base, offsetMinutes),
    endTime: addWallMinutes(base, offsetMinutes + minutes),
    categoryId: category,
    isCompleted: done,
    isImportant: important,
    reminderMinutes: reminder,
    notes: notes,
    recurrence: rule,
    createdAt: created,
    updatedAt: created,
  );

  final vitaminsStart = LocalDate.of(base).at(8, 0);
  final samples = [
    task('Morning walk', -180, 45, category: 'health', done: true),
    task('Focus time', -60, 90, category: 'deepWork'),
    task(
      'Lunch with Sam',
      90,
      60,
      category: 'family',
      reminder: 15,
      notes: 'The café on 3rd Street',
    ),
    task(
      'Pick up groceries',
      210,
      30,
      category: 'personal',
      important: true,
      reminder: 10,
    ),
    Task(
      id: 'sample',
      title: 'Take vitamins',
      startTime: vitaminsStart,
      endTime: addWallMinutes(vitaminsStart, 15),
      categoryId: 'health',
      recurrence: RecurrenceRule.daily,
      createdAt: created,
      updatedAt: created,
    ),
  ];
  for (final s in samples) {
    await service.create(s);
  }
}
