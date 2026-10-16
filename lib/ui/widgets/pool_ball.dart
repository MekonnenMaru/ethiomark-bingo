import 'package:flutter/material.dart';

import '../../core/performance/resource_budget.dart';
import '../theme/bingo_colors.dart';
import 'bingo_board.dart';

/// Glossy pool / billiard-style ball for recent-call display.
class PoolBall extends StatelessWidget {
  const PoolBall({
    super.key,
    required this.number,
    this.size = 52,
    this.highlightLatest = false,
    this.bounceContinuously = false,
  });

  final int number;
  final double size;
  final bool highlightLatest;
  final bool bounceContinuously;

  @override
  Widget build(BuildContext context) {
    final ball = _PoolBallBody(
      number: number,
      size: size,
      highlightLatest: highlightLatest,
    );

    if (bounceContinuously && !ResourceBudget.reduceAnimations) {
      return _ContinuousBounce(child: ball);
    }
    return ball;
  }
}

class _PoolBallBody extends StatelessWidget {
  const _PoolBallBody({
    required this.number,
    required this.size,
    required this.highlightLatest,
  });

  final int number;
  final double size;
  final bool highlightLatest;

  @override
  Widget build(BuildContext context) {
    final letter = BingoBoard.letterFor(number);
    final base = _poolColor(letter);
    // Thin colored rim — white patch gets most of the diameter for readable digits.
    final patchSize = size * 0.80;
    final letterSize = (size * 0.15).clamp(8.0, 16.0);
    final numberSize = (size * 0.40).clamp(12.0, 30.0);
    final rimWidth = (size * 0.018).clamp(0.8, 1.2);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          if (highlightLatest)
            Container(
              width: size * 1.08,
              height: size * 1.08,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: BingoColors.gold, width: 1.6),
                boxShadow: ResourceBudget.reduceDecorations
                    ? null
                    : [
                        BoxShadow(
                          color: BingoColors.gold.withValues(alpha: 0.35),
                          blurRadius: 6,
                        ),
                      ],
              ),
            ),
          CustomPaint(
            size: Size(size, size),
            painter: _PoolBallSpherePainter(
              baseColor: base,
              simple: ResourceBudget.reduceDecorations,
            ),
          ),
          Container(
            width: patchSize,
            height: patchSize,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white,
              border: Border.all(
                color: Colors.black.withValues(alpha: 0.14),
                width: rimWidth,
              ),
            ),
            alignment: Alignment.center,
            child: Padding(
              padding: EdgeInsets.all(size * 0.04),
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      letter,
                      style: TextStyle(
                        fontSize: letterSize,
                        fontWeight: FontWeight.w800,
                        color: _letterColor(letter),
                        height: 1,
                      ),
                    ),
                    Text(
                      '$number',
                      style: TextStyle(
                        fontSize: numberSize,
                        fontWeight: FontWeight.w900,
                        color: BingoColors.lastCalled,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static Color _poolColor(String letter) {
    return switch (letter) {
      'B' => const Color(0xFFD32F2F),
      'I' => const Color(0xFF1565C0),
      'N' => const Color(0xFFF5F5F5),
      'G' => const Color(0xFFF9A825),
      'O' => const Color(0xFF2E7D32),
      _ => const Color(0xFF455A64),
    };
  }

  static Color _letterColor(String letter) {
    return switch (letter) {
      'B' => BingoColors.columnB,
      'I' => BingoColors.columnI,
      'N' => BingoColors.columnNText,
      'G' => Colors.black87,
      'O' => BingoColors.columnO,
      _ => Colors.black87,
    };
  }
}

class _PoolBallSpherePainter extends CustomPainter {
  _PoolBallSpherePainter({
    required this.baseColor,
    this.simple = false,
  });

  final Color baseColor;
  final bool simple;

  @override
  void paint(Canvas canvas, Size size) {
    final r = size.width / 2;
    final center = Offset(r, r);

    if (simple) {
      canvas.drawCircle(center, r * 0.96, Paint()..color = baseColor);
      return;
    }

    final lightBall = baseColor.computeLuminance() > 0.7;

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(r, size.height * 0.96),
        width: r * 1.3,
        height: r * 0.2,
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.3),
    );

    final sphere = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.42, -0.48),
        radius: 0.95,
        colors: [
          Color.lerp(baseColor, Colors.white, lightBall ? 0.12 : 0.4)!,
          baseColor,
          Color.lerp(baseColor, Colors.black, 0.5)!,
        ],
        stops: const [0.0, 0.45, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: r));

    canvas.drawCircle(center, r * 0.96, sphere);

    canvas.drawCircle(
      Offset(r - r * 0.28, r - r * 0.3),
      r * 0.12,
      Paint()..color = Colors.white.withValues(alpha: 0.75),
    );
  }

  @override
  bool shouldRepaint(covariant _PoolBallSpherePainter oldDelegate) =>
      oldDelegate.baseColor != baseColor || oldDelegate.simple != simple;
}

/// Gentle non-stop bounce on the latest called ball.
class _ContinuousBounce extends StatefulWidget {
  const _ContinuousBounce({required this.child});

  final Widget child;

  @override
  State<_ContinuousBounce> createState() => _ContinuousBounceState();
}

class _ContinuousBounceState extends State<_ContinuousBounce>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _lift;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    )..repeat(reverse: true);
    _lift = Tween(begin: 0.0, end: -5.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _scale = Tween(begin: 1.0, end: 1.06).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) => Transform.translate(
        offset: Offset(0, _lift.value),
        child: Transform.scale(scale: _scale.value, child: child),
      ),
      child: widget.child,
    );
  }
}
