/// Betting rules for cartela rounds.
abstract final class BetCalculator {
  /// Demo round: one player at 10 birr is free so the cashier can run a sample game.
  static bool isFreeDemoRound({
    required int cardCount,
    required int pricePerCard,
  }) {
    return cardCount == 1 && pricePerCard == 10;
  }

  static int billableCardCount({
    required int cardCount,
    required int pricePerCard,
  }) {
    if (cardCount <= 0 || isFreeDemoRound(
          cardCount: cardCount,
          pricePerCard: pricePerCard,
        )) {
      return 0;
    }
    return cardCount;
  }

  static int totalBet({
    required int cardCount,
    required int pricePerCard,
  }) {
    if (isFreeDemoRound(cardCount: cardCount, pricePerCard: pricePerCard)) {
      return 0;
    }
    return cardCount * pricePerCard;
  }
}
