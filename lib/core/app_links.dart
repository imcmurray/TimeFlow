import 'package:flutter/foundation.dart';

/// Where the TimeFlow web app is published. Share links point here, so
/// people without the app can open them in a browser.
const publishedWebAppUrl = 'https://imcmurray.github.io/TimeFlow/';

/// Public pages linked from the app.
const privacyPolicyUrl = '${publishedWebAppUrl}privacy.html';
const supportUrl = 'https://github.com/imcmurray/TimeFlow/issues';

/// The web app address share links should use: the one the user is on when
/// running in a browser (so self-hosted copies share their own links), or
/// the published one.
Uri webAppUrl() {
  if (kIsWeb) return Uri.base.removeFragment().replace(query: '');
  return Uri.parse(publishedWebAppUrl);
}
