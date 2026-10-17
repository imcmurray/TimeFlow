/// Beta tester mode: what the portal tells a connected app, and what the app may say back.
///
/// The app holds a token that acts for a tester without ever learning who they are — the
/// portal answers with a handle like "Tester 27AF", never a name or an email. Everything
/// here is pure: the talking is in services/beta_access_service.dart.
library;

/// The portal's answer to `GET /api/device/summary`.
class BetaSummary {
  const BetaSummary({
    this.tasksLeft = 0,
    this.tasksTotal = 0,
    this.findingsOpen = 0,
    this.needsAgreement = false,
    this.pollAfter = const Duration(minutes: 15),
    this.rounds = const [],
  });

  /// Required steps not yet reported, across every open round this app has for the
  /// tester. This is the number on the badge. The portal is asked about this app only,
  /// so it can never count a round belonging to something else.
  final int tasksLeft;
  final int tasksTotal;
  final int findingsOpen;

  /// A round needs an agreement signed before it will say anything about itself. The badge
  /// stays empty rather than leaking a count through the gate.
  final bool needsAgreement;

  /// How long the portal would like us to wait before asking again.
  final Duration pollAfter;
  final List<BetaRound> rounds;

  /// The rounds the number is actually made of. One of them means we can name it, which
  /// is the difference between "5 tasks left" and "5 tasks left, but where?".
  List<BetaRound> get roundsWithWork =>
      rounds.where((r) => r.tasksLeft > 0).toList(growable: false);

  /// Rounds asking for a build this app isn't, out of the ones with work left in them.
  ///
  /// A round moves in place rather than a new one opening — *First Look - Apple* went
  /// 1.1.0 (222) to 1.1.3 (242) — so a tester can be holding an old build and a list of
  /// steps written for a newer one, with nothing to tell them apart. Either field
  /// disagreeing is enough; a tester hunting for a build number does not care which of the
  /// two we noticed.
  ///
  /// A round that says nothing about its build, or work already finished, is not worth a
  /// word: silence is the right answer when there is nothing to do about it.
  List<BuildMoved> movedPast({
    required String version,
    required String build,
  }) => [
    for (final round in roundsWithWork)
      if (!round.needsAgreement &&
          round.label.isNotEmpty &&
          (_differs(round.version, version) || _differs(round.build, build)))
        BuildMoved(
          round: round.name,
          wanted: round.label,
          running: switch ((version, build)) {
            ('', '') => 'what you have',
            ('', final b) => b,
            (final v, '') => v,
            (final v, final b) => '$v ($b)',
          },
          gap: _gap(round.build, build),
        ),
  ];

  /// Build numbers are what a tester reads in TestFlight and Play, and on this app they are
  /// plain integers, so they can be compared. Anything else is [BuildGap.unclear] rather
  /// than a guess dressed up as advice.
  static BuildGap _gap(String roundBuild, String appBuild) {
    final theirs = int.tryParse(roundBuild.trim());
    final ours = int.tryParse(appBuild.trim());
    if (theirs == null || ours == null || theirs == ours) {
      return BuildGap.unclear;
    }
    return theirs > ours ? BuildGap.behind : BuildGap.ahead;
  }

  static BetaSummary fromJson(Map<String, dynamic> json) {
    final seconds = _int(json['poll_after']);
    return BetaSummary(
      tasksLeft: _int(json['tasks_left']),
      tasksTotal: _int(json['tasks_total']),
      findingsOpen: _int(json['findings_open']),
      needsAgreement: json['needs_agreement'] == true,
      pollAfter: Duration(seconds: seconds > 0 ? seconds : 900),
      rounds: (json['rounds'] as List? ?? const [])
          .whereType<Map<String, dynamic>>()
          .map(BetaRound.fromJson)
          .toList(growable: false),
    );
  }
}

/// One open round, as much of it as the tester is allowed to see.
class BetaRound {
  const BetaRound({
    this.name = '',
    this.app = '',
    this.version = '',
    this.build = '',
    this.tasksLeft = 0,
    this.tasksTotal = 0,
    this.needsAgreement = false,
  });

  final String name;
  final String app;

  /// The build this round is asking to be tested, as the portal has it. Empty on a round
  /// gated behind an agreement, which says nothing about itself until it is signed.
  final String version;
  final String build;

  final int tasksLeft;
  final int tasksTotal;
  final bool needsAgreement;

  /// "1.1.3 (242)", or as much of it as the round gave us.
  String get label => switch ((version, build)) {
    ('', '') => '',
    ('', final b) => b,
    (final v, '') => v,
    (final v, final b) => '$v ($b)',
  };

  static BetaRound fromJson(Map<String, dynamic> json) => BetaRound(
    name: json['name'] as String? ?? '',
    app: json['app'] as String? ?? '',
    version: json['version'] as String? ?? '',
    build: json['build'] as String? ?? '',
    tasksLeft: _int(json['tasks_left']),
    tasksTotal: _int(json['tasks_total']),
    needsAgreement: json['needs_agreement'] == true,
  );
}

/// A round that has moved on from the build this app is running.
///
/// A warning, never a block. The tester may well have found something real on the build
/// they have, and the worst outcome here is one who decides their report no longer counts
/// and says nothing. The portal's round page says the same thing when they get there; this
/// is so they hear it before they start rather than after.
class BuildMoved {
  const BuildMoved({
    required this.round,
    required this.wanted,
    required this.running,
    this.gap = BuildGap.unclear,
  });

  /// The round's name, so a tester in two rounds knows which one means them.
  final String round;

  /// What the round asks for, and what this app actually is — "1.1.3 (242)", "1.1.0 (227)".
  final String wanted;
  final String running;

  /// Which of the two is in front, where that can be told.
  final BuildGap gap;
}

/// Which way a round and the build in hand have come apart.
///
/// The first version of this warning only knew that they differed, and told the tester to
/// update either way. That is wrong half the time: a round's build row is updated by hand
/// after an upload, so for a while the round asks for the *older* build and a tester who
/// updated promptly was told to update again — to a build behind the one they had.
enum BuildGap {
  /// The round has moved on. Update.
  behind,

  /// The tester is ahead of the round: they have a newer build than its steps were written
  /// for. Nothing for them to do, but worth knowing before they report anything.
  ahead,

  /// They differ and nothing in them says which way round — a build that isn't a number, or
  /// two versions apart on the same build.
  unclear,
}

/// What the app shows about itself: connected or not, for whom, and how much is left.
class BetaAccess {
  const BetaAccess({this.handle = '', this.summary});

  /// "Tester 27AF" — the only name the app ever has for the person using it.
  final String handle;
  final BetaSummary? summary;

  bool get connected => handle.isNotEmpty;
  int get tasksLeft => summary?.tasksLeft ?? 0;

  /// A badge is only worth showing when we know the number and it isn't zero.
  bool get showBadge => connected && tasksLeft > 0;

  static const disconnected = BetaAccess();
}

/// What `RRL-7K2P-9QRM-4T8X-2WYE` looks like once the spaces and the hyphens are gone and
/// the three characters people mistype are put back. The portal does this too, and refusing it
/// here as well means a mistyped code never costs a round trip.
String normaliseBetaCode(String raw) {
  final body = raw
      .toUpperCase()
      .replaceAll(RegExp(r'[\s-]+'), '')
      .replaceFirst(RegExp('^RRL'), '')
      .replaceAll(RegExp('[IL]'), '1')
      .replaceAll('O', '0')
      .replaceAll('U', 'V');
  return RegExp(r'^[0-9A-Z]{16}$').hasMatch(body) ? body : '';
}

bool looksLikeBetaCode(String raw) => normaliseBetaCode(raw).isNotEmpty;

/// Two build strings disagree only when we have both and they aren't the same.
///
/// Missing either side is not a disagreement. A round that hasn't filled in its build, or a
/// platform that won't tell us ours, would otherwise warn every tester about nothing.
bool _differs(String theirs, String ours) {
  final a = theirs.trim();
  final b = ours.trim();
  return a.isNotEmpty && b.isNotEmpty && a != b;
}

int _int(Object? value) => switch (value) {
  final int n => n,
  final num n => n.toInt(),
  final String s => int.tryParse(s) ?? 0,
  _ => 0,
};
