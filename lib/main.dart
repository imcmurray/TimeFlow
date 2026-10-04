import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeflow/core/theme/app_theme.dart';
import 'package:timeflow/data/migrations/legacy_web_storage.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';
import 'package:timeflow/presentation/providers/task_provider.dart';
import 'package:timeflow/presentation/screens/onboarding_screen.dart';
import 'package:timeflow/presentation/screens/timeline_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final container = ProviderContainer(
    overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
  );
  await migrateLegacyWebStorage(container.read(taskRepositoryProvider));
  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const TimeFlowApp(),
    ),
  );
}

/// TimeFlow: your day as a river flowing past a fixed NOW line.
class TimeFlowApp extends ConsumerWidget {
  const TimeFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(settingsProvider.select((s) => s.theme));
    final firstLaunch =
        ref.watch(settingsProvider.select((s) => s.firstLaunch));

    return MaterialApp(
      title: 'TimeFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: switch (theme) {
        'light' => ThemeMode.light,
        'dark' => ThemeMode.dark,
        _ => ThemeMode.system,
      },
      home: firstLaunch ? const OnboardingScreen() : const TimelineScreen(),
    );
  }
}
