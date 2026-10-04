import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'package:timeflow/domain/entities/task_category.dart';
import 'package:timeflow/domain/sharing/share_codec.dart';

Task t(String title, int hour, {String? notes, bool important = false}) {
  final c = DateTime(2026);
  return Task(
    id: title,
    title: title,
    startTime: DateTime(2026, 10, 5, hour, 30),
    endTime: DateTime(2026, 10, 5, hour + 1),
    notes: notes,
    isImportant: important,
    category: TaskCategory.health,
    createdAt: c,
    updatedAt: c,
  );
}

void main() {
  test('round-trips a schedule through a link', () {
    final schedule = SharedSchedule(
      title: "Biscuit's day",
      tasks: [
        t('Breakfast — ½ cup kibble', 7, notes: 'Pills are in the blue jar'),
        t('Walk 🐕', 12, important: true),
      ],
    );
    final link = ShareCodec.link(
      Uri.parse('https://imcmurray.github.io/TimeFlow/'),
      schedule,
    );
    expect(
      link.toString(),
      startsWith('https://imcmurray.github.io/TimeFlow/#/s/'),
    );

    final back = ShareCodec.fromFragment(link.fragment)!;
    expect(back.title, "Biscuit's day");
    expect(back.tasks.length, 2);
    final first = back.tasks.first;
    expect(first.title, 'Breakfast — ½ cup kibble');
    expect(first.startTime, DateTime(2026, 10, 5, 7, 30));
    expect(first.endTime, DateTime(2026, 10, 5, 8));
    expect(first.notes, 'Pills are in the blue jar');
    expect(first.category, TaskCategory.health);
    expect(back.tasks.last.isImportant, isTrue);
    expect(back.tasks.last.notes, isNull);
  });

  test('a busy day still makes a short link', () {
    final tasks = [for (var h = 6; h < 22; h++) t('Task number $h', h)];
    final data = ShareCodec.encode(SharedSchedule(tasks: tasks));
    expect(data.length, lessThan(1200));
  });

  test('ignores fragments that are not share links or are damaged', () {
    expect(ShareCodec.fromFragment(''), isNull);
    expect(ShareCodec.fromFragment('/settings'), isNull);
    expect(ShareCodec.fromFragment('/s/not-valid-data'), isNull);
  });
}
