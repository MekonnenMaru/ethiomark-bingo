import 'dart:math' as math;

import 'bingo_patterns.dart';

/// Board cell for pattern help animations (row 0–4, col 0 = B … 4 = O).
typedef PatternAnimCell = ({int row, int col});

/// One animation step — one or more highlighted cell groups (different tones).
class PatternAnimationFrame {
  const PatternAnimationFrame({
    required this.label,
    required this.groups,
    this.index = 1,
    this.total = 1,
    this.holdMs = 1500,
  });

  final String label;
  final List<Set<PatternAnimCell>> groups;
  final int index;
  final int total;
  final int holdMs;
}

/// Builds win-pattern preview frames (aligned with maraki_bingo win-pattern-animator).
abstract final class PatternAnimationFrames {
  /// Minimum time each animation step stays on screen (keeps UI load low).
  static const minHoldMs = 1500;

  static int _holdMs(int ms) => math.max(ms, minHoldMs);

  /// Fixed shapes draw once quickly; line/combo patterns loop with [minHoldMs].
  static bool loopsForPattern(int pattern) =>
      !BingoPatterns.isFixedShapePattern(pattern);

  /// Per-cell step while drawing fixed shapes (faster than [minHoldMs]).
  static const fixedShapeStepMs = 120;

  static const _letters = ['B', 'I', 'N', 'G', 'O'];

  static PatternAnimCell cell(int row, int col) => (row: row, col: col);

  static Set<PatternAnimCell> _rowCells(int row) {
    return {for (var c = 0; c < 5; c++) cell(row, c)};
  }

  static Set<PatternAnimCell> _colCells(int col) {
    return {for (var r = 0; r < 5; r++) cell(r, col)};
  }

  static Set<PatternAnimCell> _diagCells({required bool main}) {
    return {
      for (var i = 0; i < 5; i++)
        main ? cell(i, i) : cell(i, 4 - i),
    };
  }

  static Set<PatternAnimCell> _cellsFromKeys(Set<String> keys) {
    const colMap = {'B': 0, 'I': 1, 'N': 2, 'G': 3, 'O': 4};
    final out = <PatternAnimCell>{};
    for (final key in keys) {
      final parts = key.split(':');
      if (parts.length != 2) continue;
      final col = colMap[parts[0]];
      final row = int.tryParse(parts[1]);
      if (col == null || row == null) continue;
      out.add(cell(row, col));
    }
    return out;
  }

  static const _outside = {(0, 0), (0, 4), (4, 0), (4, 4)};
  static const _inside = {(1, 1), (1, 3), (3, 1), (3, 3)};

  static Set<PatternAnimCell> _outsideCells() =>
      _outside.map((e) => cell(e.$1, e.$2)).toSet();

  static Set<PatternAnimCell> _insideCells() =>
      _inside.map((e) => cell(e.$1, e.$2)).toSet();

  static List<({String label, Set<PatternAnimCell> cells})> _buildSingleLines() {
    final lines = <({String label, Set<PatternAnimCell> cells})>[];
    for (var row = 0; row < 5; row++) {
      lines.add((label: 'Row ${row + 1}', cells: _rowCells(row)));
    }
    for (var col = 0; col < 5; col++) {
      lines.add((label: '${_letters[col]} column', cells: _colCells(col)));
    }
    lines.add((label: 'Diagonal ↘', cells: _diagCells(main: true)));
    lines.add((label: 'Diagonal ↙', cells: _diagCells(main: false)));
    lines.add((label: 'Outside corners', cells: _outsideCells()));
    lines.add((label: 'Inside corners', cells: _insideCells()));
    return lines;
  }

  static List<List<int>> _combinationsK(int n, int k) {
    final result = <List<int>>[];
    final chosen = <int>[];

    void pick(int start) {
      if (chosen.length == k) {
        result.add(List<int>.from(chosen));
        return;
      }
      for (var i = start; i < n; i++) {
        chosen.add(i);
        pick(i + 1);
        chosen.removeLast();
      }
    }

    pick(0);
    return result;
  }

  static List<PatternAnimationFrame> _combinationFrames(
    int lineCount,
    List<({String label, Set<PatternAnimCell> cells})> singles,
    int holdMs,
  ) {
    final combos = _combinationsK(singles.length, lineCount);
    final total = combos.length;
    return combos.asMap().entries.map((entry) {
      final idx = entry.key + 1;
      final combo = entry.value;
      final names = combo.map((i) => singles[i].label).toList();
      final groups = combo.map((i) => singles[i].cells).toList();
      return PatternAnimationFrame(
        label: '$lineCount lines ($idx/$total): ${names.join(' + ')}',
        groups: groups,
        index: idx,
        total: total,
        holdMs: _holdMs(holdMs),
      );
    }).toList();
  }

  static List<PatternAnimationFrame> _singleLineFrames(int holdMs) {
    final singles = _buildSingleLines();
    final total = singles.length;
    return singles.asMap().entries.map((e) {
      final idx = e.key + 1;
      final line = e.value;
      return PatternAnimationFrame(
        label: '1 line ($idx/$total): ${line.label}',
        groups: [line.cells],
        index: idx,
        total: total,
        holdMs: _holdMs(holdMs),
      );
    }).toList();
  }

  static List<PatternAnimationFrame> _progressiveRevealFrames(
    Set<PatternAnimCell> cells,
    String label, {
    int drawMs = 1500,
    int holdMs = 1500,
  }) {
    final ordered = cells.toList()
      ..sort((a, b) {
        final rowCmp = a.row.compareTo(b.row);
        if (rowCmp != 0) return rowCmp;
        return a.col.compareTo(b.col);
      });
    if (ordered.isEmpty) {
      return [
        PatternAnimationFrame(
          label: label,
          groups: [cells],
          holdMs: _holdMs(holdMs),
        ),
      ];
    }

    final stepMs = _holdMs((drawMs / ordered.length).round());
    final frames = <PatternAnimationFrame>[];
    final acc = <PatternAnimCell>{};
    for (var i = 0; i < ordered.length; i++) {
      acc.add(ordered[i]);
      frames.add(
        PatternAnimationFrame(
          label: label,
          groups: [Set<PatternAnimCell>.from(acc)],
          index: i + 1,
          total: ordered.length,
          holdMs: stepMs,
        ),
      );
    }
    frames.add(
      PatternAnimationFrame(
        label: label,
        groups: [cells],
        index: ordered.length,
        total: ordered.length,
        holdMs: _holdMs(holdMs),
      ),
    );
    return frames;
  }

  static List<PatternAnimationFrame> _fixedShapeRevealFrames(
    Set<PatternAnimCell> cells,
    String label,
  ) {
    final ordered = cells.toList()
      ..sort((a, b) {
        final rowCmp = a.row.compareTo(b.row);
        if (rowCmp != 0) return rowCmp;
        return a.col.compareTo(b.col);
      });
    if (ordered.isEmpty) {
      return [
        PatternAnimationFrame(
          label: label,
          groups: [cells],
          holdMs: fixedShapeStepMs,
        ),
      ];
    }

    final frames = <PatternAnimationFrame>[];
    final acc = <PatternAnimCell>{};
    for (var i = 0; i < ordered.length; i++) {
      acc.add(ordered[i]);
      frames.add(
        PatternAnimationFrame(
          label: label,
          groups: [Set<PatternAnimCell>.from(acc)],
          index: i + 1,
          total: ordered.length,
          holdMs: fixedShapeStepMs,
        ),
      );
    }
    return frames;
  }

  static List<PatternAnimationFrame> buildForPattern(int pattern) {
    switch (pattern) {
      case BingoPatterns.allInOne:
      case BingoPatterns.lineOne:
        return _singleLineFrames(1500);
      case BingoPatterns.lineTwo:
        return _combinationFrames(2, _buildSingleLines(), 1500);
      case BingoPatterns.lineThree:
        return _combinationFrames(3, _buildSingleLines(), 1500);
      case BingoPatterns.full:
        return _fixedShapeRevealFrames(
          _cellsFromKeys(BingoPatterns.fullCells),
          'Full card',
        );
      case BingoPatterns.anyVertical:
        final cols = <PatternAnimationFrame>[];
        for (var c = 0; c < 5; c++) {
          cols.add(
            PatternAnimationFrame(
              label: '${_letters[c]} column',
              groups: [_colCells(c)],
              index: c + 1,
              total: 5,
              holdMs: _holdMs(1500),
            ),
          );
        }
        return cols;
      case BingoPatterns.anyHorizontal:
        final rows = <PatternAnimationFrame>[];
        for (var r = 0; r < 5; r++) {
          rows.add(
            PatternAnimationFrame(
              label: 'Row ${r + 1}',
              groups: [_rowCells(r)],
              index: r + 1,
              total: 5,
              holdMs: _holdMs(1500),
            ),
          );
        }
        return rows;
      default:
        final cells = BingoPatterns.cellsFor(pattern);
        if (cells.isNotEmpty) {
          final animCells = _cellsFromKeys(cells);
          if (BingoPatterns.isFixedShapePattern(pattern)) {
            return _fixedShapeRevealFrames(
              animCells,
              _staticLabel(pattern),
            );
          }
          return _progressiveRevealFrames(
            animCells,
            _staticLabel(pattern),
          );
        }
        return [
          PatternAnimationFrame(
            label: _staticLabel(pattern),
            groups: [{}],
            holdMs: _holdMs(1500),
          ),
        ];
    }
  }

  static String _staticLabel(int pattern) {
    return switch (pattern) {
      BingoPatterns.full => 'Full card',
      BingoPatterns.lShape => 'L shape',
      BingoPatterns.tShape => 'T shape',
      BingoPatterns.reverseTShape => 'Reverse T',
      BingoPatterns.xShape => 'X shape',
      BingoPatterns.reverseLShape => 'Reverse L',
      BingoPatterns.halfAbove => 'Top half',
      BingoPatterns.halfBelow => 'Bottom half',
      _ => 'Pattern',
    };
  }

  static int combinationCount(int pattern) {
    switch (pattern) {
      case BingoPatterns.allInOne:
      case BingoPatterns.lineOne:
        return 14;
      case BingoPatterns.lineTwo:
        return 91;
      case BingoPatterns.lineThree:
        return 364;
      case BingoPatterns.full:
        return 1;
      case BingoPatterns.anyVertical:
      case BingoPatterns.anyHorizontal:
        return 5;
      default:
        return 1;
    }
  }
}
