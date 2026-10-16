import 'package:flutter/material.dart';

import '../../core/config/register_prefs.dart';
import '../theme/bingo_colors.dart';

class FontSizeControls extends StatelessWidget {
  const FontSizeControls({
    super.key,
    required this.scale,
    required this.onDecrease,
    required this.onIncrease,
    this.compact = false,
    this.dense = false,
    this.minScale = RegisterPrefs.minFontScale,
    this.maxScale = RegisterPrefs.maxFontScale,
    this.barHeight,
  });

  final double scale;
  final VoidCallback onDecrease;
  final VoidCallback onIncrease;
  final bool compact;
  final bool dense;
  final double minScale;
  final double maxScale;
  final double? barHeight;

  bool get _canDecrease => scale > minScale + 0.001;
  bool get _canIncrease => scale < maxScale - 0.001;

  @override
  Widget build(BuildContext context) {
    final percent = (scale * 100).round();
    final height = barHeight;
    final buttonSize = height != null
        ? (height - 10).clamp(24.0, 34.0)
        : dense
        ? 24.0
        : (compact ? 32.0 : 36.0);

    final shell = Container(
      height: height,
      padding: EdgeInsets.symmetric(
        horizontal: dense ? 4 : (compact ? 6 : 8),
        vertical: height != null ? 0 : (dense ? 1 : (compact ? 2 : 4)),
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF0F2E50),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: BingoColors.accentTeal.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _roundButton(
            label: '−',
            size: buttonSize,
            enabled: _canDecrease,
            onTap: onDecrease,
          ),
          Padding(
            padding: EdgeInsets.symmetric(horizontal: dense ? 6 : (compact ? 8 : 10)),
            child: Text(
              '$percent%',
              style: TextStyle(
                color: Colors.white,
                fontSize: dense ? 11 : (compact ? 13 : 14),
                fontWeight: FontWeight.w700,
                decoration: TextDecoration.none,
              ),
            ),
          ),
          _roundButton(
            label: '+',
            size: buttonSize,
            enabled: _canIncrease,
            onTap: onIncrease,
          ),
        ],
      ),
    );

    if (height == null) return shell;

    return SizedBox(
      height: height,
      child: shell,
    );
  }

  Widget _roundButton({
    required String label,
    required double size,
    required bool enabled,
    required VoidCallback onTap,
  }) {
    return Material(
      color: enabled
          ? BingoColors.accentTeal
          : BingoColors.accentTeal.withValues(alpha: 0.35),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: enabled ? onTap : null,
        customBorder: const CircleBorder(),
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: size * 0.55,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
