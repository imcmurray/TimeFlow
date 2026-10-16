import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:timeflow/build_info.dart';
import 'package:timeflow/domain/beta_access.dart';
import 'package:timeflow/services/beta_access_service.dart';

final betaAccessServiceProvider = Provider<BetaAccessService>(
  (ref) => BetaAccessService(),
);

/// Whether this build offers beta tester mode at all.
///
/// Beta mobile builds do, because that's what they're for. The web app does because it
/// can't carry a compile-time flag — it's one deployment serving everybody, and a toggle
/// nobody has a code for does nothing. iOS and Android **store** builds never do: a hidden
/// sign-in in a store build invites questions from App Review that we'd rather not invite,
/// and the answer "it's for testers" isn't visible from the outside.
bool get betaModeOffered => betaFeedback || kIsWeb;

/// Who this device is acting for, and how much they have left to do.
class BetaAccessNotifier extends AsyncNotifier<BetaAccess> {
  BetaAccessService get _service => ref.read(betaAccessServiceProvider);

  @override
  Future<BetaAccess> build() async {
    if (!betaModeOffered) return BetaAccess.disconnected;
    // The token's presence is the question, not a stored preference: Keychain items outlive
    // an app on iOS, so a reinstall that trusted a preference would show the toggle off
    // with a live token sitting behind it.
    final handle = await _service.readHandle();
    if (handle == null || handle.isEmpty) return BetaAccess.disconnected;
    return BetaAccess(handle: handle, summary: await _service.summary());
  }

  /// Paste a code from the round's announcement email.
  Future<String> connect(
    String code, {
    required String label,
    required String platform,
  }) async {
    final result = await _service.connect(
      code,
      label: label,
      platform: platform,
    );
    if (!result.ok) return result.error;
    state = AsyncData(
      BetaAccess(handle: result.handle, summary: await _service.summary()),
    );
    return '';
  }

  Future<void> disconnect() async {
    await _service.disconnect();
    state = const AsyncData(BetaAccess.disconnected);
  }

  /// Ask again for the count. Called when the app comes back to the foreground, never on a
  /// timer: the number changes when the tester does something in the portal, which is rare.
  Future<void> refresh() async {
    final current = state.value;
    if (current == null || !current.connected) return;
    final fresh = await _service.summary();
    // A null summary means we couldn't ask, not that there's nothing left. Keep what we had
    // unless the token turned out to be dead, which the service has already forgotten.
    if (fresh == null) {
      if ((await _service.readHandle())?.isEmpty ?? true) {
        state = const AsyncData(BetaAccess.disconnected);
      }
      return;
    }
    state = AsyncData(BetaAccess(handle: current.handle, summary: fresh));
  }
}

final betaAccessProvider =
    AsyncNotifierProvider<BetaAccessNotifier, BetaAccess>(
      BetaAccessNotifier.new,
    );
