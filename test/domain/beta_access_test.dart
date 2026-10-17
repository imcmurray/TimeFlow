import 'package:flutter_test/flutter_test.dart';
import 'package:timeflow/domain/beta_access.dart';
import 'package:timeflow/domain/beta_feedback_link.dart';

void main() {
  group('normaliseBetaCode', () {
    test('takes the code as printed in the email', () {
      expect(normaliseBetaCode('RRL-7K2P-9QRM-4T8X-3HBN'), '7K2P9QRM4T8X3HBN');
    });

    test('forgives what someone copying it by eye types instead', () {
      // The portal does the same three substitutions, which is why the alphabet has no
      // I, L, O or U in it to begin with.
      expect(normaliseBetaCode('rrl 7k2p 9qrm 4t8x 3hbn'), '7K2P9QRM4T8X3HBN');
      expect(normaliseBetaCode('RRL-7K2P-9QRM-4T8X-3HBN '), '7K2P9QRM4T8X3HBN');
      expect(normaliseBetaCode('RRL-IK2P-9QRM-4T8X-3HBN'), '1K2P9QRM4T8X3HBN');
      expect(normaliseBetaCode('RRL-OK2P-9QRM-4T8X-3HBN'), '0K2P9QRM4T8X3HBN');
    });

    test(
      'rejects anything that is not a code, so a typo costs no round trip',
      () {
        expect(normaliseBetaCode(''), '');
        expect(normaliseBetaCode('hello'), '');
        expect(
          normaliseBetaCode('RRL-7K2P-9QRM-4T8X'),
          '',
          reason: 'three groups, not four',
        );
        expect(looksLikeBetaCode('RRL-7K2P-9QRM-4T8X-3HBN'), isTrue);
        expect(looksLikeBetaCode('nope'), isFalse);
      },
    );
  });

  group('BetaSummary', () {
    test('reads what the portal sends', () {
      final summary = BetaSummary.fromJson(const {
        'rounds': [
          {
            'name': 'First Look - Apple',
            'app': 'TimeFlow',
            'tasks_left': 2,
            'tasks_total': 3,
          },
          {'needs_agreement': true},
        ],
        'tasks_left': 2,
        'tasks_total': 3,
        'findings_open': 1,
        'needs_agreement': true,
        'poll_after': 900,
      });
      expect(summary.tasksLeft, 2);
      expect(summary.tasksTotal, 3);
      expect(summary.findingsOpen, 1);
      expect(summary.needsAgreement, isTrue);
      expect(summary.pollAfter, const Duration(minutes: 15));
      expect(summary.rounds, hasLength(2));
      expect(summary.rounds.first.name, 'First Look - Apple');
      expect(summary.rounds.last.needsAgreement, isTrue);
      expect(
        summary.rounds.last.name,
        isEmpty,
        reason: 'a gated round names nothing',
      );
    });

    test('knows which rounds the number is made of', () {
      final summary = BetaSummary.fromJson(const {
        'rounds': [
          {'name': 'First look - Android and web', 'tasks_left': 5},
          {'name': 'Finished round', 'tasks_left': 0},
        ],
        'tasks_left': 5,
      });
      expect(summary.roundsWithWork, hasLength(1));
      expect(
        summary.roundsWithWork.single.name,
        'First look - Android and web',
      );
    });

    test('survives a response with nothing useful in it', () {
      final summary = BetaSummary.fromJson(const {});
      expect(summary.tasksLeft, 0);
      expect(summary.rounds, isEmpty);
      expect(
        summary.pollAfter,
        const Duration(minutes: 15),
        reason: 'never poll in a tight loop',
      );
    });
  });

  group('BetaAccess', () {
    test('is disconnected until there is a handle', () {
      expect(BetaAccess.disconnected.connected, isFalse);
      expect(const BetaAccess(handle: 'Tester 27AF').connected, isTrue);
    });

    test('shows a badge only when it knows the number and it is not zero', () {
      const summary = BetaSummary(tasksLeft: 3, tasksTotal: 3);
      expect(
        const BetaAccess(handle: 'Tester 27AF', summary: summary).showBadge,
        isTrue,
      );
      expect(
        const BetaAccess(handle: 'Tester 27AF').showBadge,
        isFalse,
        reason: "no summary means we don't know, not that it's zero",
      );
      expect(
        const BetaAccess(
          handle: 'Tester 27AF',
          summary: BetaSummary(tasksLeft: 0),
        ).showBadge,
        isFalse,
      );
      expect(
        const BetaAccess(summary: summary).showBadge,
        isFalse,
        reason: 'not connected, no badge',
      );
    });
  });

  group('the handoff in the link', () {
    const context = BetaFeedbackContext(
      version: '1.1.1',
      buildNumber: '230',
      commit: 'd344854',
      platform: 'Android Phone',
      os: 'Android 16',
      device: 'Google Pixel 8a',
    );

    test('rides in the fragment, so it never reaches the portal\'s logs', () {
      final uri = betaTasksUri(context, handoff: 'abc123');
      expect(uri.query, isEmpty);
      final params = Uri.splitQueryString(uri.fragment.split('?').last);
      expect(params['h'], 'abc123');
      expect(uri.fragment, startsWith('/tasks?'));
    });

    test('is absent when there is none, rather than empty', () {
      final params = Uri.splitQueryString(
        betaTasksUri(context).fragment.split('?').last,
      );
      expect(params.containsKey('h'), isFalse);
      final report = Uri.splitQueryString(
        betaFeedbackUri(context).fragment.split('?').last,
      );
      expect(report.containsKey('h'), isFalse);
    });
  });
}
