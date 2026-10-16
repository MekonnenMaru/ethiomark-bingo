import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/ui/modal_guard.dart';
import '../../core/bingo/bingo_checker.dart';
import '../../core/bingo/bingo_patterns.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/performance/resource_budget.dart';
import 'app_loading.dart';
import '../layout/responsive_layout.dart';
import '../theme/bingo_colors.dart';
import 'cartela_preview.dart';
import 'check_card_help_dialog.dart';
import 'win_celebration.dart';

/// Check result modal — mirrors ethiomark `#myModalcard` (cartela + Good/Not/Lock).
Future<void> showCheckCardModal({
  required BuildContext context,
  required int roundNumber,
  required int cardNumber,
  required BingoCheckResult result,
  required List<int> drawn,
  required bool autoMode,
  required Future<bool> Function() onGoodBingo,
  required Future<void> Function() onLock,
  VoidCallback? onNotBingo,
  Future<void> Function()? onTooLate,
  bool showBonusClaim = false,
  Future<bool> Function()? onClaimBonus,
  bool showBonusView = false,
  Future<void> Function()? onViewBonusCards,
}) async {
  return ModalGuard.run(
    ModalKeys.checkCard,
    () async {
      var bonusClaimReady = showBonusClaim;
      if (autoMode && result.isWinner && !result.isLocked) {
        bonusClaimReady = await onGoodBingo() || bonusClaimReady;
      }

      if (!context.mounted) return;

      final s = context.read<LocaleController>().strings;

      await showGeneralDialog<void>(
        context: context,
        useRootNavigator: true,
        barrierDismissible: false,
        barrierLabel: s.checkingCard,
        barrierColor: Colors.black.withValues(alpha: 0.65),
        transitionDuration: const Duration(milliseconds: 280),
        pageBuilder: (ctx, anim1, anim2) {
          return _CheckCardModalHost(
            navigatorContext: ctx,
            anim1: anim1,
            roundNumber: roundNumber,
            cardNumber: cardNumber,
            result: result,
            drawn: drawn,
            autoMode: autoMode,
            onGoodBingo: onGoodBingo,
            onLock: onLock,
            onNotBingo: onNotBingo,
            onTooLate: onTooLate,
            showBonusClaim: bonusClaimReady,
            onClaimBonus: onClaimBonus,
            showBonusView: showBonusView,
            onViewBonusCards: onViewBonusCards,
          );
        },
      );
    },
  );
}

class _CheckCardModalHost extends StatefulWidget {
  const _CheckCardModalHost({
    required this.navigatorContext,
    required this.anim1,
    required this.roundNumber,
    required this.cardNumber,
    required this.result,
    required this.drawn,
    required this.autoMode,
    required this.onGoodBingo,
    required this.onLock,
    this.onNotBingo,
    this.onTooLate,
    this.showBonusClaim = false,
    this.onClaimBonus,
    this.showBonusView = false,
    this.onViewBonusCards,
  });

  final BuildContext navigatorContext;
  final Animation<double> anim1;
  final int roundNumber;
  final int cardNumber;
  final BingoCheckResult result;
  final List<int> drawn;
  final bool autoMode;
  final Future<bool> Function() onGoodBingo;
  final Future<void> Function() onLock;
  final VoidCallback? onNotBingo;
  final Future<void> Function()? onTooLate;
  final bool showBonusClaim;
  final Future<bool> Function()? onClaimBonus;
  final bool showBonusView;
  final Future<void> Function()? onViewBonusCards;

  @override
  State<_CheckCardModalHost> createState() => _CheckCardModalHostState();
}

class _CheckCardModalHostState extends State<_CheckCardModalHost> {
  int _confettiBurst = 0;
  bool _dismissLocked = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoMode &&
        widget.result.isWinner &&
        !widget.result.isLocked) {
      _confettiBurst = 1;
    }
  }

  void _celebrate() {
    if (!mounted) return;
    setState(() => _confettiBurst++);
  }

  void _popModal() {
    if (!widget.navigatorContext.mounted) return;
    final navigator = Navigator.of(widget.navigatorContext, rootNavigator: true);
    if (navigator.canPop()) {
      navigator.pop();
    }
  }

  void _dismiss() {
    if (_dismissLocked) return;
    _popModal();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: _dismiss,
              behavior: HitTestBehavior.opaque,
            ),
          ),
          Center(
            child: GestureDetector(
              onTap: () {},
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: widget.anim1,
                  curve: Curves.easeOut,
                ),
                child: ScaleTransition(
                  scale: Tween<double>(begin: 0.92, end: 1).animate(
                    CurvedAnimation(
                      parent: widget.anim1,
                      curve: Curves.easeOutBack,
                    ),
                  ),
                  child: _CheckCardDialog(
                    roundNumber: widget.roundNumber,
                    cardNumber: widget.cardNumber,
                    result: widget.result,
                    drawn: widget.drawn,
                    autoMode: widget.autoMode,
                    onGoodBingo: widget.onGoodBingo,
                    onLock: widget.onLock,
                    onNotBingo: widget.onNotBingo,
                    onTooLate: widget.onTooLate,
                    showBonusClaim: widget.showBonusClaim,
                    onClaimBonus: widget.onClaimBonus,
                    showBonusView: widget.showBonusView,
                    onViewBonusCards: widget.onViewBonusCards,
                    onCelebrate: _celebrate,
                    onDismiss: _popModal,
                    helpContext: widget.navigatorContext,
                    onDismissLockedChanged: (locked) {
                      if (!mounted || _dismissLocked == locked) return;
                      setState(() => _dismissLocked = locked);
                    },
                  ),
                ),
              ),
            ),
          ),
          if (_confettiBurst > 0 && !ResourceBudget.reduceAnimations)
            ConfettiCelebration(
              key: ValueKey(_confettiBurst),
              pieceCount: ResourceBudget.lowMemory ? 40 : 200,
              burstCount: ResourceBudget.lowMemory ? 1 : 2,
            ),
        ],
      ),
    );
  }
}

class _CheckCardDialog extends StatefulWidget {
  const _CheckCardDialog({
    required this.roundNumber,
    required this.cardNumber,
    required this.result,
    required this.drawn,
    required this.autoMode,
    required this.onGoodBingo,
    required this.onLock,
    this.onNotBingo,
    this.onTooLate,
    this.showBonusClaim = false,
    this.onClaimBonus,
    this.showBonusView = false,
    this.onViewBonusCards,
    this.onCelebrate,
    required this.onDismiss,
    required this.helpContext,
    this.onDismissLockedChanged,
  });

  final int roundNumber;
  final int cardNumber;
  final BingoCheckResult result;
  final List<int> drawn;
  final bool autoMode;
  final Future<bool> Function() onGoodBingo;
  final Future<void> Function() onLock;
  final VoidCallback? onNotBingo;
  final Future<void> Function()? onTooLate;
  final bool showBonusClaim;
  final Future<bool> Function()? onClaimBonus;
  final bool showBonusView;
  final Future<void> Function()? onViewBonusCards;
  final VoidCallback? onCelebrate;
  final VoidCallback onDismiss;
  final BuildContext helpContext;
  final ValueChanged<bool>? onDismissLockedChanged;

  @override
  State<_CheckCardDialog> createState() => _CheckCardDialogState();
}

class _CheckCardDialogState extends State<_CheckCardDialog> {
  bool _busy = false;
  bool _latePatternRevealed = false;
  bool _bonusClaimed = false;
  late bool _showBonusClaim = widget.showBonusClaim;
  late bool _showBonusView = widget.showBonusView;
  _ManualReviewDecision? _manualDecision;

  Future<void> _run(
    Future<void> Function() action, {
    bool closeOnComplete = true,
  }) async {
    if (_busy) return;
    _setBusy(true);
    try {
      await action();
      if (!mounted) return;
      if (closeOnComplete) {
        _setBusy(false);
        if (!mounted) return;
        widget.onDismiss();
      }
    } finally {
      if (mounted && _busy) _setBusy(false);
    }
  }

  void _setBusy(bool busy) {
    if (!mounted) return;
    setState(() => _busy = busy);
    widget.onDismissLockedChanged?.call(busy);
  }

  void _close() {
    if (_busy) return;
    widget.onDismiss();
  }

  Future<void> _goodBingoManual() async {
    if (_busy) return;
    _setBusy(true);
    try {
      final ready = await widget.onGoodBingo();
      if (!mounted) return;
      widget.onCelebrate?.call();
      setState(() {
        _manualDecision = _ManualReviewDecision.good;
        if (ready) _showBonusClaim = true;
      });
    } finally {
      if (mounted) _setBusy(false);
    }
  }

  Future<void> _claimBonus() async {
    final claim = widget.onClaimBonus;
    if (claim == null || _busy || _bonusClaimed) return;
    _setBusy(true);
    try {
      final awarded = await claim();
      if (!mounted) return;
      setState(() {
        _bonusClaimed = true;
        _showBonusClaim = false;
        if (awarded) _showBonusView = true;
      });
    } finally {
      if (mounted) _setBusy(false);
    }
  }

  Future<void> _viewBonusCards() async {
    final view = widget.onViewBonusCards;
    if (view == null || _busy) return;
    _setBusy(true);
    try {
      await view();
    } finally {
      if (mounted) _setBusy(false);
    }
  }

  void _notBingoManual() {
    if (_busy) return;
    widget.onNotBingo?.call();
    setState(() => _manualDecision = _ManualReviewDecision.notBingo);
  }

  void _tooLateManual() {
    if (_busy) return;
    unawaited(widget.onTooLate?.call() ?? Future<void>.value());
    setState(() => _manualDecision = _ManualReviewDecision.tooLate);
  }

  void _toggleLatePattern() {
    if (_busy) return;
    setState(() => _latePatternRevealed = !_latePatternRevealed);
  }

  ({List<int> drawn, int callNumber})? _latePatternPreview() {
    final winAt = BingoChecker.firstWinningDrawIndex(
      cartela: widget.result.cartela,
      drawn: widget.drawn,
      pattern: widget.result.pattern,
    );
    if (winAt == null) return null;
    return (
      drawn: widget.drawn.sublist(0, winAt + 1),
      callNumber: winAt + 1,
    );
  }

  Widget _actionBtn({
    required String label,
    required Color bg,
    required bool desktop,
    Color fg = Colors.white,
    VoidCallback? onPressed,
  }) {
    return Expanded(
      child: SizedBox(
        height: desktop ? 40 : 34,
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: bg,
            foregroundColor: fg,
            padding: EdgeInsets.symmetric(
              horizontal: desktop ? 12 : 4,
              vertical: 0,
            ),
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            visualDensity: desktop ? VisualDensity.standard : VisualDensity.compact,
          ),
          onPressed: _busy ? null : onPressed,
          child: Text(
            label,
            style: TextStyle(
              fontSize: desktop ? 15 : 10,
              fontWeight: FontWeight.w800,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }

  Widget _claimBonusBtn({required bool desktop, required String label}) {
    return Expanded(
      flex: 2,
      child: _ClaimBonusButton(
        label: label,
        desktop: desktop,
        enabled: !_busy,
        onPressed: _claimBonus,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final desktop = context.isDesktop;
    final cellWidth = desktop ? 82.0 : 44.0;
    final cardWidth = cellWidth * 5 + 2;
    final isWinner = widget.result.isWinner;
    final isLateClaim = widget.result.isLateClaim;
    final showAutoWinner = widget.autoMode && isWinner && !widget.result.isLocked;
    final showManualWinner =
        _manualDecision == _ManualReviewDecision.good && !widget.autoMode;
    final showManualWinnerSuggest = !widget.autoMode &&
        !widget.result.isLocked &&
        isWinner &&
        _manualDecision != _ManualReviewDecision.notBingo;
    final showManualTooLate =
        _manualDecision == _ManualReviewDecision.tooLate && !widget.autoMode;
    final latePreview = _latePatternPreview();
    final tooLateEnabled = widget.result.claimMode.usesClaimWindow;
    final showLatePattern = tooLateEnabled &&
        widget.result.hadWinningPattern &&
        latePreview != null &&
        _latePatternRevealed;
    final showLatePatternToggle = tooLateEnabled &&
        widget.result.hadWinningPattern &&
        latePreview != null;
    final showLateWinnerSuggest = isLateClaim &&
        widget.result.hadWinningPattern &&
        !widget.result.isLocked &&
        (widget.autoMode ||
            _manualDecision != _ManualReviewDecision.notBingo);
    final showWinnerHighlight = showLatePattern ||
        showLateWinnerSuggest ||
        showManualWinner ||
        showManualWinnerSuggest ||
        (widget.autoMode &&
            isWinner &&
            !widget.result.isLocked &&
            !showLatePattern);
    final previewDrawn = showLatePattern ? latePreview.drawn : widget.drawn;
    final previewLastCalled =
        previewDrawn.isNotEmpty ? previewDrawn.last : null;
    final s = context.watch<LocaleController>().strings;

    String manualSuggestedStatus() {
      if (widget.result.isLocked) return s.cardLocked;
      if (isLateClaim) {
        return s.tooLateForMode(widget.result.claimMode);
      }
      if (isWinner) {
        if (BingoPatterns.isLinePattern(widget.result.pattern)) {
          return s.bingoLines(widget.result.winningLines);
        }
        return s.bingoPattern(s.patternName(widget.result.pattern));
      }
      return s.reviewCard;
    }

    final statusText = widget.autoMode
        ? (isLateClaim
            ? s.tooLateForMode(widget.result.claimMode)
            : widget.result.isLocked
            ? s.cardLocked
            : isWinner
            ? (BingoPatterns.isLinePattern(widget.result.pattern)
                ? s.bingoLines(widget.result.winningLines)
                : s.bingoPattern(s.patternName(widget.result.pattern)))
            : s.notWinner)
        : (_manualDecision == _ManualReviewDecision.good
            ? s.goodBingo
            : _manualDecision == _ManualReviewDecision.notBingo
            ? s.notWinner
            : _manualDecision == _ManualReviewDecision.tooLate
            ? (isLateClaim
                ? s.tooLateForMode(widget.result.claimMode)
                : s.tooLateClaim)
            : manualSuggestedStatus());

    final horizontalPad = desktop ? 10.0 : 8.0;
    final baseDialogWidth = cardWidth + horizontalPad * 2;
    // Fit card + action buttons; never stretch to full screen on desktop.
    final dialogWidth = desktop ? math.max(baseDialogWidth, 520.0) : baseDialogWidth;

    return WinnerDialogFrame(
        active: showAutoWinner || showManualWinner || showManualWinnerSuggest,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(desktop ? 14 : 15),
            border: Border.all(
              color: showAutoWinner
                  ? Colors.transparent
                  : const Color(0xFFD8D8D8),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.14),
                blurRadius: desktop ? 24 : 16,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxWidth: dialogWidth),
            child: SizedBox(
              width: dialogWidth,
              child: Padding(
              padding: EdgeInsets.fromLTRB(
                horizontalPad,
                desktop ? 8 : 6,
                horizontalPad,
                desktop ? 10 : 8,
              ),
              child: AppLoadingOverlay(
                loading: _busy,
                message: s.checkingCard,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                      _CheckCardHeader(
                        desktop: desktop,
                        roundNumber: widget.roundNumber,
                        cardNumber: widget.cardNumber,
                        patternLabel:
                            s.patternName(widget.result.pattern),
                        busy: _busy,
                        onHelp: () => showCheckCardHelpDialog(
                          widget.helpContext,
                          s,
                        ),
                        onClose: _close,
                      ),
                      SizedBox(height: desktop ? 8 : 6),
                      Padding(
                        padding: EdgeInsets.symmetric(
                          vertical: desktop ? 18 : 14,
                        ),
                        child: Center(
                          child: CartelaPreview(
                            cartela: widget.result.cartela,
                            drawn: previewDrawn,
                            highlightCheck: true,
                            highlightWinning: showWinnerHighlight,
                            pattern: widget.result.pattern,
                            cellWidth: cellWidth,
                            cellPadding: desktop ? 14 : 8,
                            headerFontSize: desktop ? 22 : 14,
                            numberFontSize: desktop ? 24 : 14,
                            lightSurface: true,
                            lastCalled: previewLastCalled,
                            blinkLastCalled: true,
                          ),
                        ),
                      ),
                      if (showLatePattern) ...[
                        const SizedBox(height: 6),
                        Text(
                          s.latePatternAtCall(latePreview.callNumber),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFFE65100),
                            fontWeight: FontWeight.w800,
                            fontSize: desktop ? 12 : 11,
                            height: 1.25,
                          ),
                        ),
                      ],
                      const SizedBox(height: 8),
                      Text(
                        statusText,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: desktop ? 14 : 13,
                          fontWeight: FontWeight.w800,
                          color: isLateClaim || showManualTooLate
                              ? BingoColors.lastCalled
                              : widget.result.isLocked
                              ? const Color(0xFFB8860B)
                              : showAutoWinner || showManualWinnerSuggest
                              ? BingoColors.primaryDark
                              : widget.autoMode
                              ? BingoColors.lastCalled
                              : isWinner
                              ? BingoColors.primaryDark
                              : const Color(0xFF424242),
                          height: 1.2,
                        ),
                      ),
                      if (isLateClaim || showManualTooLate) ...[
                        const SizedBox(height: 4),
                        Text(
                          s.bingoClaimModeHelp(widget.result.claimMode),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFF616161),
                            fontWeight: FontWeight.w700,
                            fontSize: desktop ? 11 : 10,
                            height: 1.3,
                          ),
                        ),
                      ],
                      if (showLatePatternToggle) ...[
                        SizedBox(height: desktop ? 8 : 6),
                        SizedBox(
                          height: desktop ? 36 : 32,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              backgroundColor: BingoColors.gold,
                              foregroundColor: Colors.black,
                              padding: EdgeInsets.symmetric(
                                horizontal: desktop ? 16 : 10,
                              ),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: _busy ? null : _toggleLatePattern,
                            child: Text(
                              _latePatternRevealed
                                  ? s.hidePatternBtn
                                  : s.seePatternBtn,
                              style: TextStyle(
                                fontSize: desktop ? 14 : 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                      if (widget.result.isLocked) ...[
                        const SizedBox(height: 2),
                        Text(
                          s.cardLocked,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: const Color(0xFFB8860B),
                            fontWeight: FontWeight.w800,
                            fontSize: desktop ? 12 : 11,
                          ),
                        ),
                      ],
                      if (_busy) ...[
                        const SizedBox(height: 6),
                        const Center(
                          child: AppButtonLoader(
                            color: BingoColors.primary,
                            size: 18,
                          ),
                        ),
                      ],
                      SizedBox(height: desktop ? 10 : 8),
                      if (widget.result.isLocked)
                        Row(
                          children: [
                            _actionBtn(
                              label: s.ok,
                              bg: const Color(0xFFE8E8E8),
                              fg: const Color(0xFF212121),
                              desktop: desktop,
                              onPressed: _close,
                            ),
                            if (_showBonusView &&
                                widget.onViewBonusCards != null) ...[
                              SizedBox(width: desktop ? 8 : 4),
                              _actionBtn(
                                label: s.bonusViewCards,
                                bg: BingoColors.gold,
                                fg: Colors.black,
                                desktop: desktop,
                                onPressed: _viewBonusCards,
                              ),
                            ],
                          ],
                        )
                      else if (widget.autoMode)
                        Row(
                          children: [
                            _actionBtn(
                              label: s.ok,
                              bg: const Color(0xFFE8E8E8),
                              fg: const Color(0xFF212121),
                              desktop: desktop,
                              onPressed: _close,
                            ),
                            if (_showBonusClaim && widget.onClaimBonus != null) ...[
                              SizedBox(width: desktop ? 8 : 4),
                              _claimBonusBtn(
                                desktop: desktop,
                                label: s.bonusClaim,
                              ),
                            ] else if (_showBonusView &&
                                widget.onViewBonusCards != null) ...[
                              SizedBox(width: desktop ? 8 : 4),
                              _actionBtn(
                                label: s.bonusViewCards,
                                bg: BingoColors.gold,
                                fg: Colors.black,
                                desktop: desktop,
                                onPressed: _viewBonusCards,
                              ),
                            ],
                            SizedBox(width: desktop ? 8 : 4),
                            _actionBtn(
                              label: s.lock,
                              bg: BingoColors.gold,
                              fg: Colors.black,
                              desktop: desktop,
                              onPressed: () => _run(widget.onLock),
                            ),
                          ],
                        )
                      else
                        desktop
                            ? Row(
                                children: [
                                  _actionBtn(
                                    label: s.good,
                                    bg: BingoColors.primary,
                                    desktop: desktop,
                                    onPressed: _goodBingoManual,
                                  ),
                                  SizedBox(width: desktop ? 8 : 4),
                                  _actionBtn(
                                    label: s.notBingo,
                                    bg: BingoColors.lastCalled,
                                    desktop: desktop,
                                    onPressed: _notBingoManual,
                                  ),
                                  SizedBox(width: desktop ? 8 : 4),
                                  _actionBtn(
                                    label: s.tooLateBtn,
                                    bg: const Color(0xFFE65100),
                                    desktop: desktop,
                                    onPressed: _tooLateManual,
                                  ),
                                  SizedBox(width: desktop ? 8 : 4),
                                  _actionBtn(
                                    label: s.lock,
                                    bg: BingoColors.gold,
                                    fg: Colors.black,
                                    desktop: desktop,
                                    onPressed: () => _run(widget.onLock),
                                  ),
                                ],
                              )
                            : Column(
                                children: [
                                  Row(
                                    children: [
                                      _actionBtn(
                                        label: s.good,
                                        bg: BingoColors.primary,
                                        desktop: desktop,
                                        onPressed: _goodBingoManual,
                                      ),
                                      const SizedBox(width: 4),
                                      _actionBtn(
                                        label: s.notBingo,
                                        bg: BingoColors.lastCalled,
                                        desktop: desktop,
                                        onPressed: _notBingoManual,
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      _actionBtn(
                                        label: s.tooLateBtn,
                                        bg: const Color(0xFFE65100),
                                        desktop: desktop,
                                        onPressed: _tooLateManual,
                                      ),
                                      const SizedBox(width: 4),
                                      _actionBtn(
                                        label: s.lock,
                                        bg: BingoColors.gold,
                                        fg: Colors.black,
                                        desktop: desktop,
                                        onPressed: () => _run(widget.onLock),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                    if (!widget.autoMode &&
                        !widget.result.isLocked &&
                        _showBonusClaim &&
                        widget.onClaimBonus != null) ...[
                      SizedBox(height: desktop ? 8 : 4),
                      Row(
                        children: [
                          _claimBonusBtn(
                            desktop: desktop,
                            label: s.bonusClaim,
                          ),
                        ],
                      ),
                    ],
                    if (!widget.autoMode &&
                        _showBonusView &&
                        !_showBonusClaim &&
                        widget.onViewBonusCards != null) ...[
                      SizedBox(height: desktop ? 8 : 4),
                      Row(
                        children: [
                          _actionBtn(
                            label: s.bonusViewCards,
                            bg: BingoColors.gold,
                            fg: Colors.black,
                            desktop: desktop,
                            onPressed: _viewBonusCards,
                          ),
                        ],
                      ),
                    ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
    );
  }
}

class _ClaimBonusButton extends StatefulWidget {
  const _ClaimBonusButton({
    required this.label,
    required this.desktop,
    required this.enabled,
    required this.onPressed,
  });

  final String label;
  final bool desktop;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  State<_ClaimBonusButton> createState() => _ClaimBonusButtonState();
}

class _ClaimBonusButtonState extends State<_ClaimBonusButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );
    if (widget.enabled && !ResourceBudget.reduceAnimations) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _ClaimBonusButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (ResourceBudget.reduceAnimations) {
      _pulse.stop();
      _pulse.value = 0;
      return;
    }
    if (widget.enabled && !_pulse.isAnimating) {
      _pulse.repeat(reverse: true);
    } else if (!widget.enabled && _pulse.isAnimating) {
      _pulse.stop();
      _pulse.value = 0;
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final desktop = widget.desktop;
    final height = desktop ? 46.0 : 38.0;

    return AnimatedBuilder(
      animation: _pulse,
      builder: (context, child) {
        final t = widget.enabled ? _pulse.value : 0.0;
        final glow = 8 + (t * 10);
        return Transform.scale(
          scale: 1 + (t * 0.035),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFFFC107).withValues(alpha: 0.35 + t * 0.35),
                  blurRadius: glow,
                  spreadRadius: 1 + t,
                ),
              ],
            ),
            child: child,
          ),
        );
      },
      child: SizedBox(
        height: height,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: widget.enabled ? widget.onPressed : null,
            borderRadius: BorderRadius.circular(10),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                gradient: const LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFFF59D),
                    Color(0xFFFFC107),
                    Color(0xFFFF8F00),
                  ],
                ),
                border: Border.all(color: const Color(0xFFFFE082), width: 1.5),
              ),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: desktop ? 10 : 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.card_giftcard_rounded,
                      size: desktop ? 20 : 16,
                      color: const Color(0xFF3E2723),
                    ),
                    SizedBox(width: desktop ? 8 : 4),
                    Flexible(
                      child: Text(
                        widget.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: desktop ? 16 : 12,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFF3E2723),
                          height: 1.1,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

enum _ManualReviewDecision { good, notBingo, tooLate }

class _CheckCardHeader extends StatelessWidget {
  const _CheckCardHeader({
    required this.desktop,
    required this.roundNumber,
    required this.cardNumber,
    required this.patternLabel,
    required this.busy,
    required this.onHelp,
    required this.onClose,
  });

  final bool desktop;
  final int roundNumber;
  final int cardNumber;
  final String patternLabel;
  final bool busy;
  final VoidCallback onHelp;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().strings;
    final labelStyle = TextStyle(
      fontSize: desktop ? 14 : 12,
      fontWeight: FontWeight.w800,
      color: const Color(0xFF616161),
      height: 1.2,
    );
    final valueStyle = TextStyle(
      fontSize: desktop ? 15 : 13,
      fontWeight: FontWeight.w800,
      color: const Color(0xFF1A1A1A),
      height: 1.2,
    );
    final patternStyle = TextStyle(
      fontSize: desktop ? 13 : 11,
      fontWeight: FontWeight.w800,
      color: const Color(0xFFB8860B),
      height: 1.2,
    );

    if (!desktop) {
      return Stack(
        clipBehavior: Clip.none,
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 52),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(s.roundLabel, style: labelStyle),
                    Text('$roundNumber', style: valueStyle),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(s.cardLabel, style: labelStyle),
                    Text('$cardNumber', style: valueStyle),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  patternLabel,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: patternStyle,
                ),
              ],
            ),
          ),
          Positioned(
            top: 0,
            right: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Tooltip(
                  message: s.checkCardHelpTooltip,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: busy ? null : onHelp,
                      borderRadius: BorderRadius.circular(4),
                      child: Container(
                        width: 24,
                        height: 24,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF5F5),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: BingoColors.accentRed,
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          '?',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: BingoColors.accentRed,
                            height: 1,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 28,
                  ),
                  onPressed: busy ? null : onClose,
                  icon: const Icon(
                    Icons.close,
                    size: 18,
                    color: Color(0xFF424242),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(s.roundLabel, style: labelStyle),
            Text('$roundNumber', style: valueStyle),
            const Spacer(),
            Tooltip(
              message: s.checkCardHelpTooltip,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: busy ? null : onHelp,
                  borderRadius: BorderRadius.circular(4),
                  child: Container(
                    width: desktop ? 26 : 24,
                    height: desktop ? 26 : 24,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF5F5),
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(
                        color: BingoColors.accentRed,
                        width: 1.5,
                      ),
                    ),
                    child: Text(
                      '?',
                      style: TextStyle(
                        fontSize: desktop ? 16 : 14,
                        fontWeight: FontWeight.w900,
                        color: BingoColors.accentRed,
                        height: 1,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SizedBox(width: desktop ? 4 : 2),
            IconButton(
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(
                minWidth: desktop ? 32 : 28,
                minHeight: desktop ? 32 : 28,
              ),
              onPressed: busy ? null : onClose,
              icon: Icon(
                Icons.close,
                size: desktop ? 20 : 18,
                color: const Color(0xFF424242),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(s.cardLabel, style: labelStyle),
            Text('$cardNumber', style: valueStyle),
            const Spacer(),
            Flexible(
              child: Text(
                patternLabel,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.right,
                style: patternStyle,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
