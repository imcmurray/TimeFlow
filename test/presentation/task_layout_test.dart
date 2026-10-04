import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/presentation/timeline/task_layout.dart';

Task t(String id, int startHour, int endHour, {int startMin = 0}) {
  final c = DateTime(2026);
  return Task(
    id: id,
    title: id,
    startTime: DateTime(2026, 6, 1, startHour, startMin),
    endTime: DateTime(2026, 6, 1, endHour),
    createdAt: c,
    updatedAt: c,
  );
}

Map<String, int> columns(TaskCluster c) =>
    {for (final p in c.placed) p.task.id: p.column};

void main() {
  test('separate tasks get their own single-column clusters', () {
    final clusters = layoutTasks([t('a', 9, 10), t('b', 10, 11)]);
    expect(clusters.length, 2);
    expect(clusters.every((c) => c.columns == 1), isTrue);
  });

  test('a task bridging two others joins one cluster', () {
    // The old grouping put c in a's group only, letting b and c overlap.
    final clusters = layoutTasks(
        [t('a', 9, 10), t('b', 11, 12), t('c', 9, 12, startMin: 30)]);
    expect(clusters.length, 1);
    final cl = clusters.single;
    expect(cl.columns, 2);
    expect(columns(cl), {'a': 0, 'c': 1, 'b': 0});
  });

  test('columns are reused once free', () {
    final cl = layoutTasks([
      t('long', 9, 13),
      t('x', 9, 10),
      t('y', 10, 11),
      t('z', 11, 12),
    ]).single;
    expect(cl.columns, 2);
    expect(columns(cl), {'long': 0, 'x': 1, 'y': 1, 'z': 1});
  });

  test('three-way overlap needs three columns', () {
    final cl =
        layoutTasks([t('a', 9, 12), t('b', 10, 12), t('c', 11, 12)]).single;
    expect(cl.columns, 3);
  });

  test('cluster bounds', () {
    final cl = layoutTasks([t('a', 9, 10), t('b', 9, 14)]).single;
    expect(cl.start, DateTime(2026, 6, 1, 9));
    expect(cl.end, DateTime(2026, 6, 1, 14));
  });
}
