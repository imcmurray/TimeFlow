import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/core/theme/app_theme.dart';
import 'package:timeflow/presentation/providers/settings_provider.dart';
import 'package:timeflow/presentation/screens/timeline_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const ProviderScope(
      child: TimeFlowApp(),
    ),
  );
}

/// The main TimeFlow application widget.
///
/// TimeFlow transforms daily scheduling into a flowing river of time,
/// where tasks automatically scroll past a fixed "NOW" line as real
/// minutes pass.
class TimeFlowApp extends ConsumerWidget {
  const TimeFlowApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeSetting = ref.watch(settingsProvider).theme;
    final themeMode = switch (themeSetting) {
      'light' => ThemeMode.light,
      'dark' => ThemeMode.dark,
      _ => ThemeMode.system,
    };

    return MaterialApp(
      title: 'TimeFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const TimelineScreen(),
    );
  }
}
