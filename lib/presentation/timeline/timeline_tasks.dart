import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/presentation/providers/task_provider.dart';

/// True for timelines nobody can edit (a schedule someone shared): no
/// creating, moving, completing or deleting; tapping shows details.
final timelineReadOnlyProvider = Provider<bool>((ref) => false);

/// The block of days whose tasks are loaded while [visible] is on screen:
/// whole weeks with a week of margin either side, so scrolling only reloads
/// when crossing into another week.
DayRange taskWindowFor(DayRange visible) => DayRange(
  visible.first.startOfWeek.addDays(-7),
  visible.last.startOfWeek.addDays(13),
);

/// Watches the tasks for the window around [visible], falling back to
/// [previous] while a newly entered window loads so cards don't flicker.
List<Task> watchTimelineTasks(
  WidgetRef ref,
  DayRange visible,
  List<Task> previous,
) {
  return ref.watch(tasksInRangeProvider(taskWindowFor(visible))).value ??
      previous;
}
