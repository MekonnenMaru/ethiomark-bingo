import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../../services/sound_service.dart';
import '../layout/responsive_layout.dart';

/// Large hall-readable lucky-card overlay after Claim.
///
/// When [animate] is true, cards spin like AnbesaBingo (`bonus.js` reel) before
/// landing on the final lucky numbers one-by-one.
Future<void> showPlayerBonusClaimDialog({
  required BuildContext context,
  required String title,
  required String amountLabel,
  required List<int> luckyCards,
  required String closeLabel,
  String? spinningKicker,
  String? spinningTitle,
  String? revealedTitle,
  List<int>? spinPool,
  bool animate = false,
}) {
  return showGeneralDialog<void>(
    context: context,
    useRootNavigator: true,
    barrierDismissible: false,
    barrierLabel: title,
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (ctx, anim1, anim2) {
      return FadeTransition(
        opacity: anim1,
        child: _LuckyCardsOverlay(
          title: title,
          amountLabel: amountLabel,
          luckyCards: luckyCards,
          closeLabel: closeLabel,
          spinningKicker: spinningKicker ?? 'Spinning lucky cards...',
          spinningTitle: spinningTitle ?? 'Who is lucky?',
          revealedTitle: revealedTitle ?? title,
          spinPool: spinPool ?? luckyCards,
          animate: animate,
        ),
      );
    },
  );
}

class _LuckyCardsOverlay extends StatefulWidget {
  const _LuckyCardsOverlay({
    required this.title,
    required this.amountLabel,
    required this.luckyCards,
    required this.closeLabel,
    required this.spinningKicker,
    required this.spinningTitle,
    required this.revealedTitle,
    required this.spinPool,
    required this.animate,
  });

  final String title;
  final String amountLabel;
  final List<int> luckyCards;
  final String closeLabel;
  final String spinningKicker;
  final String spinningTitle;
  final String revealedTitle;
  final List<int> spinPool;
  final bool animate;

  @override
  State<_LuckyCardsOverlay> createState() => _LuckyCardsOverlayState();
}

class _LuckyCardsOverlayState extends State<_LuckyCardsOverlay>
    with TickerProviderStateMixin {
  late final List<int?> _display;
  late final List<bool> _spinning;
  late final List<bool> _landed;
  late final List<AnimationController> _shakeControllers;
  late final List<AnimationController> _lockControllers;
  bool _revealed = false;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    final n = widget.luckyCards.length;
    _display = List<int?>.filled(n, null);
    _spinning = List<bool>.filled(n, false);
    _landed = List<bool>.filled(n, !widget.animate);
    _shakeControllers = List.generate(
      n,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 120),
      ),
    );
    _lockControllers = List.generate(
      n,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 450),
      ),
    );

    if (!widget.animate) {
      for (var i = 0; i < n; i++) {
        _display[i] = widget.luckyCards[i];
        _landed[i] = true;
        _lockControllers[i].value = 1;
      }
      _revealed = true;
    } else {
      for (var i = 0; i < n; i++) {
        _spinning[i] = true;
        _shakeControllers[i].repeat(reverse: true);
      }
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) unawaited(_runSpinSequence());
      });
    }
  }

  @override
  void dispose() {
    for (final c in _shakeControllers) {
      c.dispose();
    }
    for (final c in _lockControllers) {
      c.dispose();
    }
    super.dispose();
  }

  List<int> get _pool {
    final pool = widget.spinPool.where((v) => v > 0).toList();
    if (pool.length >= 2) return pool;
    return List<int>.generate(75, (i) => i + 1);
  }

  int _randomFromPool(Set<int> exclude) {
    final pool = _pool;
    final options = pool.where((v) => !exclude.contains(v)).toList();
    final source = options.isNotEmpty ? options : pool;
    return source[Random().nextInt(source.length)];
  }

  Future<void> _runSpinSequence() async {
    if (_busy) return;
    _busy = true;
    for (var i = 0; i < widget.luckyCards.length; i++) {
      if (!mounted) return;
      await _spinCard(i, widget.luckyCards[i], 1400 + i * 350);
      if (!mounted) return;
      await Future<void>.delayed(const Duration(milliseconds: 220));
    }
    if (!mounted) return;
    setState(() => _revealed = true);
    unawaited(SoundService.instance.playBonusWinChime());
    _busy = false;
  }

  Future<void> _spinCard(int index, int finalValue, int durationMs) async {
    final started = DateTime.now();
    var lastTick = DateTime.fromMillisecondsSinceEpoch(0);
    final exclude = {finalValue};

    setState(() {
      _spinning[index] = true;
      _landed[index] = false;
      _display[index] = null;
    });
    if (!_shakeControllers[index].isAnimating) {
      _shakeControllers[index].repeat(reverse: true);
    }

    while (mounted) {
      final now = DateTime.now();
      final elapsed = now.difference(started).inMilliseconds;
      final progress = (elapsed / durationMs).clamp(0.0, 1.0);
      final intervalMs = 40 + progress * 140;
      if (now.difference(lastTick).inMilliseconds >= intervalMs) {
        lastTick = now;
        final next = _randomFromPool(exclude);
        setState(() => _display[index] = next);
        // Anbesa: playTick(480 + progress * 220, 0.04)
        unawaited(
          SoundService.instance.playBonusTick(
            frequency: 480 + progress * 220,
            durationSec: 0.04,
          ),
        );
      }
      if (progress >= 1) break;
      await Future<void>.delayed(const Duration(milliseconds: 16));
    }

    if (!mounted) return;
    _shakeControllers[index].stop();
    _shakeControllers[index].value = 0;
    setState(() {
      _display[index] = finalValue;
      _spinning[index] = false;
      _landed[index] = true;
    });
    unawaited(_lockControllers[index].forward(from: 0));
    // Anbesa: playTick(980, 0.16) on land
    unawaited(
      SoundService.instance.playBonusTick(frequency: 980, durationSec: 0.16),
    );
  }

  @override
  Widget build(BuildContext context) {
    final desktop = context.isDesktop;
    final size = MediaQuery.sizeOf(context);
    final count = widget.luckyCards.length.clamp(1, 6);
    final tile = desktop
        ? (size.width / (count + 1.6)).clamp(110.0, 180.0)
        : 92.0;
    final numberSize = desktop ? tile * 0.42 : 36.0;
    final titleSize = desktop ? 42.0 : 26.0;
    final amountSize = desktop ? 32.0 : 20.0;
    final kickerSize = desktop ? 16.0 : 12.0;
    final panelWidth = desktop
        ? (tile * count + 80).clamp(520.0, 980.0)
        : size.width * 0.92;

    final headline = !_revealed && widget.animate
        ? widget.spinningTitle
        : (_revealed && widget.animate
            ? widget.revealedTitle
            : widget.title);
    final kicker = !_revealed && widget.animate
        ? widget.spinningKicker
        : null;

    return Material(
      type: MaterialType.transparency,
      child: Center(
        child: AnimatedScale(
          scale: _revealed && widget.animate ? 1.0 : 0.99,
          duration: const Duration(milliseconds: 420),
          curve: Curves.easeOutBack,
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: panelWidth),
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFFFF8E1), Color(0xFFFFE082)],
                ),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFFFC107), width: 4),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x59000000),
                    blurRadius: 28,
                    offset: Offset(0, 12),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  const Positioned.fill(child: _BonusSparkles()),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      desktop ? 28 : 16,
                      desktop ? 24 : 16,
                      desktop ? 28 : 16,
                      desktop ? 22 : 14,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (kicker != null) ...[
                          Text(
                            kicker.toUpperCase(),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: kickerSize,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.2,
                              color: const Color(0xFFEF6C00),
                              height: 1.1,
                            ),
                          ),
                          SizedBox(height: desktop ? 8 : 6),
                        ],
                        Text(
                          headline,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: titleSize,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFF4E342E),
                            height: 1.1,
                          ),
                        ),
                        SizedBox(height: desktop ? 10 : 8),
                        Text(
                          widget.amountLabel,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: amountSize,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFB71C1C),
                            height: 1.15,
                          ),
                        ),
                        SizedBox(height: desktop ? 22 : 14),
                        Wrap(
                          spacing: desktop ? 16 : 10,
                          runSpacing: desktop ? 16 : 10,
                          alignment: WrapAlignment.center,
                          children: [
                            for (var i = 0; i < widget.luckyCards.length; i++)
                              _SpinCardTile(
                                size: tile,
                                numberSize: numberSize,
                                value: _display[i],
                                spinning: _spinning[i],
                                landed: _landed[i],
                                shake: _shakeControllers[i],
                                lock: _lockControllers[i],
                              ),
                          ],
                        ),
                        SizedBox(height: desktop ? 24 : 16),
                        SizedBox(
                          width: desktop ? 220 : double.infinity,
                          height: desktop ? 52 : 44,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFF1A1A1A),
                              foregroundColor: Colors.white,
                              disabledBackgroundColor:
                                  const Color(0xFF1A1A1A).withValues(alpha: 0.45),
                            ),
                            onPressed: (_revealed || !widget.animate)
                                ? () => Navigator.of(
                                      context,
                                      rootNavigator: true,
                                    ).pop()
                                : null,
                            child: Text(
                              widget.closeLabel,
                              style: TextStyle(
                                fontSize: desktop ? 20 : 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SpinCardTile extends StatelessWidget {
  const _SpinCardTile({
    required this.size,
    required this.numberSize,
    required this.value,
    required this.spinning,
    required this.landed,
    required this.shake,
    required this.lock,
  });

  final double size;
  final double numberSize;
  final int? value;
  final bool spinning;
  final bool landed;
  final AnimationController shake;
  final AnimationController lock;

  @override
  Widget build(BuildContext context) {
    final label = value == null ? '?' : '$value';

    Widget card = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: landed
              ? const [Color(0xFFFFF59D), Color(0xFFFFD54F)]
              : const [Color(0xFFFFE082), Color(0xFFFFCA28)],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: landed ? const Color(0xFFF57F17) : const Color(0xFFFF8F00),
          width: 3,
        ),
        boxShadow: landed
            ? const [
                BoxShadow(color: Colors.white, spreadRadius: 3),
                BoxShadow(
                  color: Color(0xFFFFEB3B),
                  blurRadius: 18,
                  spreadRadius: 1,
                ),
                BoxShadow(
                  color: Color(0x33000000),
                  blurRadius: 12,
                  offset: Offset(0, 8),
                ),
              ]
            : null,
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 70),
        transitionBuilder: (child, anim) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, -0.35),
              end: Offset.zero,
            ).animate(anim),
            child: FadeTransition(opacity: anim, child: child),
          );
        },
        child: Text(
          label,
          key: ValueKey('$label-$spinning-$landed'),
          style: TextStyle(
            fontSize: numberSize,
            fontWeight: FontWeight.w900,
            color: const Color(0xFF3E2723),
            height: 1,
          ),
        ),
      ),
    );

    if (spinning) {
      card = AnimatedBuilder(
        animation: shake,
        builder: (context, child) {
          final t = shake.value;
          final dy = (t - 0.5) * 6;
          final rot = (t - 0.5) * 0.05;
          return Transform.translate(
            offset: Offset(0, dy),
            child: Transform.rotate(angle: rot, child: child),
          );
        },
        child: card,
      );
    }

    if (landed) {
      card = AnimatedBuilder(
        animation: lock,
        builder: (context, child) {
          final t = Curves.easeOutBack.transform(lock.value.clamp(0.0, 1.0));
          final scale = 1.18 - (0.18 * t);
          final rot = (-0.10) + (0.10 * t);
          return Transform.rotate(
            angle: rot,
            child: Transform.scale(scale: scale, child: child),
          );
        },
        child: card,
      );
    }

    return card;
  }
}

class _BonusSparkles extends StatelessWidget {
  const _BonusSparkles();

  @override
  Widget build(BuildContext context) {
    return const IgnorePointer(
      child: CustomPaint(painter: _SparklePainter()),
    );
  }
}

class _SparklePainter extends CustomPainter {
  const _SparklePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = const Color(0xB3FFFFFF);
    void dot(double x, double y, double r) {
      canvas.drawCircle(Offset(size.width * x, size.height * y), r, paint);
    }

    dot(0.12, 0.20, 3);
    dot(0.88, 0.18, 3);
    dot(0.20, 0.80, 2);
    dot(0.80, 0.78, 2);
    dot(0.50, 0.08, 2);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
