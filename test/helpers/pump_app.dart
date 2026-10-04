import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeflow/core/theme/app_theme.dart';
import 'package:timeflow/data/datasources/database.dart';
import 'package:timeflow/presentation/providers/clock_provider.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';
import 'package:timeflow/presentation/providers/task_provider.dart';

/// Pumps [home] in a MaterialApp backed by an in-memory database and mock
/// preferences. Returns the provider container for seeding and inspecting.
Future<ProviderContainer> pumpApp(
  WidgetTester tester,
  Widget home, {
  Map<String, Object> prefs = const {},
}) async {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  SharedPreferences.setMockInitialValues({
    'timeflow_first_launch': false,
    'timeflow_has_seen_longpress_hint': true,
    ...prefs,
  });
  final sharedPrefs = await SharedPreferences.getInstance();
  final db = AppDatabase(
    DatabaseConnection(
      NativeDatabase.memory(),
      closeStreamsSynchronously: true,
    ),
  );
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(sharedPrefs),
      deviceTimeZoneProvider.overrideWithValue('America/Denver'),
      appDatabaseProvider.overrideWithValue(db),
      // The real clock re-arms a timer every minute, which the test binding
      // would report as pending at the end of the test.
      minuteClockProvider.overrideWith((ref) => Stream.value(DateTime.now())),
    ],
  );
  addTearDown(() async {
    // Unmount first so timers and streams stop, then close the database.
    await tester.pumpWidget(const SizedBox());
    container.dispose();
    await tester.runAsync(db.close);
  });
  await tester.binding.setSurfaceSize(const Size(420, 900));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(theme: AppTheme.lightTheme, home: home),
    ),
  );
  return container;
}

/// Lets database work and the stream updates it triggers finish.
Future<void> settle(WidgetTester tester) async {
  for (var i = 0; i < 5; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 20)),
    );
    await tester.pump(const Duration(milliseconds: 50));
  }
}
