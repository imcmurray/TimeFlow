import 'package:flutter/foundation.dart' show kIsWeb;

// Build metadata, injected at build time with --dart-define, e.g.
//   flutter build apk --dart-define=GIT_COMMIT=$(git rev-parse --short HEAD)
// Local builds without the defines report 'dev'.

const String gitCommitHash = String.fromEnvironment(
  'GIT_COMMIT',
  defaultValue: 'dev',
);
const String buildTimestamp = String.fromEnvironment(
  'BUILD_TIME',
  defaultValue: 'dev',
);

// Beta builds for tester rounds (TIMEFLOW_BETA=1 ./scripts/build_flags.sh)
// show a Feedback button that opens the tester portal. Store builds don't.
const bool betaFeedback = bool.fromEnvironment('BETA_FEEDBACK');

/// Whether this build offers beta tester mode: the Settings → Beta testing section, the
/// device token, and the two buttons that follow from it.
///
/// Beta builds do, because that's what they're for. The web app does because it can't
/// carry a compile-time flag — it's one deployment serving everybody, and a toggle nobody
/// has a code for does nothing. iOS and Android **store** builds never do: a hidden
/// sign-in in a store build invites App Review questions we'd rather not invite.
///
/// **It is `const`, and every reference to beta mode sits behind it**, so a store build
/// doesn't merely hide the feature — the compiler removes it, down to the portal's
/// hostname. Make this a getter and the strings come back: that is how
/// `testers.rinserepeatlabs.com` ended up inside the 1.1.2 store APK.
const bool betaModeOffered = betaFeedback || kIsWeb;
