// Build metadata, injected at build time with --dart-define, e.g.
//   flutter build apk --dart-define=GIT_COMMIT=$(git rev-parse --short HEAD)
// Local builds without the defines report 'dev'.

const String gitCommitHash =
    String.fromEnvironment('GIT_COMMIT', defaultValue: 'dev');
const String buildTimestamp =
    String.fromEnvironment('BUILD_TIME', defaultValue: 'dev');
