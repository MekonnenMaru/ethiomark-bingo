import 'dart:math';

/// Player lucky-card bonus (replaces the old Start/package bonus discount).
///
/// Settings JSON shape:
/// ```json
/// "bonus": {
///   "round": "off" | "every_1" | "every_3" | "every_4" | "every_10" | "random",
///   "count": "2",
///   "per_day": "2",
///   "amount": "50",
///   "min_bet": "100"
/// }
/// ```
///
/// [count] = lucky cards picked per claim.
/// [perDay] = max successful bonus claims allowed today.
abstract final class PlayerBonusLimits {
  static const minAmount = 50;
  static const maxAmount = 3000;
  static const minTotalBet = 100;
  static const maxTotalBet = 10000;

  static int clampAmount(int value) =>
      value.clamp(minAmount, maxAmount);

  static int clampMinBet(int value) =>
      value.clamp(minTotalBet, maxTotalBet);
}

class PlayerBonusSettings {
  const PlayerBonusSettings({
    required this.round,
    required this.count,
    required this.perDay,
    required this.amount,
    required this.minBet,
  });

  final PlayerBonusRound round;
  final int count;
  final int perDay;
  final int amount;
  final int minBet;

  bool get isEnabled => round != PlayerBonusRound.off;

  static const defaults = PlayerBonusSettings(
    round: PlayerBonusRound.random,
    count: 1,
    perDay: 1,
    amount: PlayerBonusLimits.minAmount,
    minBet: PlayerBonusLimits.minTotalBet,
  );

  factory PlayerBonusSettings.fromSettings(Map<String, dynamic> settings) {
    final raw = settings['bonus'];
    if (raw is! Map) return defaults;
    return PlayerBonusSettings.fromMap(Map<String, dynamic>.from(raw));
  }

  factory PlayerBonusSettings.fromMap(Map<String, dynamic> bonus) {
    // Migrate legacy {status, amount, per_day}.
    if (!bonus.containsKey('round') && bonus.containsKey('status')) {
      final on = '${bonus['status']}' == 'on';
      final perDay = (int.tryParse('${bonus['per_day']}') ?? 1).clamp(1, 20);
      return PlayerBonusSettings(
        round: on ? PlayerBonusRound.every3 : PlayerBonusRound.off,
        count: 1,
        perDay: perDay,
        amount: PlayerBonusLimits.clampAmount(
          int.tryParse('${bonus['amount']}') ?? PlayerBonusLimits.minAmount,
        ),
        minBet: PlayerBonusLimits.minTotalBet,
      );
    }

    final count = (int.tryParse('${bonus['count']}') ?? 1).clamp(1, 10);
    // Prefer explicit per_day; older random configs used count as the daily cap.
    final rawPerDay = bonus.containsKey('per_day')
        ? int.tryParse('${bonus['per_day']}')
        : null;
    final perDay = (rawPerDay ??
            (PlayerBonusRound.parse('${bonus['round'] ?? 'off'}') ==
                    PlayerBonusRound.random
                ? count
                : 1))
        .clamp(1, 20);

    return PlayerBonusSettings(
      round: PlayerBonusRound.parse('${bonus['round'] ?? 'off'}'),
      count: count,
      perDay: perDay,
      amount: PlayerBonusLimits.clampAmount(
        int.tryParse('${bonus['amount']}') ?? PlayerBonusLimits.minAmount,
      ),
      minBet: PlayerBonusLimits.clampMinBet(
        int.tryParse('${bonus['min_bet']}') ?? PlayerBonusLimits.minTotalBet,
      ),
    );
  }

  Map<String, dynamic> toMap() => {
        'round': round.storageValue,
        'count': '$count',
        'per_day': '$perDay',
        'amount': '$amount',
        'min_bet': '$minBet',
      };

  bool hasDailyQuotaRemaining(int awardsToday) => awardsToday < perDay;

  /// Whether this round may offer a bonus (before Claim).
  bool scheduleAllowsOffer({
    required int roundNumber,
    required int awardsToday,
    Random? random,
  }) {
    if (!hasDailyQuotaRemaining(awardsToday)) return false;

    switch (round) {
      case PlayerBonusRound.off:
        return false;
      case PlayerBonusRound.every1:
        return roundNumber > 0;
      case PlayerBonusRound.every3:
        return roundNumber > 0 && roundNumber % 3 == 0;
      case PlayerBonusRound.every4:
        return roundNumber > 0 && roundNumber % 4 == 0;
      case PlayerBonusRound.every10:
        return roundNumber > 0 && roundNumber % 10 == 0;
      case PlayerBonusRound.random:
        final remaining = perDay - awardsToday;
        final chance = remaining / (remaining + 3);
        return (random ?? Random()).nextDouble() < chance;
    }
  }
}

enum PlayerBonusRound {
  off,
  every1,
  every3,
  every4,
  every10,
  random;

  String get storageValue => switch (this) {
        PlayerBonusRound.off => 'off',
        PlayerBonusRound.every1 => 'every_1',
        PlayerBonusRound.every3 => 'every_3',
        PlayerBonusRound.every4 => 'every_4',
        PlayerBonusRound.every10 => 'every_10',
        PlayerBonusRound.random => 'random',
      };

  static PlayerBonusRound parse(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'every_1':
      case 'every1':
        return PlayerBonusRound.every1;
      case 'every_3':
      case 'every3':
        return PlayerBonusRound.every3;
      case 'every_4':
      case 'every4':
        return PlayerBonusRound.every4;
      case 'every_10':
      case 'every10':
        return PlayerBonusRound.every10;
      case 'random':
        return PlayerBonusRound.random;
      default:
        return PlayerBonusRound.off;
    }
  }
}

enum PlayerBonusRoundState { none, ready, claimed, skipped }

class PlayerBonusClaimResult {
  const PlayerBonusClaimResult({
    required this.luckyCards,
    required this.amount,
    required this.skipped,
  });

  final List<int> luckyCards;
  final int amount;
  final bool skipped;
}
