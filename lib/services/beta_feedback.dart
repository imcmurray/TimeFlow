import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:timeflow/build_info.dart';
import 'package:timeflow/domain/beta_feedback_link.dart';
import 'package:url_launcher/url_launcher.dart';

/// Opens the tester portal's report form, filled in for this build and
/// device. Returns false when no browser could be opened.
///
/// [handoff] is a one-time value from a connected device, so the tester lands signed in
/// instead of being sent back through their email. It's minted on the tap and never
/// earlier: one that goes unused is one more thing to explain.
Future<bool> openBetaFeedback({required bool isTablet, String handoff = ''}) =>
    _openPortal(betaFeedbackUri, isTablet: isTablet, handoff: handoff);

/// Opens the round's tasks, to be walked one at a time. Returns false when no
/// browser could be opened.
Future<bool> openBetaTasks({required bool isTablet, String handoff = ''}) =>
    _openPortal(betaTasksUri, isTablet: isTablet, handoff: handoff);

/// The platform name the portal knows this device by, for the device list a tester sees.
Future<String> betaPlatformName({required bool isTablet}) async =>
    portalPlatform(
      targetPlatform: defaultTargetPlatform.name,
      isWeb: kIsWeb,
      isTablet: isTablet,
    );

Future<bool> _openPortal(
  Uri Function(BetaFeedbackContext, {String handoff}) link, {
  required bool isTablet,
  String handoff = '',
}) async {
  final package = await PackageInfo.fromPlatform();
  final (os, device) = await _osAndDevice();
  final uri = link(
    handoff: handoff,
    BetaFeedbackContext(
      version: package.version,
      buildNumber: package.buildNumber,
      commit: gitCommitHash,
      platform: portalPlatform(
        targetPlatform: defaultTargetPlatform.name,
        isWeb: kIsWeb,
        isTablet: isTablet,
      ),
      os: os,
      device: device,
    ),
  );
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}

/// Best effort: a device that won't say still gets the form, just less
/// filled in.
Future<(String, String)> _osAndDevice() async {
  try {
    final info = DeviceInfoPlugin();
    if (kIsWeb) {
      final web = await info.webBrowserInfo;
      return (web.platform ?? '', web.browserName.name);
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        final a = await info.androidInfo;
        return ('Android ${a.version.release}', '${a.manufacturer} ${a.model}');
      case TargetPlatform.iOS:
        final i = await info.iosInfo;
        return ('${i.systemName} ${i.systemVersion}', i.modelName);
      case TargetPlatform.macOS:
        final m = await info.macOsInfo;
        return (
          'macOS ${m.majorVersion}.${m.minorVersion}.${m.patchVersion}',
          m.model,
        );
      case TargetPlatform.windows:
        final w = await info.windowsInfo;
        // Not computerName: that's the owner's machine name.
        return (w.productName, '');
      case TargetPlatform.linux:
        final l = await info.linuxInfo;
        return (l.prettyName, '');
      case TargetPlatform.fuchsia:
        return ('', '');
    }
  } catch (_) {
    return ('', '');
  }
}
