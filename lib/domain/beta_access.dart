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
    this.tasksLeft = 0,
    this.tasksTotal = 0,
    this.needsAgreement = false,
  });

  final String name;
  final String app;
  final int tasksLeft;
  final int tasksTotal;
  final bool needsAgreement;

  static BetaRound fromJson(Map<String, dynamic> json) => BetaRound(
    name: json['name'] as String? ?? '',
    app: json['app'] as String? ?? '',
    tasksLeft: _int(json['tasks_left']),
    tasksTotal: _int(json['tasks_total']),
    needsAgreement: json['needs_agreement'] == true,
  );
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

int _int(Object? value) => switch (value) {
  final int n => n,
  final num n => n.toInt(),
  final String s => int.tryParse(s) ?? 0,
  _ => 0,
};
