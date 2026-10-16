/// Win pattern ids stored on each game round.
abstract final class BingoPatterns {
  /// Legacy stored id — same rules as [lineOne]. Use [normalize] when reading.
  static const allInOne = 14;
  static const lineOne = 1;
  static const lineTwo = 2;
  static const lineThree = 3;
  static const lShape = 4;
  static const tShape = 5;
  static const xShape = 6;
  static const full = 7;
  static const anyVertical = 8;
  static const anyHorizontal = 9;
  static const reverseTShape = 10;
  static const reverseLShape = 11;
  static const halfAbove = 12;
  static const halfBelow = 13;

  static const defaultPattern = lineOne;

  /// Line-style patterns (combinations / any column / any row).
  static const lineSelectionGroup = [
    lineOne,
    lineTwo,
    lineThree,
    anyVertical,
    anyHorizontal,
  ];

  /// Fixed shapes — full card first, then letter / half shapes.
  static const staticShapeGroup = [
    full,
    tShape,
    reverseTShape,
    xShape,
    lShape,
    reverseLShape,
    halfAbove,
    halfBelow,
  ];

  static const all = [...lineSelectionGroup, ...staticShapeGroup];

  /// Maps legacy default id (14) to any-one-line (1).
  static int normalize(int pattern) =>
      pattern == allInOne ? lineOne : pattern;

  static bool isAllInOnePattern(int pattern) => pattern == allInOne;

  static bool isLinePattern(int pattern) {
    final p = normalize(pattern);
    return p >= lineOne && p <= lineThree;
  }

  static bool isShapePattern(int pattern) => switch (pattern) {
        lShape ||
        tShape ||
        xShape ||
        reverseTShape ||
        reverseLShape ||
        halfAbove ||
        halfBelow ||
        full =>
          true,
        _ => false,
      };

  /// Fixed shapes (full, T, L, X, halves) — one fast draw, no combination loop.
  static bool isFixedShapePattern(int pattern) => switch (pattern) {
        full ||
        lShape ||
        tShape ||
        xShape ||
        reverseTShape ||
        reverseLShape ||
        halfAbove ||
        halfBelow =>
          true,
        _ => false,
      };

  static bool isAnyVerticalPattern(int pattern) => pattern == anyVertical;

  static bool isAnyHorizontalPattern(int pattern) => pattern == anyHorizontal;

  /// Four board corners (B1, O1, B5, O5).
  static const outsideCornersCells = {
    'B:0',
    'O:0',
    'B:4',
    'O:4',
  };

  /// Square around the free space (I2, G2, I4, G4).
  static const insideCornersCells = {
    'I:1',
    'G:1',
    'I:3',
    'G:3',
  };

  /// Left column + bottom row.
  static const lShapeCells = {
    'B:0',
    'B:1',
    'B:2',
    'B:3',
    'B:4',
    'I:4',
    'N:4',
    'G:4',
    'O:4',
  };

  /// Top row + center (N) column.
  static const tShapeCells = {
    'B:0',
    'I:0',
    'N:0',
    'G:0',
    'O:0',
    'N:1',
    'N:2',
    'N:3',
    'N:4',
  };

  /// Bottom row + center (N) column.
  static const reverseTShapeCells = {
    'B:4',
    'I:4',
    'N:4',
    'G:4',
    'O:4',
    'N:0',
    'N:1',
    'N:2',
    'N:3',
  };

  /// Both diagonals through the free space.
  static const xShapeCells = {
    'B:0',
    'I:1',
    'N:2',
    'G:3',
    'O:4',
    'B:4',
    'I:3',
    'G:1',
    'O:0',
  };

  /// Right column + bottom row.
  static const reverseLShapeCells = {
    'O:0',
    'O:1',
    'O:2',
    'O:3',
    'O:4',
    'B:4',
    'I:4',
    'N:4',
    'G:4',
  };

  static final halfAboveCells = _cellsForRows({0, 1});
  static final halfBelowCells = _cellsForRows({3, 4});
  static final fullCells = _cellsForRows({0, 1, 2, 3, 4});

  static Set<String> _cellsForRows(Set<int> rows) {
    return {
      for (final col in const ['B', 'I', 'N', 'G', 'O'])
        for (final row in rows) '$col:$row',
    };
  }

  static Set<String> cellsFor(int pattern) => switch (pattern) {
        lShape => lShapeCells,
        tShape => tShapeCells,
        reverseTShape => reverseTShapeCells,
        xShape => xShapeCells,
        reverseLShape => reverseLShapeCells,
        halfAbove => halfAboveCells,
        halfBelow => halfBelowCells,
        full => fullCells,
        allInOne => outsideCornersCells,
        _ => const {},
      };

  static Set<String> cellsForAllInOneBonus(int bonusWin) => switch (bonusWin) {
        1 => outsideCornersCells,
        2 => insideCornersCells,
        _ => const {},
      };
}
