import 'package:timeflow/domain/entities/task.dart';

/// A task's horizontal slot within its cluster.
class PlacedTask {
  final Task task;

  /// Zero-based column within the cluster.
  final int column;

  const PlacedTask(this.task, this.column);
}

/// A maximal group of tasks connected by overlaps. Tasks in a cluster share
/// the width of the timeline in [columns] columns.
class TaskCluster {
  final List<PlacedTask> placed;
  final int columns;
  final DateTime start;
  final DateTime end;

  const TaskCluster(this.placed, this.columns, this.start, this.end);

  List<Task> get tasks => [for (final p in placed) p.task];
}

/// Splits [tasks] into overlap clusters and gives each task the leftmost
/// column that's free at its start time, so no two overlapping tasks share a
/// column and a cluster uses as few columns as its busiest moment needs.
List<TaskCluster> layoutTasks(Iterable<Task> tasks) {
  final sorted = tasks.toList()
    ..sort((a, b) {
      final c = a.startTime.compareTo(b.startTime);
      if (c != 0) return c;
      // Longer first, so a short task nests beside a long one.
      final d = b.endTime.compareTo(a.endTime);
      return d != 0 ? d : a.id.compareTo(b.id);
    });

  final clusters = <TaskCluster>[];
  var current = <PlacedTask>[];
  var columnEnds = <DateTime>[];
  DateTime? clusterStart;
  DateTime? clusterEnd;

  void close() {
    if (current.isEmpty) return;
    clusters.add(
        TaskCluster(current, columnEnds.length, clusterStart!, clusterEnd!));
    current = [];
    columnEnds = [];
  }

  for (final task in sorted) {
    if (clusterEnd != null && !task.startTime.isBefore(clusterEnd)) close();
    if (current.isEmpty) {
      clusterStart = task.startTime;
      clusterEnd = task.endTime;
    } else if (task.endTime.isAfter(clusterEnd!)) {
      clusterEnd = task.endTime;
    }
    var column = columnEnds.indexWhere((end) => !end.isAfter(task.startTime));
    if (column < 0) {
      column = columnEnds.length;
      columnEnds.add(task.endTime);
    } else {
      columnEnds[column] = task.endTime;
    }
    current.add(PlacedTask(task, column));
  }
  close();
  return clusters;
}
