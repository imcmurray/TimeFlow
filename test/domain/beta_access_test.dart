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

  group('a round whose build has moved past this one', () {
    BetaSummary summaryOf(List<Map<String, dynamic>> rounds) =>
        BetaSummary.fromJson({'rounds': rounds, 'tasks_left': 1});

    const apple = {
      'name': 'First Look - Apple',
      'version': '1.1.3',
      'build': '242',
      'tasks_left': 5,
      'tasks_total': 5,
    };

    test('is named, with both builds spelled out', () {
      final moved = summaryOf([
        apple,
      ]).movedPast(version: '1.1.0', build: '227');
      expect(moved, hasLength(1));
      expect(moved.single.round, 'First Look - Apple');
      expect(moved.single.wanted, '1.1.3 (242)');
      expect(moved.single.running, '1.1.0 (227)');
    });

    test('knows the round is the one in front', () {
      final moved = summaryOf([
        apple,
      ]).movedPast(version: '1.1.0', build: '227');
      expect(moved.single.gap, BuildGap.behind, reason: '242 is past 227');
    });

    test('knows when the tester is the one in front', () {
      // The round's build row is updated by hand after an upload, so for a while the round
      // asks for the older build. A tester who updated promptly used to be told to update
      // again, to a build behind the one they had.
      final moved = summaryOf([
        apple,
      ]).movedPast(version: '1.1.3', build: '249');
      expect(
        moved,
        hasLength(1),
        reason: 'still worth saying, just not as "update"',
      );
      expect(moved.single.gap, BuildGap.ahead);
      expect(moved.single.wanted, '1.1.3 (242)');
      expect(moved.single.running, '1.1.3 (249)');
    });

    test('admits when it cannot tell which way round', () {
      final lettered = {...apple, 'build': '242-rc1'};
      expect(
        summaryOf([
          lettered,
        ]).movedPast(version: '1.1.3', build: '241').single.gap,
        BuildGap.unclear,
        reason: 'a build that is not a number is not a number to compare',
      );
      // Same build, different version: odd data, and not something to advise on.
      final sameBuild = {...apple, 'version': '1.1.4'};
      expect(
        summaryOf([
          sameBuild,
        ]).movedPast(version: '1.1.3', build: '242').single.gap,
        BuildGap.unclear,
      );
    });

    test('says nothing when the build matches', () {
      expect(
        summaryOf([apple]).movedPast(version: '1.1.3', build: '242'),
        isEmpty,
      );
    });

    test('notices a build bump that keeps the version', () {
      // 1.1.3 (242) and 1.1.3 (243) are different builds, and a tester hunting a number in
      // TestFlight cares. Either field disagreeing is enough.
      final moved = summaryOf([
        apple,
      ]).movedPast(version: '1.1.3', build: '241');
      expect(moved, hasLength(1));
      expect(moved.single.running, '1.1.3 (241)');
    });

    test('keeps quiet about work already finished', () {
      // Nothing to do about it, so saying so is noise in front of a round that is done.
      final done = {...apple, 'tasks_left': 0};
      expect(
        summaryOf([done]).movedPast(version: '1.1.0', build: '227'),
        isEmpty,
      );
    });

    test('keeps quiet when either side does not say', () {
      final silent = {...apple, 'version': '', 'build': ''};
      expect(
        summaryOf([silent]).movedPast(version: '1.1.0', build: '227'),
        isEmpty,
        reason: 'a round that has not filled in its build warns nobody',
      );
      expect(
        summaryOf([apple]).movedPast(version: '', build: ''),
        isEmpty,
        reason: 'a platform that will not tell us ours warns nobody either',
      );
    });

    test('says nothing about a round behind an agreement', () {
      // A gated round answers with needs_agreement and nothing else — no name, no build.
      // Warning about it would mean warning about a round the tester cannot see.
      final gated = summaryOf([
        {'needs_agreement': true, 'tasks_left': 3},
      ]);
      expect(gated.movedPast(version: '1.1.0', build: '227'), isEmpty);
    });

    test('names each round when a tester is in two that have both moved', () {
      final moved = summaryOf([
        apple,
        {
          'name': 'First Look - Android',
          'version': '1.1.4',
          'build': '250',
          'tasks_left': 2,
        },
      ]).movedPast(version: '1.1.0', build: '227');
      expect(moved.map((m) => m.round), [
        'First Look - Apple',
        'First Look - Android',
      ]);
      expect(moved.map((m) => m.wanted), ['1.1.3 (242)', '1.1.4 (250)']);
    });

    test('carries the round\'s build through from the portal\'s answer', () {
      // The summary dropped version and build before this; the warning is only possible
      // because they survive the parse.
      final round = BetaSummary.fromJson({
        'rounds': [apple],
      }).rounds.single;
      expect(round.version, '1.1.3');
      expect(round.build, '242');
      expect(round.label, '1.1.3 (242)');
    });
  });
}
