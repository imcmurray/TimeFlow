import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:timeflow/data/datasources/database.dart';
import 'package:timeflow/domain/entities/recurrence_rule.dart';
import 'package:timeflow/domain/entities/task.dart';

AppDatabase memoryDatabase() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  return AppDatabase(NativeDatabase.memory());
}

final _created = DateTime(2026, 1, 1);

Task draft(
  String title, {
  required DateTime start,
  int minutes = 60,
  RecurrenceRule? rule,
  int? reminder,
}) => Task(
  id: 'draft',
  title: title,
  startTime: start,
  endTime: start.add(Duration(minutes: minutes)),
  recurrence: rule,
  reminderMinutes: reminder,
  createdAt: _created,
  updatedAt: _created,
);
