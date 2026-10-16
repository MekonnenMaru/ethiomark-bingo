import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/locale_controller.dart';
import '../layout/responsive_layout.dart';
import '../theme/bingo_colors.dart';
import 'pool_ball.dart';

/// Last 4 calls: newest = largest on the left; older balls shrink to the right.
class RecentCallsPanel extends StatefulWidget {
  const RecentCallsPanel({
    super.key,
    required this.roundNumber,
    required this.drawn,
    this.callSpeedSeconds = 3,
  });

  final int roundNumber;
  final List<int> drawn;
  final int callSpeedSeconds;

  @override
  State<RecentCallsPanel> createState() => _RecentCallsPanelState();
}

class _BallEntry {
  _BallEntry({
    required this.number,
    required this.fromSlot,
    required this.toSlot,
  });

  final int number;
  double fromSlot;
  double toSlot;
}

class _RecentCallsPanelState extends State<RecentCallsPanel>
    with SingleTickerProviderStateMixin {
  static const _slotCount = 4;
  // Keep older balls large enough that digits stay readable.
  static const _sizeBySlot = [1.0, 0.92, 0.84, 0.76];

  final List<_BallEntry> _balls = [];
  late AnimationController _pushController;
  int _knownDrawnLength = 0;

  Duration get _pushDuration {
    // Push takes ~35% of the call interval — slow calls = slow push.
    final ms = (widget.callSpeedSeconds * 350).clamp(280, 3500);
    return Duration(milliseconds: ms);
  }

  @override
  void initState() {
    super.initState();
    _pushController = AnimationController(vsync: this);
    _pushController.duration = _pushDuration;
    _syncFromDrawn(animate: false);
  }

  @override
  void didUpdateWidget(RecentCallsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.callSpeedSeconds != oldWidget.callSpeedSeconds) {
      _pushController.duration = _pushDuration;
    }
    if (widget.drawn.length > _knownDrawnLength) {
      _onNewCall(widget.drawn.last);
      _knownDrawnLength = widget.drawn.length;
    } else if (widget.drawn.length < _knownDrawnLength) {
      _syncFromDrawn(animate: false);
    }
  }

  List<int> _lastFive(List<int> drawn) {
    if (drawn.length <= _slotCount) return List<int>.from(drawn);
    return drawn.sublist(drawn.length - _slotCount);
  }

  void _syncFromDrawn({required bool animate}) {
    _balls.clear();
    _knownDrawnLength = widget.drawn.length;
    if (widget.drawn.isEmpty) return;

    final recent = _lastFive(widget.drawn);
    for (var i = 0; i < recent.length; i++) {
      // recent[last] = newest → slot 0 (left, largest).
      final slot = (recent.length - 1 - i).toDouble();
      _balls.add(_BallEntry(number: recent[i], fromSlot: slot, toSlot: slot));
    }
    if (animate) {
      _pushController.duration = _pushDuration;
      _pushController.forward(from: 0);
    }
  }

  void _onNewCall(int number) {
    if (_balls.any((b) => b.toSlot == 0 && b.number == number)) return;

    for (final b in _balls) {
      b.fromSlot = b.toSlot;
      b.toSlot += 1;
    }
    _balls.removeWhere((b) => b.toSlot >= _slotCount);

    _balls.add(
      _BallEntry(
        number: number,
        fromSlot: -1.0,
        toSlot: 0.0,
      ),
    );

    _pushController.duration = _pushDuration;
    _pushController.forward(from: 0);
  }

  double _sizeScaleForSlot(double slot) {
    final s = slot.clamp(0.0, (_slotCount - 1).toDouble());
    final i = s.floor();
    final f = s - i;
    if (i >= _slotCount - 1) return _sizeBySlot.last;
    return _sizeBySlot[i] * (1 - f) + _sizeBySlot[i + 1] * f;
  }

  @override
  void dispose() {
    _pushController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().strings;
    final baseSize = context.isDesktop ? 72.0 : 56.0;
    final trackHeight = baseSize + 40;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          s.recentResultsFor(widget.roundNumber),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: BingoColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          height: trackHeight,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.22),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: BingoColors.accentTeal.withValues(alpha: 0.45),
            ),
          ),
          clipBehavior: Clip.none,
          child: widget.drawn.isEmpty
              ? _emptyTrack()
              : LayoutBuilder(
                  builder: (context, constraints) {
                    return AnimatedBuilder(
                      animation: _pushController,
                      builder: (context, _) {
                        final t = Curves.easeOutCubic.transform(
                          _pushController.value,
                        );
                        return _ballTrack(
                          width: constraints.maxWidth,
                          height: trackHeight,
                          baseSize: baseSize,
                          t: t,
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _emptyTrack() {
    final s = context.watch<LocaleController>().strings;
    return Center(
      child: Text(
        s.waitingForCalls,
        style: TextStyle(
          color: BingoColors.textSecondary.withValues(alpha: 0.8),
          fontSize: 14,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _ballTrack({
    required double width,
    required double height,
    required double baseSize,
    required double t,
  }) {
    final slotWidth = width / _slotCount;
    final sorted = [..._balls]..sort((a, b) => a.toSlot.compareTo(b.toSlot));

    return Stack(
      clipBehavior: Clip.none,
      children: [
        for (var s = 0; s < _slotCount; s++)
          Positioned(
            left: s * slotWidth + slotWidth / 2 - 1,
            top: 10,
            bottom: 10,
            child: Container(
              width: 2,
              color: Colors.white.withValues(alpha: 0.04),
            ),
          ),
        ...sorted.map((ball) {
          final slot = ball.fromSlot + (ball.toSlot - ball.fromSlot) * t;
          final size = baseSize * _sizeScaleForSlot(slot);
          final centerX = (slot + 0.5) * slotWidth;
          final isLatest = ball.toSlot <= 0.5;
          // Extra room for gold ring + bounce on the largest ball.
          final boxSize = isLatest ? size * 1.15 : size;

          return Positioned(
            left: centerX - boxSize / 2,
            top: (height - boxSize) / 2,
            width: boxSize,
            height: boxSize,
            child: PoolBall(
              number: ball.number,
              size: size,
              highlightLatest: isLatest,
              bounceContinuously: isLatest,
            ),
          );
        }),
      ],
    );
  }
}
