import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/domain/beta_feedback_link.dart';

void main() {
  group('betaFeedbackUri', () {
    test('opens the report route with everything in the fragment', () {
      final uri = betaFeedbackUri(
        const BetaFeedbackContext(
          version: '1.1.0',
          buildNumber: '220',
          commit: '05cc31f',
          platform: 'Android Phone',
          os: 'Android 16',
          device: 'Google Pixel 8a',
        ),
      );

      expect(uri.origin, testerPortalOrigin);
      expect(uri.path, '/');
      expect(uri.query, isEmpty, reason: 'nothing may reach the server');
      expect(uri.fragment, startsWith('/report?'));

      final params = Uri.splitQueryString(uri.fragment.split('?').last);
      expect(params, {
        'app': 'TimeFlow',
        'version': '1.1.0',
        'build': '220',
        'commit': '05cc31f',
        'platform': 'Android Phone',
        'os': 'Android 16',
        'device': 'Google Pixel 8a',
      });
    });

    test('leaves out what the device would not say', () {
      final uri = betaFeedbackUri(
        const BetaFeedbackContext(
          version: '1.1.0',
          buildNumber: '220',
          commit: 'dev',
          platform: 'iOS (iPad)',
          os: '',
          device: '',
        ),
      );
      final params = Uri.splitQueryString(uri.fragment.split('?').last);
      expect(params.keys, isNot(contains('os')));
      expect(params.keys, isNot(contains('device')));
      expect(params['platform'], 'iOS (iPad)');
    });
  });

  group('portalPlatform', () {
    String of(String p, {bool tablet = false, bool web = false}) =>
        portalPlatform(targetPlatform: p, isWeb: web, isTablet: tablet);

    test('names phones and tablets the way the portal does', () {
      expect(of('android'), 'Android Phone');
      expect(of('android', tablet: true), 'Android Tablet');
      expect(of('iOS'), 'iOS (iPhone)');
      expect(of('iOS', tablet: true), 'iOS (iPad)');
      expect(of('macOS'), 'macOS');
      expect(of('linux'), 'Linux');
      expect(of('windows'), 'Windows');
      expect(of('android', web: true), 'Web (Desktop)');
      expect(of('fuchsia'), '');
    });
  });
}
