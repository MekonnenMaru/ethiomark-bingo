import 'bingo_patterns.dart';

/// English-only win pattern labels shown in UI (never localized).
abstract final class BingoPatternNames {
  static String englishName(int pattern) {
    final p = BingoPatterns.normalize(pattern);
    return switch (p) {
        BingoPatterns.lineOne => 'any one line',
        BingoPatterns.lineTwo => 'any two line',
        BingoPatterns.lineThree => 'any three line',
        BingoPatterns.lShape => 'L',
        BingoPatterns.tShape => 'T',
        BingoPatterns.xShape => 'X',
        BingoPatterns.full => 'Full',
        BingoPatterns.anyVertical => 'any vertical',
        BingoPatterns.anyHorizontal => 'any horizontal',
        BingoPatterns.reverseTShape => 'reverse T',
        BingoPatterns.reverseLShape => 'reverse L',
        BingoPatterns.halfAbove => 'half above',
        BingoPatterns.halfBelow => 'half below',
        _ => '$p',
      };
  }

  static String compactEnglish(int pattern) {
    final p = BingoPatterns.normalize(pattern);
    if (p == BingoPatterns.full) return 'Full';
    if (p >= BingoPatterns.lineOne && p <= BingoPatterns.lineThree) {
      return p == BingoPatterns.lineOne ? '1 line' : '$p lines';
    }
    return englishName(pattern);
  }

  static String summaryEnglish(int pattern) {
    final p = BingoPatterns.normalize(pattern);
    if (p >= BingoPatterns.lineOne && p <= BingoPatterns.lineThree) {
      final name = englishName(p);
      final lineWord = p == BingoPatterns.lineOne ? 'line' : 'lines';
      return '$name ($p $lineWord)';
    }
    return englishName(p);
  }
}
