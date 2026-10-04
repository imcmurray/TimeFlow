import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/presentation/screens/settings/settings_appearance_section.dart';
import 'package:timeflow/presentation/screens/settings/settings_location_section.dart';
import 'package:timeflow/presentation/screens/settings/settings_task_creation_section.dart';
import 'package:timeflow/presentation/screens/settings/settings_notifications_section.dart';
import 'package:timeflow/presentation/screens/settings/settings_data_section.dart';
import 'package:timeflow/presentation/screens/settings/settings_about_section.dart';

/// Settings screen for app preferences and customization.
///
/// Allows users to configure theme, notifications, timeline density,
/// and other preferences.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: const [
          SettingsAppearanceSection(),
          Divider(),
          SettingsLocationSection(),
          Divider(),
          SettingsTaskCreationSection(),
          Divider(),
          SettingsNotificationsSection(),
          Divider(),
          SettingsDataSection(),
          Divider(),
          SettingsAboutSection(),
        ],
      ),
    );
  }
}
