import '../../data/models/cashier_profile.dart';
import 'bet_calculator.dart';

class IncomeCalculator {
  /// Ethiomark `lock_round_up_last_digit`: when partner lock is off (0) and
  /// cashier income rounding is on, last-digit rounding applies to net income.
  static bool shouldRoundNetIncome({
    bool allowIncomeRounding = false,
    bool lockRoundUpLastDigit = false,
  }) {
    return allowIncomeRounding && !lockRoundUpLastDigit;
  }

  static double calculateIncome({
    required int sew,
    required int santim,
    required int cashierProfit,
    required List<CommissionTier> tiers,
    required bool usePartnerCommissionTiers,
    int startGetMoneyFrom = 0,
    bool allowIncomeRounding = false,
    bool lockRoundUpLastDigit = false,
  }) {
    final dr = BetCalculator.totalBet(cardCount: sew, pricePerCard: santim);
    if (startGetMoneyFrom > 0 && dr < startGetMoneyFrom) {
      return 0;
    }

    final percent = _resolvePercent(
      cardCount: sew,
      dr: dr,
      cashierProfit: cashierProfit,
      tiers: tiers,
      usePartnerCommissionTiers: usePartnerCommissionTiers,
    );

    return _finalizeNetIncome(
      rawIncome: dr * percent / 100,
      roundNetIncome: shouldRoundNetIncome(
        allowIncomeRounding: allowIncomeRounding,
        lockRoundUpLastDigit: lockRoundUpLastDigit,
      ),
    );
  }

  /// Prize pool (derash) — total bet minus rounded net income.
  static double calculateDerash({
    required int sew,
    required int santim,
    required int cashierProfit,
    required List<CommissionTier> tiers,
    required bool usePartnerCommissionTiers,
    int startGetMoneyFrom = 0,
    bool allowIncomeRounding = false,
    bool lockRoundUpLastDigit = false,
  }) {
    final dr = BetCalculator.totalBet(cardCount: sew, pricePerCard: santim);
    if (startGetMoneyFrom > 0 && dr < startGetMoneyFrom) return dr.toDouble();
    final income = calculateIncome(
      sew: sew,
      santim: santim,
      cashierProfit: cashierProfit,
      tiers: tiers,
      usePartnerCommissionTiers: usePartnerCommissionTiers,
      startGetMoneyFrom: startGetMoneyFrom,
      allowIncomeRounding: allowIncomeRounding,
      lockRoundUpLastDigit: lockRoundUpLastDigit,
    );
    return _roundToMoney(dr - income);
  }

  /// Mirrors ethiomark `index.php` profit steps one / two / three.
  static double _resolvePercent({
    required int cardCount,
    required int dr,
    required int cashierProfit,
    required List<CommissionTier> tiers,
    required bool usePartnerCommissionTiers,
  }) {
    if (usePartnerCommissionTiers && tiers.isNotEmpty) {
      final tierPercent = _tierPercentForCardCount(tiers, cardCount, dr);
      return tierPercent ?? _defaultDrPercent(dr);
    }

    if (cashierProfit > 0) {
      return cashierProfit.toDouble();
    }

    return _defaultDrPercent(dr);
  }

  /// Tier `min`/`max` match **card count** (`n`), not total bet (`dr`).
  static double? _tierPercentForCardCount(
    List<CommissionTier> tiers,
    int cardCount,
    int dr,
  ) {
    for (final tier in tiers) {
      if (cardCount >= tier.min && cardCount <= tier.max) {
        if (dr <= 120) return 9;
        return tier.percent;
      }
    }
    return null;
  }

  /// Fallback when no commission tier matches — ethiomark default DR ladder.
  static double _defaultDrPercent(int dr) {
    if (dr > 120 && dr < 320) return 20;
    if (dr >= 320 && dr < 800) return 22;
    if (dr >= 800 && dr < 1000) return 25;
    if (dr >= 1000) return 30;
    return 20;
  }

  static double _finalizeNetIncome({
    required double rawIncome,
    required bool roundNetIncome,
  }) {
    if (rawIncome <= 0) return 0;

    if (!roundNetIncome) {
      return _roundToMoney(rawIncome);
    }

    return _applyLastDigitRounding(rawIncome);
  }

  /// Ethiomark `index.php` — last digit of net income (`total` / `roundedTotal`).
  static double _applyLastDigitRounding(double rawIncome) {
    if (rawIncome <= 0) return 0;

    var roundedTotal = rawIncome;
    final lastDigit = roundedTotal % 10;
    final roundedLastDigit = lastDigit > 5 ? 10.0 : 0.0;
    roundedTotal = roundedTotal - lastDigit + roundedLastDigit;
    if (roundedTotal < 10 && rawIncome <= 10) {
      roundedTotal = 10;
    }

    return _roundToMoney(roundedTotal);
  }

  static double roundToMoney(double value) => _roundToMoney(value);

  static double _roundToMoney(double value) {
    return (value * 100).roundToDouble() / 100;
  }
}
