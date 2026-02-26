import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cron_timeflow/core/plugins/plugin_providers.dart';
import 'package:cron_timeflow/core/plugins/plugin_registry.dart';
import 'package:cron_timeflow/core/theme/app_theme.dart';
import 'package:cron_timeflow/plugins/server_flow/server_flow_plugin.dart';
import 'package:cron_timeflow/plugins/weather_flow/weather_flow_plugin.dart';
import 'package:cron_timeflow/plugins/quote_flow/quote_flow_plugin.dart';
import 'package:cron_timeflow/presentation/providers/settings_provider.dart';
import 'package:cron_timeflow/presentation/screens/onboarding_screen.dart';
import 'package:cron_timeflow/presentation/screens/timeline_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final registry = PluginRegistry();
  final plugins = [
    ServerFlowPlugin(),
    WeatherFlowPlugin(),
    QuoteFlowPlugin(),
  ];

  for (final plugin in plugins) {
    registry.register(plugin);
    await plugin.initialize();
  }

  runApp(
    ProviderScope(
      overrides: [
        pluginRegistryProvider.overrideWithValue(registry),
      ],
      child: const TimeFlowApp(),
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

    final settings = ref.watch(settingsProvider);

    return MaterialApp(
      title: 'TimeFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: settings.firstLaunch
          ? const OnboardingScreen()
          : const TimelineScreen(),
    );
  }
}
