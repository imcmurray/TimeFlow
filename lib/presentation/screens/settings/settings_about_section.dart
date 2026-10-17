import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeflow/build_info.dart';
import 'package:timeflow/core/app_links.dart';
import 'package:timeflow/core/plugins/plugin_state_provider.dart';
import 'package:timeflow/presentation/screens/plugin_marketplace_screen.dart';
import 'package:timeflow/presentation/screens/settings/section_header.dart';
import 'package:timeflow/services/background_breadcrumb.dart';

/// The app's version and build number, e.g. "1.0.0 (42)".
final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return '${info.version} (${info.buildNumber})';
});

/// How far the notification background isolate got, last time one ran.
final lastBackgroundActionProvider = FutureProvider<String?>(
  (ref) => BackgroundBreadcrumb.read(),
);

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

        // Beta builds only, and `betaFeedback` is const, so a store build
        // doesn't hide this — it doesn't contain it.
        if (betaFeedback) ...[
          const Divider(),
          const SectionHeader(title: 'Beta diagnostics'),
          ListTile(
            leading: const Icon(Icons.bug_report_outlined),
            title: const Text('Last reminder action'),
            subtitle: Text(
              ref
                      .watch(lastBackgroundActionProvider)
                      .maybeWhen(
                        data: (crumbs) => crumbs?.split('\n').last,
                        orElse: () => null,
                      ) ??
                  'Nothing recorded yet. Answer a reminder from the lock '
                      'screen with the app closed, then look here.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _showBreadcrumb(context, ref),
          ),
        ],
      ],
    );
  }

  /// What the background isolate wrote down, for a tester to read back to us.
  ///
  /// It exists because *Completed* on a lock-screen reminder didn't complete the
  /// task on a release build on a real iPhone, and passed on every simulator
  /// (TimeFlow#68). This is how a phone nobody can plug in says where it stops.
  void _showBreadcrumb(BuildContext context, WidgetRef ref) {
    ref.invalidate(lastBackgroundActionProvider);
    showDialog(
      context: context,
      builder: (context) => Consumer(
        builder: (context, ref, _) => AlertDialog(
          title: const Text('Last reminder action'),
          content: SingleChildScrollView(
            child: Text(
              ref
                      .watch(lastBackgroundActionProvider)
                      .maybeWhen(
                        data: (crumbs) => crumbs,
                        orElse: () => null,
                      ) ??
                  'Nothing recorded yet.\n\nThis fills in when a reminder is '
                      'answered from the notification while TimeFlow is '
                      'closed: each step the app reached, or the error it hit.',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () async {
                await BackgroundBreadcrumb.clear();
                ref.invalidate(lastBackgroundActionProvider);
              },
              child: const Text('Clear'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Close'),
            ),
          ],
        ),
      ),
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
