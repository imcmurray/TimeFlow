import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/domain/entities/task.dart';
import 'dart:convert';

import 'package:archive/archive.dart';
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
    categoryId: 'health',
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
    expect(first.categoryId, 'health');
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

  group('categories', () {
    const errands = TaskCategory(
      id: 'c-123',
      name: 'Errands',
      icon: 'shopping_cart',
      colorValue: 0xFFFFCA28,
    );
    final mine = [
      ...builtInCategories.map(
        (c) => c.id == 'family' ? c.copyWith(name: 'Kids') : c,
      ),
      errands,
    ];
    Task with_(String title, String category) =>
        t(title, 9).copyWith(categoryId: category);

    List<dynamic> rawRows(String data) {
      final padded = data.padRight((data.length + 3) ~/ 4 * 4, '=');
      final json = utf8.decode(
        const ZLibDecoder().decodeBytes(base64Url.decode(padded)),
      );
      return (jsonDecode(json) as Map<String, dynamic>)['t'] as List;
    }

    test('custom and edited categories travel with the link', () {
      final data = ShareCodec.encode(
        SharedSchedule(
          tasks: [
            with_('Groceries', errands.id),
            with_('School run', 'family'),
            with_('Run', 'health'),
          ],
          categories: mine,
        ),
      );
      final back = ShareCodec.decode(data);
      final lookup = {for (final c in back.categories) c.id: c};
      final groceries = lookup[back.tasks[0].categoryId]!;
      expect(groceries.name, 'Errands');
      expect(groceries.icon, 'shopping_cart');
      expect(groceries.colorValue, 0xFFFFCA28);
      expect(lookup[back.tasks[1].categoryId]!.name, 'Kids');
      // An unchanged built-in is sent by index alone.
      expect(back.tasks[2].categoryId, 'health');
      expect(lookup['health']!.name, 'Health');
    });

    test('links stay readable by versions before 1.1', () {
      final rows = rawRows(
        ShareCodec.encode(
          SharedSchedule(
            tasks: [with_('Groceries', errands.id), with_('Run', 'health')],
            categories: mine,
          ),
        ),
      );
      // Old versions read the built-in index at [4] (-1 shows as None) and
      // ignore anything after [6].
      expect(rows[0][4], -1);
      expect(rows[1][4], legacyCategoryOrder.indexOf('health'));
      expect(rows[1].length, 7);
    });
  });
}
