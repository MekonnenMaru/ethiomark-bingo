import 'trial_prefs.dart';

/// Free trial: up to 5 rounds at 0 wallet balance — 1 card @ 10 birr only.
abstract final class TrialService {
  static const maxRounds = TrialPrefs.maxRounds;
  static const trialCardCount = 1;
  static const trialStakeBirr = 10;

  static bool isZeroBalance(String packageBalance) {
    return (double.tryParse(packageBalance.trim()) ?? 0) == 0;
  }

  static bool isTrialRoundConfig({
    required int cardCount,
    required int pricePerCard,
  }) {
    return cardCount == trialCardCount && pricePerCard == trialStakeBirr;
  }

  static bool isActiveTrial({
    required String packageBalance,
    required int roundsUsed,
  }) {
    return isZeroBalance(packageBalance) && roundsUsed < maxRounds;
  }

  static bool isTrialExhausted({
    required String packageBalance,
    required int roundsUsed,
  }) {
    return isZeroBalance(packageBalance) && roundsUsed >= maxRounds;
  }

  /// Whether this round is free (no wallet charge).
  static bool isFreeTrialRound({
    required String packageBalance,
    required int roundsUsed,
    required int cardCount,
    required int pricePerCard,
  }) {
    return isActiveTrial(
          packageBalance: packageBalance,
          roundsUsed: roundsUsed,
        ) &&
        isTrialRoundConfig(cardCount: cardCount, pricePerCard: pricePerCard);
  }

  static int roundsRemaining(int roundsUsed) {
    return (maxRounds - roundsUsed).clamp(0, maxRounds);
  }

  static bool isTrialExhaustedResult(Map<String, dynamic> result) =>
      result['code'] == 'trial_exhausted';

  static bool isTrialRulesResult(Map<String, dynamic> result) =>
      result['code'] == 'trial_rules';
}
