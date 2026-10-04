import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/domain/time/wall_clock.dart';
import 'package:timeflow/presentation/providers/task_provider.dart';
import 'package:timeflow/presentation/widgets/edit_scope_dialog.dart';
import 'package:timeflow/services/task_service.dart';

/// Task operations triggered from the UI, asking which occurrences a change
/// applies to when the task repeats.
class TaskActions {
  TaskActions(this._ref);

  final WidgetRef _ref;

  TaskService get _service => _ref.read(taskServiceProvider);

  Future<void> toggleComplete(Task task) async {
    await _service.setCompleted(task, !task.isCompleted);
    HapticFeedback.lightImpact();
  }

  /// Deletes [task], asking about the series for repeating ones. Shows an
  /// undo snackbar for single tasks and occurrences. Returns whether anything
  /// was deleted.
  Future<bool> delete(BuildContext context, Task task) async {
    var scope = EditScope.thisOnly;
    if (task.isRecurring) {
      final chosen = await showEditScopeDialog(context, verb: 'delete');
      if (chosen == null) return false;
      scope = chosen;
    }
    if (!context.mounted) return false;
    final messenger = ScaffoldMessenger.maybeOf(context);
    await _service.delete(task, scope);
    if (scope == EditScope.thisOnly && !task.isRecurring) {
      messenger?.showSnackBar(
        SnackBar(
          content: Text('Deleted "${task.title}"'),
          behavior: SnackBarBehavior.floating,
          action: SnackBarAction(
            label: 'Undo',
            onPressed: () => _ref.read(taskRepositoryProvider).upsert(task),
          ),
        ),
      );
    }
    return true;
  }

  /// Moves [task] to start at [newStart], keeping its length.
  Future<void> move(BuildContext context, Task task, DateTime newStart) async {
    if (newStart == task.startTime) return;
    var scope = EditScope.thisOnly;
    if (task.isRecurring) {
      final chosen = await showEditScopeDialog(context, verb: 'move');
      if (chosen == null) return;
      scope = chosen;
    }
    final moved = task.copyWith(
      startTime: newStart,
      endTime: addWallMinutes(newStart, task.durationMinutes),
    );
    await _service.update(task, moved, scope);
    HapticFeedback.lightImpact();
  }
}
