import 'package:flutter/material.dart';

import '../theme/bingo_colors.dart';

/// Wraps a control that is temporarily blocked. Shows a bold white-on-red
/// tooltip on hover; clicks are ignored.
class BlockedActionTooltip extends StatelessWidget {
  const BlockedActionTooltip({
    super.key,
    required this.reason,
    required this.child,
    this.disabledOpacity = 0.45,
  });

  final String? reason;
  final Widget child;
  final double disabledOpacity;

  @override
  Widget build(BuildContext context) {
    if (reason == null) return child;

    return Tooltip(
      message: reason!,
      preferBelow: false,
      waitDuration: const Duration(milliseconds: 120),
      showDuration: const Duration(seconds: 6),
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: BingoColors.lastCalled,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      textStyle: const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w800,
        height: 1.35,
      ),
      child: MouseRegion(
        cursor: SystemMouseCursors.forbidden,
        child: Opacity(
          opacity: disabledOpacity,
          child: AbsorbPointer(child: child),
        ),
      ),
    );
  }
}
