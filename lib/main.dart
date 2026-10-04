import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeflow/core/device_time_zone.dart';
import 'package:timeflow/core/theme/app_theme.dart';
import 'package:timeflow/data/migrations/legacy_web_storage.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';
import 'package:timeflow/presentation/providers/task_provider.dart';
import 'package:timeflow/domain/sharing/share_codec.dart';
import 'package:timeflow/presentation/screens/onboarding_screen.dart';
import 'package:timeflow/presentation/screens/shared_schedule_screen.dart';
import 'package:timeflow/presentation/screens/task_detail_screen.dart';
import 'package:timeflow/presentation/screens/timeline_screen.dart';
import 'package:timeflow/services/reminder_coordinator.dart';

final _navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final timeZone = await deviceTimeZone();
  final container = ProviderContainer(
    overrides: [
      sharedPreferencesProvider.overrideWithValue(prefs),
      deviceTimeZoneProvider.overrideWithValue(timeZone),
    ],
  );
  final repository = container.read(taskRepositoryProvider);
  await migrateLegacyWebStorage(repository);
  // Photos removed from tasks (or whose tasks were deleted) are cleaned up
  // once per launch.
  unawaited(repository.pruneAttachments());
  // Reminders start after the first frame so a notification that launched
  // the app can navigate.
  WidgetsBinding.instance.addPostFrameCallback((_) {
    container
        .read(reminderCoordinatorProvider)
        .start(
          openTask: (task) => _navigatorKey.currentState?.push(
            MaterialPageRoute(builder: (_) => TaskDetailScreen(task: task)),
          ),
        );
  });
  runApp(
    UncontrolledProviderScope(container: container, child: const TimeFlowApp()),
  );
}

/// TimeFlow: your day as a river flowing past a fixed NOW line.
class TimeFlowApp extends ConsumerWidget {
  const TimeFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(settingsProvider.select((s) => s.theme));
    final firstLaunch = ref.watch(
      settingsProvider.select((s) => s.firstLaunch),
    );

    // A share link (web only: #/s/...) opens the shared schedule instead.
    final shared = kIsWeb ? ShareCodec.fromFragment(Uri.base.fragment) : null;

    return MaterialApp(
      title: 'TimeFlow',
      navigatorKey: _navigatorKey,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: switch (theme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      home: shared != null
          ? SharedScheduleScreen(schedule: shared)
          : firstLaunch
          ? const OnboardingScreen()
          : const TimelineScreen(),
    );
  }
}
