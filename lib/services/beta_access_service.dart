import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:timeflow/domain/beta_access.dart';
import 'package:timeflow/domain/beta_feedback_link.dart';

/// Talks to the tester portal on behalf of a connected device, at `/api/device/*`.
///
/// That path is Bearer only and never reads a cookie — it's carved out ahead of the
/// portal's session handling. It sits under `/api/` rather than a prefix of its own
/// because the portal's zone firewall is an allowlist, and a new top-level path would be
/// a rule change in a dashboard before any build could reach it.
///
/// The token lives in the platform's own store — Keychain on Apple, Keystore-backed
/// preferences on Android, WebCrypto in the browser — and is read only in the foreground.
/// On Apple it is deliberately `…ThisDeviceOnly` and not synchronizable: a token restored
/// onto a new phone from a backup would be a second device nobody connected, and the list
/// in the portal would be a lie.
///
/// There is no preference recording whether beta mode is on. Deleting an app on iOS leaves
/// its Keychain items behind, so the token's presence is the only honest answer.
class BetaAccessService {
  BetaAccessService({http.Client? client, BetaTokenStore? store})
    : _client = client ?? http.Client(),
      _store = store ?? const KeychainTokenStore();

  static const _tokenKey = 'rrl_beta_token';
  static const _handleKey = 'rrl_beta_handle';

  final http.Client _client;
  final BetaTokenStore _store;

  Future<String?> readToken() => _get(_tokenKey);
  Future<String?> readHandle() => _get(_handleKey);

  /// Spend the one-time code from the round's announcement email. On success the token is
  /// stored and the handle comes back; everything else is a message to show the tester.
  Future<BetaConnectResult> connect(
    String rawCode, {
    required String label,
    required String platform,
  }) async {
    final code = normaliseBetaCode(rawCode);
    if (code.isEmpty) {
      return const BetaConnectResult.failed(
        "That doesn't look like a beta code. It's the RRL-… line in the email about this round.",
      );
    }
    final res = await _post('/api/device/connect', {
      'code': code,
      'label': label,
      'platform': platform,
    });
    if (res == null) {
      return const BetaConnectResult.failed(
        "Couldn't reach the tester portal. Check your connection and try again.",
      );
    }
    if (res.statusCode == 409) {
      return const BetaConnectResult.failed(
        'That code has already been used. Sign in to the portal and ask for a new one.',
      );
    }
    final body = _json(res.body);
    if (res.statusCode != 200 || body['token'] is! String) {
      return BetaConnectResult.failed(
        body['error'] as String? ?? "That didn't work. Try again in a minute.",
      );
    }
    final handle = body['handle'] as String? ?? 'this tester';
    await _store.write(_tokenKey, body['token'] as String);
    await _store.write(_handleKey, handle);
    return BetaConnectResult.connected(handle);
  }

  /// The badge. Null means we don't know — offline, or the portal said no — and the caller
  /// should keep whatever it had rather than show a zero it can't stand behind.
  ///
  /// The app name goes with the question: a tester is often in rounds for more than one
  /// app, and a number on this app's Tasks button that counted another app's round is a
  /// number that doesn't match the page the button opens.
  Future<BetaSummary?> summary() async {
    final token = await readToken();
    if (token == null) return null;
    final res = await _get401(
      '/api/device/summary?app=${Uri.encodeQueryComponent(testerPortalAppName)}',
      token,
    );
    if (res == null) return null;
    if (res.statusCode == 401) {
      // The tester left the pool, or the token was revoked from the portal. Forget it
      // rather than keep asking; the next code they paste connects cleanly.
      await forget();
      return null;
    }
    if (res.statusCode != 200) return null;
    return BetaSummary.fromJson(_json(res.body));
  }

  /// A fresh thirty-second value, minted on the tap and never before it: it's no use to
  /// anyone sooner, and one that goes unused is one more thing to explain.
  Future<String> handoff({required String intent}) async {
    final token = await readToken();
    if (token == null) return '';
    final res = await _post('/api/device/handoff', {
      'intent': intent,
    }, token: token);
    if (res == null || res.statusCode != 200) return '';
    return _json(res.body)['handoff'] as String? ?? '';
  }

  /// Tell the portal first, so the device drops off the tester's list even if this copy of
  /// the app is never opened again, then forget the token either way.
  Future<void> disconnect() async {
    final token = await readToken();
    if (token != null) {
      await _post('/api/device/disconnect', const {}, token: token);
    }
    await forget();
  }

  Future<void> forget() async {
    await _store.delete(_tokenKey);
    await _store.delete(_handleKey);
  }

  Future<String?> _get(String key) async {
    try {
      return await _store.read(key);
    } catch (_) {
      return null; // No keystore, a locked device, a browser with storage blocked.
    }
  }

  Future<http.Response?> _post(
    String path,
    Map<String, Object?> body, {
    String? token,
  }) async {
    try {
      return await _client.post(
        Uri.parse('$testerPortalOrigin$path'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
    } catch (_) {
      return null;
    }
  }

  Future<http.Response?> _get401(String path, String token) async {
    try {
      return await _client.get(
        Uri.parse('$testerPortalOrigin$path'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (_) {
      return null;
    }
  }

  Map<String, dynamic> _json(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : const {};
    } catch (_) {
      return const {};
    }
  }
}

/// Where the device token is kept. An interface so the service can be tested without a
/// platform channel, and so the platform's own rules live in one place.
abstract class BetaTokenStore {
  Future<String?> read(String key);
  Future<void> write(String key, String value);
  Future<void> delete(String key);
}

/// Keychain on Apple, a Keystore-wrapped file on Android, WebCrypto in a browser.
class KeychainTokenStore implements BetaTokenStore {
  const KeychainTokenStore();

  /// `…ThisDeviceOnly` and not synchronizable, so the token never reaches iCloud Keychain
  /// or a backup restored onto another phone: that would be a device nobody connected, and
  /// the portal's device list would be a lie. "Unlocked" is enough, because the token is
  /// only ever read in the foreground. Android takes the package's defaults — since 11.0
  /// that is AES-GCM under an RSA-OAEP wrapped Keystore key.
  static const _storage = FlutterSecureStorage(
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.unlocked_this_device,
      synchronizable: false,
    ),
  );

  @override
  Future<String?> read(String key) => _storage.read(key: key);

  @override
  Future<void> write(String key, String value) =>
      _storage.write(key: key, value: value);

  @override
  Future<void> delete(String key) => _storage.delete(key: key);
}

/// Either connected, with the handle to show, or a sentence to put in front of the tester.
@immutable
class BetaConnectResult {
  const BetaConnectResult.connected(this.handle) : error = '';
  const BetaConnectResult.failed(this.error) : handle = '';

  final String handle;
  final String error;

  bool get ok => handle.isNotEmpty;
}
