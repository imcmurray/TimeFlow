/// The tester portal link behind the beta Feedback button.
///
/// It opens the portal's report form for the tester's current TimeFlow round,
/// already filled in with what the build and device are. Everything rides in
/// the URL fragment, so none of it reaches the portal's server or its logs
/// until the tester signs in and sends the finding themselves.
const String testerPortalOrigin = 'https://testers.rinserepeatlabs.com';

/// The app name the portal knows TimeFlow by; it picks the round from it.
const String testerPortalAppName = 'TimeFlow';

/// What the portal is told about the build and the device in hand.
class BetaFeedbackContext {
  const BetaFeedbackContext({
    required this.version,
    required this.buildNumber,
    required this.commit,
    required this.platform,
    required this.os,
    required this.device,
  });

  final String version;
  final String buildNumber;
  final String commit;

  /// One of the portal's platform names, e.g. `Android Phone`, `iOS (iPad)`.
  final String platform;

  /// e.g. `Android 16`, `iOS 26.0`.
  final String os;

  /// e.g. `Google Pixel 8a`, `iPhone 16 Pro`.
  final String device;
}

/// The portal's platform name for a device: phones and tablets apart, by the
/// same 600 dp shortest side Flutter's own adaptive layouts use.
String portalPlatform({
  required String targetPlatform,
  required bool isWeb,
  required bool isTablet,
}) {
  if (isWeb) return 'Web (Desktop)';
  switch (targetPlatform) {
    case 'android':
      return isTablet ? 'Android Tablet' : 'Android Phone';
    case 'iOS':
      return isTablet ? 'iOS (iPad)' : 'iOS (iPhone)';
    case 'macOS':
      return 'macOS';
    case 'windows':
      return 'Windows';
    case 'linux':
      return 'Linux';
    default:
      return '';
  }
}

Uri betaFeedbackUri(BetaFeedbackContext c) {
  final params = <String, String>{
    'app': testerPortalAppName,
    'version': c.version,
    'build': c.buildNumber,
    'commit': c.commit,
    'platform': c.platform,
    'os': c.os,
    'device': c.device,
  }..removeWhere((_, value) => value.isEmpty);
  final query = Uri(queryParameters: params).query;
  return Uri.parse('$testerPortalOrigin/#/report?$query');
}
