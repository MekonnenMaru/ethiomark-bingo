import 'package:flutter/material.dart';

import '../../core/bingo/bingo_checker.dart';
import '../../core/performance/resource_budget.dart';
import '../../data/models/cartela.dart';
import '../theme/bingo_colors.dart';

class CartelaPreview extends StatelessWidget {
  const CartelaPreview({
    super.key,
    required this.cartela,
    required this.drawn,
    this.highlightCheck = false,
    this.highlightWinning,
    this.pattern,
    this.cellWidth = 44,
    this.cellPadding = 8,
    this.headerFontSize = 14,
    this.numberFontSize = 14,
    this.lightSurface = false,
    this.lastCalled,
    this.blinkLastCalled = false,
    this.winningHighlightColor,
  });

  final Cartela cartela;
  final List<int> drawn;
  final bool highlightCheck;
  final bool? highlightWinning;
  final int? pattern;
  final double cellWidth;
  final double cellPadding;
  final double headerFontSize;
  final double numberFontSize;
  final bool lightSurface;
  final int? lastCalled;
  final bool blinkLastCalled;
  final Color? winningHighlightColor;

  static const _lastCalledBlue = Color(0xFF2196F3);
  static const _lastCalledBlueDim = Color(0xFF1565C0);

  @override
  Widget build(BuildContext context) {
    final drawnSet = drawn.toSet();
    final showWinning = highlightWinning ?? highlightCheck;
    final winningCells = highlightCheck && showWinning
        ? BingoChecker.winningCellKeys(
            cartela,
            drawn,
            pattern: pattern,
          )
        : const <String>{};
    const headers = ['B', 'I', 'N', 'G', 'O'];
    final cols = [cartela.b, cartela.i, cartela.n, cartela.g, cartela.o];
    final activeLastCalled =
        lastCalled ?? (drawn.isNotEmpty ? drawn.last : null);
    final borderColor =
        lightSurface ? BingoColors.checkCardCellBorder : BingoColors.border;
    final headerSeparatorColor =
        lightSurface ? const Color(0xFF212121) : Colors.white.withValues(alpha: 0.45);

    Color headerBg(String letter) => lightSurface
        ? BingoColors.checkCardHeaderColor(letter)
        : BingoColors.columnColor(letter);

    Color headerText(String letter) => lightSurface
        ? BingoColors.checkCardHeaderTextColor(letter)
        : BingoColors.columnTextColor(letter);

    return Table(
      border: TableBorder.all(color: borderColor),
      defaultColumnWidth: FixedColumnWidth(cellWidth),
      children: [
        TableRow(
          children: headers
              .map(
                (h) => Container(
                  decoration: BoxDecoration(
                    color: headerBg(h),
                    border: Border(
                      bottom: BorderSide(
                        color: headerSeparatorColor,
                        width: lightSurface ? 5 : 2,
                      ),
                    ),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: cellPadding * 0.75,
                    vertical: lightSurface ? cellPadding * 1.1 : cellPadding * 0.75,
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    h,
                    style: TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: headerFontSize,
                      color: headerText(h),
                      letterSpacing: lightSurface ? 2 : 0,
                    ),
                  ),
                ),
              )
              .toList(),
        ),
        for (var r = 0; r < 5; r++)
          TableRow(
            children: List.generate(5, (c) {
              final colName = headers[c];
              final n = cols[c][r];
              final free = n == 0;
              final cellKey = '$colName:$r';
              final isWinning = winningCells.contains(cellKey);
              final isLastCalled =
                  !free && activeLastCalled != null && n == activeLastCalled;
              final isOtherCalled =
                  !free && !isLastCalled && drawnSet.contains(n);

              if (highlightCheck &&
                  isLastCalled &&
                  blinkLastCalled &&
                  !free) {
                return _BlinkingLastCalledCell(
                  padding: cellPadding,
                  number: n,
                  fontSize: numberFontSize,
                  brightColor: _lastCalledBlue,
                  dimColor: _lastCalledBlueDim,
                );
              }

              Color? bg;
              Color textColor;
              if (highlightCheck && isWinning) {
                bg = winningHighlightColor ?? BingoColors.primary;
                textColor = winningHighlightColor == BingoColors.gold
                    ? Colors.black
                    : Colors.white;
              } else if (highlightCheck && isLastCalled) {
                bg = _lastCalledBlue;
                textColor = Colors.white;
              } else if (highlightCheck && isOtherCalled) {
                bg = BingoColors.lastCalled;
                textColor = Colors.white;
              } else if (!highlightCheck && (free || drawnSet.contains(n))) {
                if (!free && isLastCalled) {
                  bg = _lastCalledBlue;
                  textColor = Colors.white;
                } else {
                  bg = BingoColors.called;
                  textColor = Colors.white;
                }
              } else if (lightSurface) {
                bg = BingoColors.checkCardCellBg;
                textColor =
                    free ? BingoColors.primaryDark : const Color(0xFF1F1F1F);
              } else {
                textColor = Colors.white;
              }

              return Container(
                color: bg,
                padding: EdgeInsets.all(cellPadding),
                child: Center(
                  child: Text(
                    free ? '★' : '$n',
                    style: TextStyle(
                      fontSize: numberFontSize,
                      fontWeight: FontWeight.w800,
                      color: textColor,
                    ),
                  ),
                ),
              );
            }),
          ),
      ],
    );
  }
}

class _BlinkingLastCalledCell extends StatefulWidget {
  const _BlinkingLastCalledCell({
    required this.padding,
    required this.number,
    required this.fontSize,
    required this.brightColor,
    required this.dimColor,
  });

  final double padding;
  final int number;
  final double fontSize;
  final Color brightColor;
  final Color dimColor;

  @override
  State<_BlinkingLastCalledCell> createState() => _BlinkingLastCalledCellState();
}

class _BlinkingLastCalledCellState extends State<_BlinkingLastCalledCell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
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
      return Container(
        padding: EdgeInsets.all(widget.padding),
        decoration: BoxDecoration(
          color: widget.brightColor,
          border: Border.all(
            color: widget.dimColor.withValues(alpha: 0.85),
            width: 2,
          ),
        ),
        child: Center(
          child: Text(
            '${widget.number}',
            style: TextStyle(
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ),
      );
    }
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final bg = Color.lerp(widget.brightColor, widget.dimColor, t)!;

        return Container(
          padding: EdgeInsets.all(widget.padding),
          decoration: BoxDecoration(
            color: bg,
            border: Border.all(
              color: widget.dimColor.withValues(alpha: 0.85),
              width: 2,
            ),
          ),
          child: child,
        );
      },
      child: Center(
        child: Text(
          '${widget.number}',
          style: TextStyle(
            fontSize: widget.fontSize,
            fontWeight: FontWeight.w900,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
