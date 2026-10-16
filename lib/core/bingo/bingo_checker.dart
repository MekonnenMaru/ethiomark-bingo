import '../../data/models/cartela.dart';
import 'bingo_claim_mode.dart';
import 'bingo_patterns.dart';

class BingoCheckResult {
  const BingoCheckResult({
    required this.isWinner,
    required this.isLocked,
    required this.winningLines,
    required this.cartela,
    required this.pattern,
    this.hadWinningPattern = false,
    this.isLateClaim = false,
    this.callsAfterPattern = 0,
    this.bingoClaimLimit = -1,
    this.claimMode = BingoClaimMode.noRestriction,
    this.locksOnLateClaim = false,
    this.allInOneBonusWin = 0,
  });

  /// Valid bingo — pattern complete and claimed within the allowed time.
  final bool isWinner;

  final bool isLocked;
  final int winningLines;
  final Cartela cartela;
  final int pattern;

  /// Pattern was complete on the board (may be too late to claim).
  final bool hadWinningPattern;

  /// Pattern was complete but the player did not claim bingo in time.
  final bool isLateClaim;

  /// How many numbers were called after the claim opportunity opened.
  final int callsAfterPattern;

  /// Legacy mirror: `-1` = no window, `0` = before next ball.
  final int bingoClaimLimit;

  final BingoClaimMode claimMode;

  /// Under [BingoClaimMode.disqualifyOnMiss], a late check should lock the card.
  final bool locksOnLateClaim;

  /// For [BingoPatterns.allInOne]: `1` = outside corners, `2` = inside corners.
  final int allInOneBonusWin;

  BingoCheckResult copyWith({bool? isLocked}) {
    return BingoCheckResult(
      isWinner: isWinner,
      isLocked: isLocked ?? this.isLocked,
      winningLines: winningLines,
      cartela: cartela,
      pattern: pattern,
      hadWinningPattern: hadWinningPattern,
      isLateClaim: isLateClaim,
      callsAfterPattern: callsAfterPattern,
      bingoClaimLimit: bingoClaimLimit,
      claimMode: claimMode,
      locksOnLateClaim: locksOnLateClaim,
      allInOneBonusWin: allInOneBonusWin,
    );
  }
}

class BingoChecker {
  static BingoCheckResult check({
    required Cartela cartela,
    required List<int> drawn,
    required int pattern,
    required bool isLocked,
    BingoClaimMode? claimMode,
    @Deprecated('Use claimMode') int? bingoClaimLimit,
  }) {
    final mode = claimMode ??
        (bingoClaimLimit == null || bingoClaimLimit < 0
            ? BingoClaimMode.noRestriction
            : BingoClaimMode.disqualifyOnMiss);

    final normalizedPattern = BingoPatterns.normalize(pattern);
    final evaluation = _evaluatePattern(cartela, drawn, normalizedPattern);
    final hadPattern = evaluation.hadPattern;

    var isLateClaim = false;
    var callsAfterPattern = 0;

    if (mode.usesClaimWindow && hadPattern && drawn.isNotEmpty) {
      final opportunityAt = mode == BingoClaimMode.allowLaterPatterns
          ? _lastQualifyingUpgradeIndex(
              cartela: cartela,
              drawn: drawn,
              pattern: normalizedPattern,
            )
          : _firstQualifyingIndex(
              cartela: cartela,
              drawn: drawn,
              pattern: normalizedPattern,
            );
      if (opportunityAt != null) {
        callsAfterPattern = (drawn.length - 1) - opportunityAt;
        // Window closes when the next ball is called (0 extra numbers allowed).
        isLateClaim = callsAfterPattern > 0;
      }
    }

    return BingoCheckResult(
      isWinner: hadPattern && !isLateClaim,
      isLocked: isLocked,
      winningLines: evaluation.winningLines,
      cartela: cartela,
      pattern: normalizedPattern,
      hadWinningPattern: hadPattern,
      isLateClaim: isLateClaim,
      callsAfterPattern: callsAfterPattern,
      bingoClaimLimit: mode.legacyLimit,
      claimMode: mode,
      locksOnLateClaim: mode.locksOnLateClaim && isLateClaim && !isLocked,
      allInOneBonusWin: evaluation.allInOneBonusWin,
    );
  }

  static int? firstWinningDrawIndex({
    required Cartela cartela,
    required List<int> drawn,
    required int pattern,
  }) {
    return _firstQualifyingIndex(
      cartela: cartela,
      drawn: drawn,
      pattern: BingoPatterns.normalize(pattern),
    );
  }

  static int? _firstQualifyingIndex({
    required Cartela cartela,
    required List<int> drawn,
    required int pattern,
  }) {
    if (drawn.isEmpty) return null;
    for (var i = 0; i < drawn.length; i++) {
      final score = _winningScore(
        cartela,
        drawn.sublist(0, i + 1),
        pattern,
      );
      if (_scoreQualifies(score, pattern)) return i;
    }
    return null;
  }

  /// Latest draw where the qualifying win level increased (new pattern opportunity).
  static int? _lastQualifyingUpgradeIndex({
    required Cartela cartela,
    required List<int> drawn,
    required int pattern,
  }) {
    if (drawn.isEmpty) return null;
    var peak = 0;
    int? lastUpgrade;
    for (var i = 0; i < drawn.length; i++) {
      final score = _winningScore(
        cartela,
        drawn.sublist(0, i + 1),
        pattern,
      );
      if (score > peak && _scoreQualifies(score, pattern)) {
        peak = score;
        lastUpgrade = i;
      } else if (score > peak) {
        peak = score;
      }
    }
    return lastUpgrade;
  }

  static int _winningScore(Cartela cartela, List<int> drawn, int pattern) {
    return _evaluatePattern(cartela, drawn, pattern).winningLines;
  }

  static bool _scoreQualifies(int score, int pattern) {
    if (BingoPatterns.isShapePattern(pattern)) return score >= 1;
    if (BingoPatterns.isAnyVerticalPattern(pattern) ||
        BingoPatterns.isAnyHorizontalPattern(pattern)) {
      return score >= 1;
    }
    final required = pattern.clamp(1, 3);
    return score >= required;
  }

  static ({bool hadPattern, int winningLines, int allInOneBonusWin})
      _evaluatePattern(
    Cartela cartela,
    List<int> drawn,
    int pattern,
  ) {
    pattern = BingoPatterns.normalize(pattern);

    if (BingoPatterns.isAnyVerticalPattern(pattern)) {
      final columns = _completeVerticalColumns(cartela.columns, drawn);
      return (
        hadPattern: columns.isNotEmpty,
        winningLines: columns.length,
        allInOneBonusWin: 0,
      );
    }

    if (BingoPatterns.isAnyHorizontalPattern(pattern)) {
      final rows = _completeHorizontalRows(cartela.columns, drawn);
      return (
        hadPattern: rows.isNotEmpty,
        winningLines: rows.length,
        allInOneBonusWin: 0,
      );
    }

    if (BingoPatterns.isShapePattern(pattern)) {
      final shape = _evaluateShape(cartela.columns, drawn, pattern);
      return (
        hadPattern: shape.hadPattern,
        winningLines: shape.winningLines,
        allInOneBonusWin: 0,
      );
    }

    final lines = _countWinningLines(cartela.columns, drawn);
    final required = pattern.clamp(1, 3);
    return (
      hadPattern: lines >= required,
      winningLines: lines,
      allInOneBonusWin: 0,
    );
  }

  static ({bool hadPattern, int winningLines}) _evaluateShape(
    Map<String, List<int>> card,
    List<int> drawn,
    int pattern,
  ) {
    final cells = _completedShapeCells(card, drawn, pattern);
    final required = BingoPatterns.cellsFor(pattern).length;
    return (
      hadPattern: cells.length == required,
      winningLines: cells.isEmpty ? 0 : 1,
    );
  }

  static Set<String> _completeVerticalColumns(
    Map<String, List<int>> card,
    List<int> drawn,
  ) {
    final drawnSet = drawn.toSet();
    final columns = <String>{};

    for (final entry in card.entries) {
      if (entry.value.every((n) => _isMarked(n, drawnSet))) {
        columns.add(entry.key);
      }
    }

    return columns;
  }

  static Set<int> _completeHorizontalRows(
    Map<String, List<int>> card,
    List<int> drawn,
  ) {
    final drawnSet = drawn.toSet();
    final rows = <int>{};

    for (var i = 0; i < 5; i++) {
      final horizontal = [
        card['B']![i],
        card['I']![i],
        card['N']![i],
        card['G']![i],
        card['O']![i],
      ];
      if (horizontal.every((n) => _isMarked(n, drawnSet))) {
        rows.add(i);
      }
    }

    return rows;
  }

  static int _countWinningLines(Map<String, List<int>> card, List<int> drawn) {
    return _winningLineKeys(card, drawn).length;
  }

  static bool _isMarked(int n, Set<int> drawnSet) =>
      n == 0 || drawnSet.contains(n);

  static Set<String> _completedShapeCells(
    Map<String, List<int>> card,
    List<int> drawn,
    int pattern,
  ) {
    return _completedCellSet(card, drawn, BingoPatterns.cellsFor(pattern));
  }

  static Set<String> _completedCellSet(
    Map<String, List<int>> card,
    List<int> drawn,
    Set<String> required,
  ) {
    final drawnSet = drawn.toSet();
    final completed = <String>{};

    for (final key in required) {
      final parts = key.split(':');
      if (parts.length != 2) continue;

      final col = parts[0];
      final row = int.tryParse(parts[1]);
      if (row == null) continue;

      final numbers = card[col];
      if (numbers == null || row < 0 || row >= numbers.length) continue;

      if (_isMarked(numbers[row], drawnSet)) {
        completed.add(key);
      }
    }

    return completed;
  }

  /// Unique line ids for each complete row/column/diagonal/corner set on the card.
  static Set<String> _winningLineKeys(
    Map<String, List<int>> card,
    List<int> drawn,
  ) {
    final drawnSet = drawn.toSet();
    final lines = <String>{};

    for (final entry in card.entries) {
      if (entry.value.every((n) => _isMarked(n, drawnSet))) {
        lines.add('col:${entry.key}');
      }
    }

    for (var i = 0; i < 5; i++) {
      final vertical = [
        card['B']![i],
        card['I']![i],
        card['N']![i],
        card['G']![i],
        card['O']![i],
      ];
      if (vertical.every((n) => _isMarked(n, drawnSet))) {
        lines.add('row:$i');
      }
    }

    final d1 = [
      card['B']![0],
      card['I']![1],
      card['N']![2],
      card['G']![3],
      card['O']![4],
    ];
    final d2 = [
      card['B']![4],
      card['I']![3],
      card['N']![2],
      card['G']![1],
      card['O']![0],
    ];
    if (d1.every((n) => _isMarked(n, drawnSet))) lines.add('diag:0');
    if (d2.every((n) => _isMarked(n, drawnSet))) lines.add('diag:1');

    final outside = _completedCellSet(
      card,
      drawn,
      BingoPatterns.outsideCornersCells,
    );
    if (outside.length == BingoPatterns.outsideCornersCells.length) {
      lines.add('corners:outside');
    }

    final inside = _completedCellSet(
      card,
      drawn,
      BingoPatterns.insideCornersCells,
    );
    if (inside.length == BingoPatterns.insideCornersCells.length) {
      lines.add('corners:inside');
    }

    return lines;
  }

  /// Grid cells (e.g. `B:2`) that belong to the active win pattern.
  static Set<String> winningCellKeys(
    Cartela cartela,
    List<int> drawn, {
    int? pattern,
  }) {
    final card = cartela.columns;
    final activePattern =
        pattern != null ? BingoPatterns.normalize(pattern) : null;

    if (activePattern == BingoPatterns.anyVertical) {
      return _verticalColumnCellKeys(card, drawn);
    }

    if (activePattern == BingoPatterns.anyHorizontal) {
      return _horizontalRowCellKeys(card, drawn);
    }

    if (activePattern != null && BingoPatterns.isShapePattern(activePattern)) {
      return _completedShapeCells(card, drawn, activePattern);
    }

    return _linePatternCellKeys(card, drawn);
  }

  static Set<String> _linePatternCellKeys(
    Map<String, List<int>> card,
    List<int> drawn,
  ) {
    final lineKeys = _winningLineKeys(card, drawn);
    final cells = <String>{};

    for (final line in lineKeys) {
      if (line.startsWith('col:')) {
        final col = line.substring(4);
        final numbers = card[col]!;
        for (var r = 0; r < 5; r++) {
          if (numbers[r] != 0) cells.add('$col:$r');
        }
      } else if (line.startsWith('row:')) {
        final r = int.parse(line.substring(4));
        for (final col in const ['B', 'I', 'N', 'G', 'O']) {
          final n = card[col]![r];
          if (n != 0) cells.add('$col:$r');
        }
      } else if (line == 'diag:0') {
        const coords = [('B', 0), ('I', 1), ('N', 2), ('G', 3), ('O', 4)];
        for (final (col, r) in coords) {
          if (card[col]![r] != 0) cells.add('$col:$r');
        }
      } else if (line == 'diag:1') {
        const coords = [('B', 4), ('I', 3), ('N', 2), ('G', 1), ('O', 0)];
        for (final (col, r) in coords) {
          if (card[col]![r] != 0) cells.add('$col:$r');
        }
      } else if (line == 'corners:outside') {
        cells.addAll(BingoPatterns.outsideCornersCells);
      } else if (line == 'corners:inside') {
        cells.addAll(BingoPatterns.insideCornersCells);
      }
    }

    if (lineKeys.isNotEmpty) {
      for (final line in lineKeys) {
        final includesCenter = switch (line) {
          'col:N' => true,
          'row:2' => true,
          'diag:0' || 'diag:1' => true,
          _ => false,
        };
        if (includesCenter) cells.add('N:2');
      }
    }

    return cells;
  }

  static Set<String> _verticalColumnCellKeys(
    Map<String, List<int>> card,
    List<int> drawn,
  ) {
    final cells = <String>{};
    for (final col in _completeVerticalColumns(card, drawn)) {
      final numbers = card[col]!;
      for (var r = 0; r < 5; r++) {
        if (numbers[r] != 0) cells.add('$col:$r');
      }
      if (col == 'N') cells.add('N:2');
    }
    return cells;
  }

  static Set<String> _horizontalRowCellKeys(
    Map<String, List<int>> card,
    List<int> drawn,
  ) {
    final cells = <String>{};
    for (final r in _completeHorizontalRows(card, drawn)) {
      for (final col in const ['B', 'I', 'N', 'G', 'O']) {
        final n = card[col]![r];
        if (n != 0) cells.add('$col:$r');
      }
      if (r == 2) cells.add('N:2');
    }
    return cells;
  }
}
