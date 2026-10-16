import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:timeflow/services/beta_access_service.dart';

/// The token store, without a platform channel.
class _MemoryStore implements BetaTokenStore {
  final Map<String, String> values = {};

  @override
  Future<String?> read(String key) async => values[key];

  @override
  Future<void> write(String key, String value) async => values[key] = value;

  @override
  Future<void> delete(String key) async => values.remove(key);
}

void main() {
  late _MemoryStore store;
  final seen = <http.Request>[];

  setUp(() {
    store = _MemoryStore();
    seen.clear();
  });

  /// A portal that answers [replies] in order, recording what it was asked.
  BetaAccessService serviceThat(List<http.Response> replies) {
    var i = 0;
    return BetaAccessService(
      store: store,
      client: MockClient((request) async {
        seen.add(request);
        return replies[i++ < replies.length ? i - 1 : replies.length - 1];
      }),
    );
  }

  http.Response ok(Map<String, Object?> body) => http.Response(
    jsonEncode(body),
    200,
    headers: const {'content-type': 'application/json'},
  );

  group('connecting', () {
    test('spends the code, keeps the token, and reports the handle', () async {
      final service = serviceThat([
        ok({'token': 'a' * 43, 'handle': 'Tester 27AF'}),
      ]);
      final result = await service.connect(
        'rrl 7k2p 9qrm 4t8x 3hbn',
        label: 'TimeFlow on Android Phone',
        platform: 'Android Phone',
      );

      expect(result.ok, isTrue);
      expect(result.handle, 'Tester 27AF');
      expect(await service.readToken(), 'a' * 43);
      expect(await service.readHandle(), 'Tester 27AF');

      // Normalised before it leaves the device, so what the portal hashes is what it minted.
      expect(jsonDecode(seen.single.body)['code'], '7K2P9QRM4T8X3HBN');
      expect(seen.single.url.path, '/api/device/connect');
      expect(
        seen.single.headers['Authorization'],
        isNull,
        reason: 'no token to send yet',
      );
    });

    test('never asks the portal about something that is not a code', () async {
      final service = serviceThat([ok(const {})]);
      final result = await service.connect('hello', label: 'x', platform: 'x');
      expect(result.ok, isFalse);
      expect(result.error, contains('RRL-'));
      expect(seen, isEmpty);
    });

    test('says plainly when a code has already been used', () async {
      final service = serviceThat([http.Response('{"error":"gone"}', 409)]);
      final result = await service.connect(
        'RRL-7K2P-9QRM-4T8X-3HBN',
        label: 'x',
        platform: 'x',
      );
      expect(result.ok, isFalse);
      expect(result.error, contains('already been used'));
      expect(store.values, isEmpty);
    });

    test('keeps nothing when the portal cannot be reached', () async {
      final service = BetaAccessService(
        store: store,
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      final result = await service.connect(
        'RRL-7K2P-9QRM-4T8X-3HBN',
        label: 'x',
        platform: 'x',
      );
      expect(result.ok, isFalse);
      expect(result.error, contains("Couldn't reach"));
      expect(store.values, isEmpty);
    });
  });

  group('the summary', () {
    test('is sent with the token and read back', () async {
      store.values['rrl_beta_token'] = 'b' * 43;
      final service = serviceThat([
        ok(const {'tasks_left': 2, 'tasks_total': 3}),
      ]);
      final summary = await service.summary();
      expect(summary?.tasksLeft, 2);
      expect(seen.single.headers['Authorization'], 'Bearer ${'b' * 43}');
    });

    test('forgets the token when the portal says the tester is gone', () async {
      store.values['rrl_beta_token'] = 'b' * 43;
      store.values['rrl_beta_handle'] = 'Tester 27AF';
      final service = serviceThat([http.Response('{"error":"nope"}', 401)]);
      expect(await service.summary(), isNull);
      expect(store.values, isEmpty, reason: 'a dead token is worse than none');
    });

    test('keeps the token when we simply could not ask', () async {
      store.values['rrl_beta_token'] = 'b' * 43;
      final service = BetaAccessService(
        store: store,
        client: MockClient((_) async => throw http.ClientException('offline')),
      );
      expect(await service.summary(), isNull);
      expect(store.values['rrl_beta_token'], 'b' * 43);
    });

    test('is not asked for at all without a token', () async {
      final service = serviceThat([ok(const {})]);
      expect(await service.summary(), isNull);
      expect(seen, isEmpty);
    });
  });

  group('the handoff', () {
    test(
      'is asked for on the tap, with the intent of the button pressed',
      () async {
        store.values['rrl_beta_token'] = 'c' * 43;
        final service = serviceThat([
          ok(const {'handoff': 'one-time', 'expires_in': 30}),
        ]);
        expect(await service.handoff(intent: 'tasks'), 'one-time');
        expect(jsonDecode(seen.single.body)['intent'], 'tasks');
      },
    );

    test('is empty rather than wrong when the portal says no', () async {
      store.values['rrl_beta_token'] = 'c' * 43;
      final service = serviceThat([http.Response('nope', 500)]);
      expect(await service.handoff(intent: 'tasks'), isEmpty);
    });
  });

  test(
    'disconnecting tells the portal first, then forgets either way',
    () async {
      store.values['rrl_beta_token'] = 'd' * 43;
      store.values['rrl_beta_handle'] = 'Tester 27AF';
      final service = serviceThat([
        ok(const {'ok': true}),
      ]);
      await service.disconnect();
      expect(seen.single.url.path, '/api/device/disconnect');
      expect(seen.single.headers['Authorization'], 'Bearer ${'d' * 43}');
      expect(store.values, isEmpty);
    },
  );
}
