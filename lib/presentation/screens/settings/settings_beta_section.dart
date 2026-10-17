import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/domain/beta_access.dart';
import 'package:timeflow/build_info.dart';
import 'package:timeflow/presentation/providers/beta_access_provider.dart';
import 'package:timeflow/presentation/screens/settings/section_header.dart';
import 'package:timeflow/services/beta_feedback.dart';

/// Beta testing: paste the code from the round's email and this device can see the
/// tester's tasks and send findings without signing in to the portal first.
///
/// A store build never reaches this widget: [betaModeOffered] is `const`, so the one
/// reference to it is dropped at compile time along with everything it leads to. The guard
/// below is belt and braces for anyone who calls it directly.
class SettingsBetaSection extends ConsumerWidget {
  const SettingsBetaSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!betaModeOffered) return const SizedBox.shrink();
    final access =
        ref.watch(betaAccessProvider).value ?? BetaAccess.disconnected;

    return Column(
      children: [
        const SectionHeader(title: 'Beta testing'),
        if (!access.connected)
          ListTile(
            leading: const Icon(Icons.vpn_key_outlined),
            title: const Text('Connect this device'),
            subtitle: const Text(
              'Paste the RRL- code from the email about this round. '
              'It works once, on the first device you use it on.',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _connect(context, ref),
          )
        else ...[
          ListTile(
            leading: const Icon(Icons.verified_user_outlined),
            title: Text('Connected as ${access.handle}'),
            subtitle: Text(_whatIsLeft(access)),
          ),
          ListTile(
            leading: const Icon(Icons.link_off),
            title: const Text('Disconnect this device'),
            subtitle: const Text(
              'Tells the portal to drop this device and forgets the code. '
              'The portal still lets you in by email.',
            ),
            onTap: () => _disconnect(context, ref),
          ),
        ],
      ],
    );
  }

  /// Say which round the number belongs to. The badge adds up every open round this app
  /// has for the tester, so a bare "5 tasks left" in front of a page that opens one round
  /// and says "Task 1 of 6" is a number with nowhere to go.
  String _whatIsLeft(BetaAccess access) {
    final summary = access.summary;
    if (summary == null) {
      return 'Tasks and Feedback are on. Tap Tasks to see what’s left.';
    }
    if (summary.needsAgreement && summary.tasksTotal == 0) {
      return 'There’s an agreement to read in the portal before this round opens up.';
    }
    final left = summary.tasksLeft;
    if (left == 0) return 'Nothing left to do — thank you.';
    final tasks = left == 1 ? '1 task left' : '$left tasks left';
    final rounds = summary.roundsWithWork;
    if (rounds.length == 1 && rounds.single.name.isNotEmpty) {
      return '$tasks in ${rounds.single.name}.';
    }
    if (rounds.length > 1) return '$tasks across ${rounds.length} rounds.';
    return '$tasks of ${summary.tasksTotal}.';
  }

  Future<void> _connect(BuildContext context, WidgetRef ref) async {
    final code = await showDialog<String>(
      context: context,
      builder: (_) => const _CodeDialog(),
    );
    if (code == null || code.isEmpty || !context.mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    final isTablet = MediaQuery.sizeOf(context).shortestSide >= 600;
    final platform = await betaPlatformName(isTablet: isTablet);
    final error = await ref
        .read(betaAccessProvider.notifier)
        .connect(
          code,
          label: 'TimeFlow${platform.isEmpty ? '' : ' on $platform'}',
          platform: platform,
        );
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          error.isEmpty
              ? 'Connected. Tasks and Feedback are in the top bar.'
              : error,
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _disconnect(BuildContext context, WidgetRef ref) async {
    final messenger = ScaffoldMessenger.of(context);
    await ref.read(betaAccessProvider.notifier).disconnect();
    messenger.showSnackBar(
      const SnackBar(
        content: Text('Disconnected. The portal still signs you in by email.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// A plain text field, and nothing else.
///
/// Deliberately no "Paste" button: on iOS a button that reads the clipboard raises the
/// system's "Allow Paste?" alert every single time, while the ordinary long-press paste
/// doesn't. Autocorrect off, because it mangles a code.
class _CodeDialog extends StatefulWidget {
  const _CodeDialog();

  @override
  State<_CodeDialog> createState() => _CodeDialogState();
}

class _CodeDialogState extends State<_CodeDialog> {
  final _controller = TextEditingController();
  bool _valid = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Your beta code'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'It looks like RRL-7K2P-9QRM-4T8X-2WYE, in the email about this round.',
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _controller,
            autofocus: true,
            autocorrect: false,
            enableSuggestions: false,
            textCapitalization: TextCapitalization.characters,
            decoration: const InputDecoration(
              labelText: 'Beta code',
              hintText: 'RRL-XXXX-XXXX-XXXX-XXXX',
            ),
            onChanged: (value) =>
                setState(() => _valid = looksLikeBetaCode(value)),
            onSubmitted: (value) {
              if (looksLikeBetaCode(value)) Navigator.of(context).pop(value);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _valid
              ? () => Navigator.of(context).pop(_controller.text)
              : null,
          child: const Text('Connect'),
        ),
      ],
    );
  }
}
