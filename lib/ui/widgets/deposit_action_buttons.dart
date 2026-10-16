import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/locale_controller.dart';
import '../../core/performance/resource_budget.dart';
import '../theme/bingo_colors.dart';

/// Strong pulsing glow + scale so deposit buttons stand out on phone support calls.
class _AttentionBlinkShell extends StatefulWidget {
  const _AttentionBlinkShell({
    required this.glowColor,
    required this.child,
  });

  final Color glowColor;
  final Widget child;

  @override
  State<_AttentionBlinkShell> createState() => _AttentionBlinkShellState();
}

class _AttentionBlinkShellState extends State<_AttentionBlinkShell>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
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
        final t = Curves.easeInOut.transform(_controller.value);
        return Transform.scale(
          scale: 0.92 + t * 0.08,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              boxShadow: [
                BoxShadow(
                  color: widget.glowColor.withValues(alpha: 0.35 + t * 0.65),
                  blurRadius: 6 + t * 18,
                  spreadRadius: 1 + t * 6,
                ),
                BoxShadow(
                  color: widget.glowColor.withValues(alpha: 0.2 + t * 0.5),
                  blurRadius: 24,
                  spreadRadius: 2 + t * 4,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}

class OfflineDepositButton extends StatefulWidget {
  const OfflineDepositButton({
    super.key,
    required this.onPressed,
    this.compact = false,
    this.tight = false,
    this.mini = false,
  });

  final VoidCallback onPressed;
  final bool compact;
  final bool tight;
  final bool mini;

  @override
  State<OfflineDepositButton> createState() => _OfflineDepositButtonState();
}

class _OfflineDepositButtonState extends State<OfflineDepositButton>
    with SingleTickerProviderStateMixin {
  static const _darkGreen = Color(0xFF166534);
  static const _brightGreen = Color(0xFF22C55E);

  late final AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    if (!ResourceBudget.reduceAnimations) {
      _blinkController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().strings;
    final desktop =
        widget.compact || widget.tight || (!widget.mini && !widget.compact);

    Widget buttonFor(Color bg, {double t = 0}) {
      final hPad = widget.tight
          ? 6.0
          : (widget.compact
              ? 10.0
              : (desktop ? 16.0 : (widget.mini ? 4.0 : 8.0)));
      final vPad = widget.tight
          ? 5.0
          : (widget.compact
              ? 8.0
              : (desktop ? 12.0 : (widget.mini ? 6.0 : 8.0)));
      final fontSize = widget.tight
          ? 10.0
          : (widget.compact
              ? 12.0
              : (desktop ? 15.0 : (widget.mini ? 8.0 : 10.0)));
      return _AttentionBlinkShell(
        glowColor: bg,
        child: FilledButton(
          onPressed: widget.onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            textStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
            ),
            tapTargetSize: (widget.mini || widget.compact || widget.tight)
                ? MaterialTapTargetSize.shrinkWrap
                : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            elevation: 2 + t * 6,
            shadowColor: _brightGreen.withValues(alpha: 0.85),
          ),
          child: Text(
            widget.mini || widget.tight
                ? s.offlineDepositShort
                : s.offlineDeposit,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    if (ResourceBudget.reduceAnimations) {
      return buttonFor(_brightGreen);
    }

    return AnimatedBuilder(
      animation: _blinkController,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_blinkController.value);
        return buttonFor(Color.lerp(_darkGreen, _brightGreen, t)!, t: t);
      },
    );
  }
}

class OnlineDepositButton extends StatefulWidget {
  const OnlineDepositButton({
    super.key,
    required this.onPressed,
    this.compact = false,
    this.tight = false,
    this.mini = false,
  });

  final VoidCallback onPressed;
  final bool compact;
  final bool tight;
  final bool mini;

  @override
  State<OnlineDepositButton> createState() => _OnlineDepositButtonState();
}

class _OnlineDepositButtonState extends State<OnlineDepositButton>
    with SingleTickerProviderStateMixin {
  static const _darkRed = Color(0xFF991B1B);
  static const _brightRed = Color(0xFFEF4444);

  late final AnimationController _blinkController;

  @override
  void initState() {
    super.initState();
    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 480),
    );
    if (!ResourceBudget.reduceAnimations) {
      _blinkController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().strings;
    final desktop =
        widget.compact || widget.tight || (!widget.mini && !widget.compact);

    Widget buttonFor(Color bg, {double t = 0}) {
      final hPad = widget.tight
          ? 6.0
          : (widget.compact
              ? 10.0
              : (desktop ? 18.0 : (widget.mini ? 4.0 : 10.0)));
      final vPad = widget.tight
          ? 5.0
          : (widget.compact
              ? 8.0
              : (desktop ? 12.0 : (widget.mini ? 6.0 : 8.0)));
      final fontSize = widget.tight
          ? 10.0
          : (widget.compact
              ? 12.0
              : (desktop ? 16.0 : (widget.mini ? 8.0 : 11.0)));
      return _AttentionBlinkShell(
        glowColor: bg,
        child: FilledButton(
          onPressed: widget.onPressed,
          style: FilledButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
            textStyle: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w800,
            ),
            tapTargetSize: (widget.mini || widget.compact || widget.tight)
                ? MaterialTapTargetSize.shrinkWrap
                : null,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            elevation: 2 + t * 6,
            shadowColor: _brightRed.withValues(alpha: 0.9),
          ),
          child: Text(
            widget.mini || widget.tight
                ? s.onlineDepositShort
                : s.onlineDeposit,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    if (ResourceBudget.reduceAnimations) {
      return buttonFor(_brightRed);
    }

    return AnimatedBuilder(
      animation: _blinkController,
      builder: (context, _) {
        final t = Curves.easeInOut.transform(_blinkController.value);
        return buttonFor(Color.lerp(_darkRed, _brightRed, t)!, t: t);
      },
    );
  }
}

class DepositHistoryButton extends StatelessWidget {
  const DepositHistoryButton({
    super.key,
    required this.onPressed,
    this.compact = false,
    this.tight = false,
    this.mini = false,
  });

  final VoidCallback onPressed;
  final bool compact;
  final bool tight;
  final bool mini;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().strings;
    final label = mini || tight ? s.depositHistoryShort : s.depositHistory;
    final iconSize = mini ? 14.0 : (tight ? 13.0 : (compact ? 16.0 : 18.0));
    final fontSize = mini ? 8.0 : (tight ? 10.0 : (compact ? 12.0 : 14.0));
    final hPad = mini ? 4.0 : (tight ? 6.0 : (compact ? 10.0 : 14.0));
    final vPad = mini ? 6.0 : (tight ? 5.0 : (compact ? 8.0 : 12.0));

    return OutlinedButton.icon(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: mini ? BingoColors.gold : Colors.white,
        side: BorderSide(
          color: mini
              ? BingoColors.gold.withValues(alpha: 0.85)
              : Colors.white.withValues(alpha: 0.55),
        ),
        backgroundColor: mini ? Colors.transparent : const Color(0xFF0F2E50),
        padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
        textStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
        ),
        tapTargetSize: (mini || compact || tight)
            ? MaterialTapTargetSize.shrinkWrap
            : null,
      ),
      icon: Icon(Icons.history, size: iconSize),
      label: Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
