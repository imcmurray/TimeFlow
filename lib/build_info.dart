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
