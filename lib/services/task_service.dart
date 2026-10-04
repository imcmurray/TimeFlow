import 'package:timeflow/data/repositories/task_repository.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/domain/time/local_date.dart';
import 'package:timeflow/domain/time/wall_clock.dart';

/// Which occurrences of a repeating task an edit or delete applies to.
enum EditScope {
  /// Only the chosen occurrence.
  thisOnly,

  /// The chosen occurrence and every later one.
  thisAndFuture,

  /// Every occurrence, past and future.
  all,
}

/// User-level task operations, including how edits to a repeating task
/// split, update or override its series.
class TaskService {
  TaskService(this._repo, {DateTime Function()? clock})
      : _now = clock ?? DateTime.now;

  final TaskRepository _repo;
  final DateTime Function() _now;

  /// Saves a new task. A draft with a recurrence becomes a series.
  Future<Task> create(Task draft) async {
    final now = _now();
    final task = draft.copyWith(
      id: TaskRepository.newId(),
      seriesId: null,
      occurrenceDate: null,
      isVirtual: false,
      createdAt: now,
      updatedAt: now,
    );
    await _repo.upsert(task);
    return task;
  }

  /// Marks a task or occurrence done or not done.
  Future<void> setCompleted(Task task, bool completed) =>
      _saveOccurrence(task, task.copyWith(isCompleted: completed));

  /// Applies [edited] to [original].
  ///
  /// For a standalone task [scope] is ignored; giving it a recurrence turns
  /// it into a series. For an occurrence, [scope] decides what changes:
  /// - [EditScope.thisOnly] stores an override for that date (changes to the
  ///   recurrence are ignored);
  /// - [EditScope.thisAndFuture] ends the series the day before and starts a
  ///   new one from the edited occurrence;
  /// - [EditScope.all] edits the series itself.
  ///
  /// Field changes carry over to stored overrides that hadn't changed that
  /// field themselves, so renaming a series also renames its completed
  /// occurrences, while an individually edited title is kept.
  Future<void> update(Task original, Task edited, EditScope scope) async {
    if (!original.isOccurrence) {
      await _repo.upsert(edited.copyWith(
        id: original.id,
        seriesId: null,
        occurrenceDate: null,
        isCompleted: edited.recurrence != null ? false : edited.isCompleted,
        isVirtual: false,
        createdAt: original.createdAt,
        updatedAt: _now(),
      ));
      return;
    }

    final series = await _repo.getSeries(original.seriesId!);
    if (series == null) {
      // The series disappeared underneath us; keep the edit as a plain task.
      await _repo.upsert(edited.copyWith(
        id: original.isVirtual ? TaskRepository.newId() : original.id,
        recurrence: null,
        seriesId: null,
        occurrenceDate: null,
        isVirtual: false,
        updatedAt: _now(),
      ));
      return;
    }

    final date = original.occurrenceDate!;
    final seriesStart = LocalDate.of(series.startTime);
    if (scope == EditScope.all && edited.recurrence == null) {
      // "Stop repeating" for the whole series still keeps its history.
      scope = EditScope.thisAndFuture;
    }
    if (scope == EditScope.thisAndFuture && date == seriesStart) {
      scope = EditScope.all;
    }

    switch (scope) {
      case EditScope.thisOnly:
        await _saveOccurrence(
            original, edited.copyWith(recurrence: original.recurrence));

      case EditScope.all:
        await _repo.transaction(() async {
          final dayShift = LocalDate.of(original.startTime)
              .daysUntil(LocalDate.of(edited.startTime));
          final newStart = seriesStart
              .addDays(dayShift)
              .at(edited.startTime.hour, edited.startTime.minute);
          final newSeries = edited.copyWith(
            id: series.id,
            startTime: newStart,
            endTime: addWallMinutes(newStart, edited.durationMinutes),
            isCompleted: false,
            seriesId: null,
            occurrenceDate: null,
            isVirtual: false,
            createdAt: series.createdAt,
            updatedAt: _now(),
          );
          final baseOld = series;
          await _repo.upsert(newSeries);
          for (final o in await _repo.overridesOf(series.id)) {
            var task = _carryOver(o.task, baseOld, newSeries);
            if (dayShift != 0) {
              task = task.copyWith(
                startTime: addWallMinutes(task.startTime, dayShift * 1440),
                endTime: addWallMinutes(task.endTime, dayShift * 1440),
                occurrenceDate: task.occurrenceDate!.addDays(dayShift),
              );
            }
            await _repo.upsert(task, isCancelled: o.isCancelled);
          }
        });

      case EditScope.thisAndFuture:
        await _repo.transaction(() async {
          final oldRule = series.recurrence!;
          await _repo.upsert(series.copyWith(
            recurrence: oldRule.endingOn(date.addDays(-1)),
            updatedAt: _now(),
          ));
          final future = await _repo.overridesOf(series.id, from: date);

          if (edited.recurrence == null) {
            // Stop repeating: this occurrence becomes a plain task and the
            // later overrides go with the series.
            await _repo.deleteOverridesFrom(series.id, date);
            await _repo.upsert(edited.copyWith(
              id: original.isVirtual ? TaskRepository.newId() : original.id,
              seriesId: null,
              occurrenceDate: null,
              isVirtual: false,
              createdAt: _now(),
              updatedAt: _now(),
            ));
            return;
          }

          final newRule = edited.recurrence!.samePatternAs(oldRule)
              ? edited.recurrence!.copyWith(
                  until: oldRule.until, clearUntil: oldRule.until == null)
              : edited.recurrence!;
          final newSeries = edited.copyWith(
            id: TaskRepository.newId(),
            recurrence: newRule,
            isCompleted: false,
            seriesId: null,
            occurrenceDate: null,
            isVirtual: false,
            createdAt: _now(),
            updatedAt: _now(),
          );
          await _repo.upsert(newSeries);
          // The edited occurrence itself is now just the new series' first
          // occurrence, so its old override goes.
          await _repo.deleteOverridesFrom(series.id, date);
          if (edited.isCompleted) {
            final first = LocalDate.of(newSeries.startTime);
            await _repo.upsert(newSeries.copyWith(
              id: TaskRepository.newId(),
              isCompleted: true,
              seriesId: newSeries.id,
              occurrenceDate: first,
            ));
          }
          for (final o in future) {
            if (o.task.occurrenceDate == date) continue;
            await _repo.upsert(
              _carryOver(o.task, series, newSeries).copyWith(
                id: TaskRepository.newId(),
                seriesId: newSeries.id,
              ),
              isCancelled: o.isCancelled,
            );
          }
        });
    }
  }

  /// Deletes a task, or occurrences of a series according to [scope].
  Future<void> delete(Task task, EditScope scope) async {
    if (!task.isOccurrence) {
      if (task.recurrence != null) {
        await _repo.deleteSeries(task.id);
      } else {
        await _repo.delete(task.id);
      }
      return;
    }
    final series = await _repo.getSeries(task.seriesId!);
    if (series == null) {
      if (!task.isVirtual) await _repo.delete(task.id);
      return;
    }
    final date = task.occurrenceDate!;
    if (scope == EditScope.thisAndFuture &&
        date == LocalDate.of(series.startTime)) {
      scope = EditScope.all;
    }
    switch (scope) {
      case EditScope.thisOnly:
        await _repo.upsert(
          task.copyWith(
            id: task.isVirtual ? TaskRepository.newId() : task.id,
            isVirtual: false,
            updatedAt: _now(),
          ),
          isCancelled: true,
        );
      case EditScope.thisAndFuture:
        await _repo.transaction(() async {
          await _repo.upsert(series.copyWith(
            recurrence: series.recurrence!.endingOn(date.addDays(-1)),
            updatedAt: _now(),
          ));
          await _repo.deleteOverridesFrom(series.id, date);
        });
      case EditScope.all:
        await _repo.deleteSeries(series.id);
    }
  }

  /// Stores [updated] as the state of [occurrence]: an override for a
  /// series occurrence, or a plain save for anything else.
  Future<void> _saveOccurrence(Task occurrence, Task updated) {
    return _repo.upsert(updated.copyWith(
      id: occurrence.isVirtual ? TaskRepository.newId() : occurrence.id,
      seriesId: occurrence.seriesId,
      occurrenceDate: occurrence.occurrenceDate,
      isVirtual: false,
      updatedAt: _now(),
    ));
  }

  /// Applies the changes between [oldBase] and [newBase] to [target], except
  /// where [target] had already diverged from [oldBase] on that field.
  static Task _carryOver(Task target, Task oldBase, Task newBase) {
    T pick<T>(T t, T o, T n) => (o != n && t == o) ? n : t;

    var result = target.copyWith(
      title: pick(target.title, oldBase.title, newBase.title),
      description:
          pick(target.description, oldBase.description, newBase.description),
      notes: pick(target.notes, oldBase.notes, newBase.notes),
      isImportant:
          pick(target.isImportant, oldBase.isImportant, newBase.isImportant),
      reminderMinutes: pick(target.reminderMinutes, oldBase.reminderMinutes,
          newBase.reminderMinutes),
      attachmentPath: pick(target.attachmentPath, oldBase.attachmentPath,
          newBase.attachmentPath),
      color: pick(target.color, oldBase.color, newBase.color),
      category: pick(target.category, oldBase.category, newBase.category),
    );

    final oldTime = minuteOfDay(oldBase.startTime);
    final newTime = minuteOfDay(newBase.startTime);
    final oldLength = oldBase.durationMinutes;
    final newLength = newBase.durationMinutes;
    if (minuteOfDay(target.startTime) == oldTime &&
        target.durationMinutes == oldLength &&
        (oldTime != newTime || oldLength != newLength)) {
      final day = LocalDate.of(target.startTime);
      final start = day.at(0, newTime);
      result = result.copyWith(
          startTime: start, endTime: addWallMinutes(start, newLength));
    }
    return result;
  }
}
