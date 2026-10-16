import 'package:flutter/material.dart';

import '../theme/bingo_colors.dart';
import '../../core/performance/resource_budget.dart';
import '../theme/bingo_typography.dart';
import 'bingo_board.dart';

/// Animated bingo ball — mirrors ethiomark `.ball2` … `.ball5` + `#rand`.
class BingoBall extends StatelessWidget {
  const BingoBall({
    super.key,
    required this.number,
    this.size = 180,
    this.shuffling = false,
    this.showBingoLetter = false,
    this.bounce = false,
    this.highlightLatest = false,
  });

  final int? number;
  final double size;
  final bool shuffling;
  final bool showBingoLetter;
  final bool bounce;
  final bool highlightLatest;

  @override
  Widget build(BuildContext context) {
    final ball = _BingoBallBody(
      number: number,
      size: size,
      shuffling: shuffling,
      showBingoLetter: showBingoLetter,
      highlightLatest: highlightLatest,
    );

    if (bounce && number != null) {
      return _BouncingCallBall(
        key: ValueKey('bounce-$number'),
        child: ball,
      );
    }

    return ball;
  }
}

class _BingoBallBody extends StatelessWidget {
  const _BingoBallBody({
    required this.number,
    required this.size,
    required this.shuffling,
    required this.showBingoLetter,
    required this.highlightLatest,
  });

  final int? number;
  final double size;
  final bool shuffling;
  final bool showBingoLetter;
  final bool highlightLatest;

  @override
  Widget build(BuildContext context) {
    final inner = size * 0.94;
    final core = size * (showBingoLetter ? 0.66 : 0.5);
    final hasNumber = number != null;
    final letter = hasNumber ? BingoBoard.letterFor(number!) : null;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (highlightLatest && hasNumber)
            Container(
              width: size * 1.08,
              height: size * 1.08,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: BingoColors.gold, width: 2.5),
                boxShadow: [
                  BoxShadow(
                    color: BingoColors.gold.withValues(alpha: 0.45),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const RadialGradient(
                center: Alignment(-0.25, -0.35),
                colors: [Color(0xFF1A1A1A), Colors.black],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.55),
                  blurRadius: 6,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
          ),
          Container(
            width: inner,
            height: inner,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: Color(0xFF418ADD),
            ),
          ),
          Container(
            width: inner * 0.94,
            height: inner * 0.94,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                center: Alignment(-0.2, -0.3),
                colors: [Color(0xFF09355E), Colors.black],
              ),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 1.0, end: shuffling ? 1.15 : 1.0),
            duration: const Duration(milliseconds: 800),
            curve: Curves.easeInOut,
            builder: (context, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
              width: core,
              height: core,
              clipBehavior: Clip.none,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: hasNumber ? Colors.white : const Color(0xFFE0E0E0),
                border: Border.all(
                  color: Colors.black.withValues(alpha: 0.22),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: hasNumber
                  ? showBingoLetter && letter != null
                      ? OverflowBox(
                          maxWidth: core * 1.25,
                          maxHeight: core * 1.3,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                letter,
                                style: BingoTypography.board(
                                  core * 0.28,
                                  _letterOnWhitePatch(letter),
                                ).copyWith(
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black12,
                                      offset: Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '$number',
                                style: BingoTypography.board(
                                  core * 0.48,
                                  BingoColors.lastCalled,
                                ).copyWith(
                                  shadows: const [
                                    Shadow(
                                      color: Colors.black26,
                                      offset: Offset(0, 1),
                                      blurRadius: 2,
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        )
                      : Text(
                          '$number',
                          style: BingoTypography.board(
                            size * 0.26,
                            BingoColors.lastCalled,
                          ),
                        )
                  : Text(
                      '—',
                      style: TextStyle(
                        fontSize: size * 0.2,
                        fontWeight: FontWeight.w700,
                        color: BingoColors.textSecondary,
                        height: 1,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  /// Dark/contrast colors for B-I-N-G-O letters on the white ball patch.
  static Color _letterOnWhitePatch(String letter) => switch (letter) {
    'B' => BingoColors.columnB,
    'I' => BingoColors.columnI,
    'N' => BingoColors.columnNText,
    'G' => Colors.black87,
    'O' => BingoColors.columnO,
    _ => Colors.black87,
  };
}

/// Bounce + slight drop when a new call lands in the recent-results row.
class _BouncingCallBall extends StatefulWidget {
  const _BouncingCallBall({super.key, required this.child});

  final Widget child;

  @override
  State<_BouncingCallBall> createState() => _BouncingCallBallState();
}

class _BouncingCallBallState extends State<_BouncingCallBall>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _drop;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    );
    _drop = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: -22.0, end: 0.0)
            .chain(CurveTween(curve: Curves.bounceOut)),
        weight: 55,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.0, end: -4.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 20,
      ),
      TweenSequenceItem(
        tween: Tween(begin: -4.0, end: 0.0)
            .chain(CurveTween(curve: Curves.easeIn)),
        weight: 25,
      ),
    ]).animate(_controller);
    _scale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween(begin: 0.55, end: 1.12)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 45,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 1.12, end: 0.96)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 25,
      ),
      TweenSequenceItem(
        tween: Tween(begin: 0.96, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 30,
      ),
    ]).animate(_controller);
    if (!ResourceBudget.reduceAnimations) {
      _controller.forward();
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
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _drop.value),
        child: Transform.scale(scale: _scale.value, child: child),
      ),
      child: widget.child,
    );
  }
}
