/// Instant-bingo late-claim rules (aligned with maraki `tooLateBingoMode`).
enum BingoClaimMode {
  /// Can claim a completed pattern later; rejected claims do not get another chance.
  noRestriction,

  /// Missed window loses that pattern; a new completed pattern opens a new window.
  allowLaterPatterns,

  /// Missed window closes the claim; checking after that locks the card for the game.
  disqualifyOnMiss;

  static const storageKey = 'bingo_claim_mode';

  String get id => switch (this) {
        noRestriction => 'no_restriction',
        allowLaterPatterns => 'allow_later_patterns',
        disqualifyOnMiss => 'disqualify_on_miss',
      };

  /// Claim must be made before the next ball is called.
  bool get usesClaimWindow =>
      this == allowLaterPatterns || this == disqualifyOnMiss;

  /// Checking a card after a missed window should lock it.
  bool get locksOnLateClaim => this == disqualifyOnMiss;

  /// Legacy `bingo_claim_limit` mirror for older readers (-1 off, 0 on).
  int get legacyLimit => this == noRestriction ? -1 : 0;

  static BingoClaimMode fromId(String? raw) {
    final id = (raw ?? '').trim().toLowerCase();
    return switch (id) {
      'allow_later_patterns' || 'allow_new_patterns' => allowLaterPatterns,
      'disqualify_on_miss' || 'strict' => disqualifyOnMiss,
      'no_restriction' || 'off' || 'instant' => noRestriction,
      _ => noRestriction,
    };
  }

  /// Reads `bingo_claim_mode`, falling back to legacy `bingo_claim_limit`.
  static BingoClaimMode fromSettings(Map<String, dynamic>? system) {
    final rawMode = system?[storageKey];
    if (rawMode != null && '$rawMode'.trim().isNotEmpty) {
      return fromId('$rawMode');
    }
    final limit = int.tryParse('${system?['bingo_claim_limit']}') ?? -1;
    // Old "Off" → no restriction; any "On / N more numbers" → disqualify (strict).
    return limit < 0 ? noRestriction : disqualifyOnMiss;
  }

  static const settingsOptions = <BingoClaimMode>[
    noRestriction,
    allowLaterPatterns,
    disqualifyOnMiss,
  ];
}
