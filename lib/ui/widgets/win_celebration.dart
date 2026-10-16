import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/bingo_colors.dart';

/// Full-screen confetti burst for a winning bingo card.
class ConfettiCelebration extends StatefulWidget {
  const ConfettiCelebration({
    super.key,
    this.pieceCount = 200,
    this.burstCount = 2,
    this.burstGap = 0.15,
  });

  /// Confetti pieces per burst.
  final int pieceCount;

  /// Number of staggered center bursts (auto-bingo uses 2).
  final int burstCount;

  /// Delay between bursts as a fraction of the animation (0–1).
  final double burstGap;

  @override
  State<ConfettiCelebration> createState() => _ConfettiCelebrationState();
}

class _ConfettiCelebrationState extends State<ConfettiCelebration>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final List<_ConfettiPiece> _pieces;
  late final Size _screenSize;
  final _random = math.Random();

  static const _colors = [
    Color(0xFFFFC107),
    Color(0xFF4CAF50),
    Color(0xFFE94560),
    Color(0xFF418ADD),
    Color(0xFFFF9800),
    Color(0xFF077C6C),
    Color(0xFFFFFFFF),
    Color(0xFFFF5722),
  ];

  @override
  void initState() {
    super.initState();
    final view = WidgetsBinding.instance.platformDispatcher.views.first;
    _screenSize = view.physicalSize / view.devicePixelRatio;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(
        milliseconds: 3200 + (widget.burstCount - 1) * 600,
      ),
    )..forward();

    _pieces = [
      for (var burst = 0; burst < widget.burstCount; burst++)
        ...List.generate(
          widget.pieceCount,
          (_) => _spawnBurst(startProgress: burst * widget.burstGap),
        ),
    ];
  }

  _ConfettiPiece _spawnBurst({required double startProgress}) {
    final centerX = _screenSize.width * 0.5;
    final centerY = _screenSize.height * 0.38;
    final angle = _random.nextDouble() * math.pi * 2;
    final speed = 6 + _random.nextDouble() * 14;

    return _ConfettiPiece(
      x: centerX + (_random.nextDouble() - 0.5) * 24,
      y: centerY + (_random.nextDouble() - 0.5) * 24,
      vx: math.cos(angle) * speed,
      vy: math.sin(angle) * speed - 3,
      rotation: _random.nextDouble() * math.pi * 2,
      spin: (_random.nextDouble() - 0.5) * 0.28,
      size: 5 + _random.nextDouble() * 7,
      color: _colors[_random.nextInt(_colors.length)],
      isCircle: _random.nextBool(),
      startProgress: startProgress,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = _controller.value;
            final fadeStart = 0.72;
            final fade = t > fadeStart ? (1 - (t - fadeStart) / (1 - fadeStart)) : 1.0;
            return CustomPaint(
              painter: _ConfettiPainter(
                pieces: _pieces,
                progress: t,
                opacity: fade.clamp(0.0, 1.0),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _ConfettiPiece {
  _ConfettiPiece({
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.rotation,
    required this.spin,
    required this.size,
    required this.color,
    required this.isCircle,
    required this.startProgress,
  });

  final double x;
  final double y;
  final double vx;
  final double vy;
  final double rotation;
  final double spin;
  final double size;
  final Color color;
  final bool isCircle;
  final double startProgress;
}

class _ConfettiPainter extends CustomPainter {
  _ConfettiPainter({
    required this.pieces,
    required this.progress,
    required this.opacity,
  });

  final List<_ConfettiPiece> pieces;
  final double progress;
  final double opacity;

  @override
  void paint(Canvas canvas, Size size) {
    for (final p in pieces) {
      final localProgress = progress - p.startProgress;
      if (localProgress <= 0) continue;

      final frames = (localProgress * 220).round();
      var x = p.x;
      var y = p.y;
      var rot = p.rotation;
      for (var i = 0; i < frames; i++) {
        x += p.vx;
        y += p.vy + 0.22;
        rot += p.spin;
      }

      if (x < -40 ||
          x > size.width + 40 ||
          y < -40 ||
          y > size.height + 40) {
        continue;
      }

      final paint = Paint()..color = p.color.withValues(alpha: opacity);
      canvas.save();
      canvas.translate(x, y);
      canvas.rotate(rot);
      if (p.isCircle) {
        canvas.drawCircle(Offset.zero, p.size / 2, paint);
      } else {
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: p.size,
            height: p.size * 0.55,
          ),
          paint,
        );
      }
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _ConfettiPainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.opacity != opacity;
}

/// Animated gold gradient frame around the whole winner check-card modal.
class WinnerDialogFrame extends StatefulWidget {
  const WinnerDialogFrame({
    super.key,
    required this.active,
    required this.child,
  });

  final bool active;
  final Widget child;

  @override
  State<WinnerDialogFrame> createState() => _WinnerDialogFrameState();
}

class _WinnerDialogFrameState extends State<WinnerDialogFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    if (widget.active) _controller.repeat(reverse: true);
  }

  @override
  void didUpdateWidget(covariant WinnerDialogFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat(reverse: true);
    } else if (!widget.active) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.active) return widget.child;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        return Container(
          padding: const EdgeInsets.all(3),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              begin: Alignment(-1 + t * 2, -1),
              end: Alignment(1 - t * 2, 1),
              colors: [
                Color.lerp(const Color(0xFFFFD54F), const Color(0xFF4CAF50), t)!,
                Color.lerp(const Color(0xFFFF9800), const Color(0xFFFFD54F), t)!,
                Color.lerp(const Color(0xFFE65100), const Color(0xFFFF9800), t)!,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: BingoColors.gold.withValues(alpha: 0.35 + t * 0.35),
                blurRadius: 14 + t * 10,
                spreadRadius: 1 + t,
              ),
            ],
          ),
          child: child,
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(15),
        child: widget.child,
      ),
    );
  }
}
