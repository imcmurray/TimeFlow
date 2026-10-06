import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeflow/build_info.dart';
import 'package:timeflow/core/app_links.dart';
import 'package:timeflow/core/plugins/plugin_state_provider.dart';
import 'package:timeflow/presentation/screens/plugin_marketplace_screen.dart';
import 'package:timeflow/presentation/screens/settings/section_header.dart';

/// The app's version and build number, e.g. "1.0.0 (42)".
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
});

/// About settings: app info, support, legal.
class SettingsAboutSection extends ConsumerWidget {
  const SettingsAboutSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const SectionHeader(title: 'Plugins'),
        ListTile(
          leading: const Icon(Icons.extension_outlined),
          title: const Text('Plugin marketplace'),
          subtitle: Text(switch (ref.watch(enabledPluginsProvider).length) {
            0 => 'Add more to your river: scheduled jobs, quotes…',
            1 => '1 plugin on',
            final n => '$n plugins on',
          }),
          trailing: const Icon(Icons.chevron_right),
          onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const PluginMarketplaceScreen()),
          ),
        ),
        const Divider(),

        // About
        const SectionHeader(title: 'About'),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('TimeFlow'),
          subtitle: Text(
            ref
                .watch(appVersionProvider)
                .maybeWhen(data: (v) => 'Version $v', orElse: () => 'Version'),
          ),
          onTap: () => _showAboutInfoDialog(context, ref),
        ),
        ListTile(
          leading: const Icon(Icons.help_outline),
          title: const Text('Support'),
          subtitle: const Text('Get help & report issues'),
          onTap: () => _showSupportDialog(context),
        ),
        ListTile(
          leading: const Icon(Icons.description_outlined),
          title: const Text('Privacy Policy'),
          subtitle: const Text('Your tasks never leave your device'),
          onTap: () => launchUrl(Uri.parse(privacyPolicyUrl)),
        ),
        ListTile(
          leading: const Icon(Icons.article_outlined),
          title: const Text('Open-source licenses'),
          onTap: () => showLicensePage(
            context: context,
            applicationName: 'TimeFlow',
            applicationVersion: ref.read(appVersionProvider).value,
          ),
        ),
      ],
    );
  }

  void _showAboutInfoDialog(BuildContext context, WidgetRef ref) {
    showAboutDialog(
      context: context,
      applicationName: 'TimeFlow',
      applicationVersion: ref.read(appVersionProvider).value ?? '',
      applicationIcon: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.asset(
          'assets/images/timeflow-logo.png',
          width: 64,
          height: 64,
        ),
      ),
      children: [
        const SizedBox(height: 16),
        const Text(
          'Experience time as a gentle flowing river, not a pressure cooker.',
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 16),
        const Text(
          'TimeFlow transforms daily scheduling into a calming visual experience '
          'where your day flows naturally past the NOW line.',
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Future<void> _showSupportDialog(BuildContext context) async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Version: ${packageInfo.version}'),
            Text('Build: $gitCommitHash ($buildTimestamp)'),
            const SizedBox(height: 16),
            const Text('Need help or found a bug?'),
            const SizedBox(height: 8),
            InkWell(
              onTap: () => launchUrl(Uri.parse(supportUrl)),
              child: Text(
                'View or create issues on GitHub',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
