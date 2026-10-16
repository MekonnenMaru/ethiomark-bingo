import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/bingo/bingo_patterns.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/performance/resource_budget.dart';
import '../theme/bingo_colors.dart';
import 'pattern_help_animator.dart';

/// Win-pattern preview beside [DerashBox] — animated, no outer box chrome.
class PlayPatternBox extends StatelessWidget {
  const PlayPatternBox({
    super.key,
    required this.pattern,
    this.onTap,
    this.compact = false,
  });

  final int pattern;
  final VoidCallback? onTap;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().strings;
    final normalized = BingoPatterns.normalize(pattern);
    final label = s.patternName(normalized);
    final animate = !ResourceBudget.reduceAnimations;

    final body = Padding(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 4 : 4,
        vertical: compact ? 2 : 0,
      ),
      child: compact
          ? _CompactBody(
              pattern: normalized,
              strings: s,
              animate: animate,
              label: label,
            )
          : _DesktopBody(
              pattern: normalized,
              strings: s,
              animate: animate,
              label: label,
            ),
    );

    final child = onTap == null
        ? body
        : GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: onTap,
            child: body,
          );

    if (compact) {
      return SizedBox(width: double.infinity, child: child);
    }

    // Content-sized height, top-aligned with Derash / recent titles.
    return Align(
      alignment: Alignment.topCenter,
      child: child,
    );
  }
}

class _DesktopBody extends StatelessWidget {
  const _DesktopBody({
    required this.pattern,
    required this.strings,
    required this.animate,
    required this.label,
  });

  final int pattern;
  final AppStrings strings;
  final bool animate;
  final String label;

  @override
  Widget build(BuildContext context) {
    // ~one cell taller than the previous 18px cells.
    const cellSize = 22.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: BingoColors.textPrimary,
            fontSize: 16,
            fontWeight: FontWeight.w600,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 6),
        IgnorePointer(
          child: RepaintBoundary(
            child: PatternHelpAnimator(
              pattern: pattern,
              strings: strings,
              isActive: animate,
              minimalChrome: true,
              cellSize: cellSize,
              holdScale: 2.0,
            ),
          ),
        ),
      ],
    );
  }
}

class _CompactBody extends StatelessWidget {
  const _CompactBody({
    required this.pattern,
    required this.strings,
    required this.animate,
    required this.label,
  });

  final int pattern;
  final AppStrings strings;
  final bool animate;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        IgnorePointer(
          child: RepaintBoundary(
            child: PatternHelpAnimator(
              pattern: pattern,
              strings: strings,
              isActive: animate,
              minimalChrome: true,
              cellSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: BingoColors.gold,
              fontSize: 12,
              fontWeight: FontWeight.w900,
              height: 1.1,
            ),
          ),
        ),
      ],
    );
  }
}
