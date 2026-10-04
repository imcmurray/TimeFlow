import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:timeflow/build_info.dart';
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
        // About
        const SectionHeader(title: 'About'),
        ListTile(
          leading: const Icon(Icons.info_outline),
          title: const Text('TimeFlow'),
          subtitle: Text(ref.watch(appVersionProvider).maybeWhen(
                data: (v) => 'Version $v',
                orElse: () => 'Version',
              )),
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
          onTap: () => _showPrivacyPolicyDialog(context),
        ),
        ListTile(
          leading: const Icon(Icons.article_outlined),
          title: const Text('Terms of Service'),
          onTap: () => _showTermsOfServiceDialog(context),
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
              onTap: () => launchUrl(
                Uri.parse('https://github.com/imcmurray/TimeFlow/issues'),
              ),
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

  void _showPrivacyPolicyDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Privacy Policy'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Last updated: January 2026\n'),
              const Text(
                'TimeFlow Privacy Policy\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                'TimeFlow is designed with your privacy in mind. '
                'Here\'s what you need to know:\n',
              ),
              const Text(
                'Data Storage',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                '• All your tasks and settings are stored locally on your device\n'
                '• We do not collect, transmit, or store any personal data on external servers\n'
                '• Your data remains entirely under your control\n',
              ),
              const Text(
                'Permissions',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                '• Notifications: Used only to remind you of upcoming tasks\n'
                '• No other permissions are required\n',
              ),
              const Text(
                'Third Parties',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                '• TimeFlow does not share any data with third parties\n'
                '• No analytics or tracking services are used\n',
              ),
              const Text(
                'Contact',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('For privacy questions, visit our '),
              Builder(
                builder: (context) => InkWell(
                  onTap: () => launchUrl(
                    Uri.parse('https://github.com/imcmurray/TimeFlow'),
                  ),
                  child: Text(
                    'GitHub repository',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
            ],
          ),
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

  void _showTermsOfServiceDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Terms of Service'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Last updated: January 2026\n'),
              const Text(
                'Terms of Service\n',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('By using TimeFlow, you agree to these terms:\n'),
              const Text(
                'Use of Service',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                '• TimeFlow is provided "as is" without warranties\n'
                '• You are responsible for your own task data\n'
                '• The app is free to use for personal purposes\n',
              ),
              const Text(
                'Limitations',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text(
                '• We are not liable for any data loss\n'
                '• We reserve the right to update the app and these terms\n',
              ),
              const Text(
                'Open Source',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('• TimeFlow is open source software'),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('• Contributions are welcome via '),
                  Builder(
                    builder: (context) => InkWell(
                      onTap: () => launchUrl(
                        Uri.parse('https://github.com/imcmurray/TimeFlow'),
                      ),
                      child: Text(
                        'GitHub',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
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
