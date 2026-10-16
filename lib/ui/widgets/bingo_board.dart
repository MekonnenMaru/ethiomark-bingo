import 'package:flutter/material.dart';

import '../layout/responsive_layout.dart';

import '../theme/bingo_colors.dart';
import '../theme/bingo_typography.dart';
import '../../core/performance/resource_budget.dart';

class BingoBoard extends StatelessWidget {
  const BingoBoard({
    super.key,

    required this.calledNumbers,

    this.lastCalled,

    this.shuffleHighlight = false,

    this.zoom = 1.0,
  });

  final Set<int> calledNumbers;

  final int? lastCalled;

  final bool shuffleHighlight;

  final double zoom;

  static String letterFor(int n) {
    if (n <= 15) return 'B';

    if (n <= 30) return 'I';

    if (n <= 45) return 'N';

    if (n <= 60) return 'G';

    return 'O';
  }

  static int columnStart(String letter) => switch (letter) {
    'B' => 1,

    'I' => 16,

    'N' => 31,

    'G' => 46,

    'O' => 61,

    _ => 1,
  };

  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: context.isDesktop
          ? _buildDesktopRows(context)
          : _buildMobileColumns(context),
    );
  }

  /// ethiomark desktop: `.brow` / `.irow` — each letter is a horizontal row.
  /// Cell width follows available width; row height is scaled down so the board
  /// does not grow too tall on large displays.

  Widget _buildDesktopRows(BuildContext context) {
    const letters = ['B', 'I', 'N', 'G', 'O'];
    const rowGap = 4.0;
    const letterGap = 4.0;
    const minCell = 44.0;
    const maxCell = 100.0;
    const heightScale = 0.88;

    return LayoutBuilder(
      builder: (context, constraints) {
        final availW = constraints.maxWidth;

        final widthCell = (availW - letterGap) / 16;
        final baseWidth = widthCell.clamp(minCell, maxCell);
        final cellWidth = baseWidth * zoom;
        final rowHeight =
            (cellWidth * heightScale).clamp(minCell * zoom, cellWidth);
        final fontSize = (rowHeight * 0.58).clamp(20.0 * zoom, 52.0 * zoom);

        return Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: letters.map((letter) {
              final start = columnStart(letter);
              final shuffleColumn = shuffleHighlight &&
                  lastCalled != null &&
                  letterFor(lastCalled!) == letter;

              return Padding(
                padding: const EdgeInsets.only(bottom: rowGap),
                child: SizedBox(
                  height: rowHeight,
                  child: Row(
                    children: [
                      SizedBox(
                        width: cellWidth,
                        height: rowHeight,
                        child: _letterBox(
                          letter,
                          cellWidth,
                          cellHeight: rowHeight,
                          shuffleActive: shuffleColumn,
                        ),
                      ),
                      const SizedBox(width: letterGap),
                      ...List.generate(15, (i) {
                        final n = start + i;
                        return Expanded(
                          child: Center(
                            child: SizedBox(
                              width: cellWidth,
                              height: rowHeight,
                              child: _numberCell(
                                n,
                                cellWidth,
                                fontSize,
                                cellHeight: rowHeight,
                                forDesktop: true,
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        );
      },
    );
  }

  /// Mobile: vertical columns (compact portrait layout).

  Widget _buildMobileColumns(BuildContext context) {
    const letters = ['B', 'I', 'N', 'G', 'O'];
    final cellHeight = 32.0 * zoom;
    final fontSize = 17.0 * zoom;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: BingoColors.mobileBoardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: BingoColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: letters.map((letter) {
          final start = columnStart(letter);
          final shuffleColumn =
              shuffleHighlight &&
              lastCalled != null &&
              letterFor(lastCalled!) == letter;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 2),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: cellHeight,
                    child: _letterBox(
                      letter,
                      cellHeight,
                      compact: true,
                      fullWidth: true,
                      shuffleActive: shuffleColumn,
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...List.generate(15, (i) {
                    final n = start + i;

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: SizedBox(
                        width: double.infinity,
                        height: cellHeight,
                        child: _numberCell(
                          n,
                          cellHeight,
                          fontSize,
                          forMobile: true,
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          );
        }).toList(),
        ),
      ),
    );
  }

  Widget _letterBox(
    String letter,
    double size, {
    double? cellHeight,
    bool compact = false,
    bool fullWidth = false,
    bool shuffleActive = false,
  }) {
    final height = cellHeight ?? size;
    return AnimatedContainer(
      duration: Duration(milliseconds: shuffleHighlight ? 80 : 200),
      width: fullWidth ? double.infinity : size,
      height: height,
      decoration: BoxDecoration(
        color: shuffleActive ? BingoColors.gold : BingoColors.columnColor(letter),
        borderRadius: BorderRadius.circular(compact ? 8 : 10),
        border: shuffleActive
            ? Border.all(color: BingoColors.lastCalled, width: compact ? 2 : 3)
            : null,
        boxShadow: shuffleActive
            ? [
                BoxShadow(
                  color: BingoColors.gold.withValues(alpha: 0.7),
                  blurRadius: 10,
                ),
              ]
            : null,
      ),
      alignment: Alignment.center,
      child: Text(
        letter,
        style: BingoTypography.board(
          compact ? 18 : size * 0.45,
          shuffleActive ? Colors.black : BingoColors.columnTextColor(letter),
        ),
      ),
    );
  }

  Widget _numberCell(
    int n,
    double size,
    double fontSize, {
    double? cellHeight,
    bool forMobile = false,
    bool forDesktop = false,
  }) {
    final height = cellHeight ?? size;
    final called = calledNumbers.contains(n);

    final isLast = n == lastCalled;

    final shuffleActive = shuffleHighlight && isLast;

    Color bg;

    Color borderColor;

    Color textColor;

    double borderWidth = 1;

    if (shuffleActive) {
      bg = const Color(0xFFFFEB3B);

      borderColor = BingoColors.lastCalled;

      textColor = Colors.black;

      borderWidth = 3;
    } else if (shuffleHighlight) {
      bg = called
          ? BingoColors.called.withValues(alpha: 0.45)
          : forMobile
          ? BingoColors.mobileNumBoxBg.withValues(alpha: 0.7)
          : forDesktop
          ? BingoColors.desktopNumBoxBg.withValues(alpha: 0.55)
          : BingoColors.numBoxBg.withValues(alpha: 0.35);

      borderColor = forMobile
          ? BingoColors.mobileNumBoxBorder.withValues(alpha: 0.6)
          : forDesktop
          ? BingoColors.desktopNumBoxBorder.withValues(alpha: 0.6)
          : BingoColors.border.withValues(alpha: 0.5);

      textColor = called
          ? Colors.white.withValues(alpha: 0.7)
          : forMobile || forDesktop
          ? Colors.white.withValues(alpha: 0.5)
          : BingoColors.numBoxText.withValues(alpha: 0.45);
    } else if (isLast) {
      bg = BingoColors.lastCalled;

      borderColor = BingoColors.lastCalled;

      textColor = Colors.white;
    } else if (called) {
      bg = BingoColors.called;

      borderColor = BingoColors.primary.withValues(alpha: 0.5);

      textColor = Colors.white;
    } else {
      if (forMobile) {
        bg = BingoColors.mobileNumBoxBg;
        borderColor = BingoColors.mobileNumBoxBorder;
        textColor = Colors.white;
      } else if (forDesktop) {
        bg = BingoColors.desktopNumBoxBg;
        borderColor = BingoColors.desktopNumBoxBorder;
        textColor = Colors.white;
      } else {
        bg = BingoColors.numBoxBg;
        borderColor = BingoColors.border;
        textColor = BingoColors.numBoxText;
      }
    }

    final reduceFx = ResourceBudget.reduceDecorations;
    final decoration = BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(forMobile ? 6 : 8),
      border: Border.all(color: borderColor, width: borderWidth),
      boxShadow: reduceFx
          ? null
          : shuffleActive
              ? [
                  BoxShadow(
                    color: BingoColors.lastCalled.withValues(alpha: 0.85),
                    blurRadius: 12,
                    spreadRadius: 1,
                  ),
                  BoxShadow(
                    color: BingoColors.gold.withValues(alpha: 0.75),
                    blurRadius: 16,
                    spreadRadius: 2,
                  ),
                ]
              : isLast
                  ? [
                      BoxShadow(
                        color: BingoColors.lastCalled.withValues(alpha: 0.6),
                        blurRadius: 8,
                      ),
                    ]
                  : null,
    );

    final cell = reduceFx || !shuffleHighlight
        ? Container(
            width: double.infinity,
            height: height,
            decoration: decoration,
            alignment: Alignment.center,
            child: Text(
              '$n',
              style: BingoTypography.board(fontSize, textColor),
            ),
          )
        : AnimatedContainer(
            duration: Duration(milliseconds: shuffleHighlight ? 80 : 300),
            width: double.infinity,
            height: height,
            decoration: decoration,
            alignment: Alignment.center,
            child: Text(
              '$n',
              style: BingoTypography.board(fontSize, textColor),
            ),
          );

    if (!shuffleActive || reduceFx) return cell;

    return _ShufflePulse(child: cell);
  }
}

class _ShufflePulse extends StatefulWidget {
  const _ShufflePulse({required this.child});

  final Widget child;

  @override
  State<_ShufflePulse> createState() => _ShufflePulseState();
}

class _ShufflePulseState extends State<_ShufflePulse>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    if (!ResourceBudget.reduceAnimations) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (ResourceBudget.reduceAnimations) {
      return widget.child;
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final scale = 1 + (_controller.value * 0.08);

        return Transform.scale(scale: scale, child: child);
      },
      child: widget.child,
    );
  }
}
