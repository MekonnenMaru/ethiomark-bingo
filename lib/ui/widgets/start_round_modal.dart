import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_assets.dart';
import '../../core/config/app_currency.dart';
import '../../core/bingo/income_calculator.dart';
import '../../core/bingo/player_bonus.dart';
import '../../core/trial/trial_prefs.dart';
import '../../core/trial/trial_service.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/ui/modal_guard.dart';
import '../../data/models/cashier_session.dart';
import '../../data/models/game_round.dart';
import '../../data/repositories/game_repository.dart';
import '../../services/sound_service.dart';
import '../layout/responsive_layout.dart';
import '../theme/bingo_colors.dart';
import 'app_loading.dart';
import 'app_toast.dart';
import 'trial_progress_banner.dart';
import 'wallet_exceeded_alert.dart';

const _packageLowThreshold = 1000.0;
const _startModalOverlay = Color.fromRGBO(0, 1, 0, 0.7);
const _startModalHeaderBg = Color(0xFF0B778A);
const _startModalHeaderBtnBg = Color(0xFF0D4742);
const _startModalHeaderBtnHover = Color(0xFFE68A00);
const _startModalRegisterHover = Color(0xFF0B3B36);
const _startModalBodyBg = Color(0xFFF6F7F9);
const _startModalDerashColor = Color(0xFFF30000);
const _startModalStartBtnBorder = Color.fromRGBO(3, 54, 53, 1);
const _startModalStartBtnHover = Color(0xFF0B3B36);
const _startModalContentRadius = 10.0;
const _startModalContentOpacity = 0.95;
/// Matches prior start-button slot width (~50% dialog × 80% slot).
const _startModalWidthScreenFactor = 0.44;
/// Start / trial actions span the full narrow modal width.
const _startModalActionSlotFactor = 1.0;

/// Mirrors ethiomark `index.php` `#myModal` — round summary before drawing starts.
Future<bool> showStartRoundModal({
  required BuildContext context,
  required CashierSession session,
  required GameRound game,
  required GameRepository gameRepository,
  required VoidCallback onEditCards,
  VoidCallback? onOpenReport,
  Future<void> Function()? onBalanceChanged,
  Future<void> Function()? onLogout,
}) async {
  final result = await ModalGuard.run<bool>(
    ModalKeys.startRound,
    () async {
      final profile = await gameRepository.getCashierProfile(session.cashierId);
  final income = IncomeCalculator.calculateIncome(
    sew: game.cardCount,
    santim: game.price,
    cashierProfit: profile.cashierProfit,
    tiers: profile.profitTiers,
    usePartnerCommissionTiers: profile.usePartnerCommissionTiers,
    startGetMoneyFrom: profile.startGetMoneyFrom,
    allowIncomeRounding: profile.allowIncomeRounding,
    lockRoundUpLastDigit: profile.lockRoundUpLastDigit,
  );
  final derash = IncomeCalculator.calculateDerash(
    sew: game.cardCount,
    santim: game.price,
    cashierProfit: profile.cashierProfit,
    tiers: profile.profitTiers,
    usePartnerCommissionTiers: profile.usePartnerCommissionTiers,
    startGetMoneyFrom: profile.startGetMoneyFrom,
    allowIncomeRounding: profile.allowIncomeRounding,
    lockRoundUpLastDigit: profile.lockRoundUpLastDigit,
  );
  final prizeAmount = 0.0;
  final bonusOn = PlayerBonusSettings.fromSettings(profile.settings).isEnabled;
  if (!context.mounted) return false;

  var saving = false;
  final packageBalance = session.packageBalance;
  final packageAmount = double.tryParse(packageBalance) ?? 0;
  final showPackageWarning = packageAmount < _packageLowThreshold;
  final trialRoundsUsed = await TrialPrefs.loadRoundsUsed(session.cashierId);
  final showTrialBanner = TrialService.isActiveTrial(
        packageBalance: packageBalance,
        roundsUsed: trialRoundsUsed,
      ) ||
      TrialService.isTrialExhausted(
        packageBalance: packageBalance,
        roundsUsed: trialRoundsUsed,
      );
  final trialExhausted = TrialService.isTrialExhausted(
    packageBalance: packageBalance,
    roundsUsed: trialRoundsUsed,
  );

  return await showDialog<bool>(
        context: context,
        barrierDismissible: false,
        barrierColor: _startModalOverlay,
        builder: (ctx) {
          final s = ctx.watch<LocaleController>().strings;
          return StatefulBuilder(
            builder: (context, setModalState) {
              return AppLoadingOverlay(
                loading: saving,
                message: s.startingRound,
                child: _StartRoundDialog(
                  game: game,
                  derash: derash,
                  prizeAmount: prizeAmount,
                  bonusOn: bonusOn,
                  currencyCode: AppCurrency.fromSettings(profile.settings),
                  packageBalance: packageBalance,
                  showPackageWarning: showPackageWarning,
                  showTrialBanner: showTrialBanner,
                  trialRoundsUsed: trialRoundsUsed,
                  trialExhausted: trialExhausted,
                  saving: saving,
                  onEditCards: () {
                    Navigator.pop(ctx, false);
                    onEditCards();
                  },
                  onOpenReport: onOpenReport == null
                      ? null
                      : () {
                          Navigator.pop(ctx, false);
                          onOpenReport();
                        },
                  onLogout: onLogout == null
                      ? null
                      : () async {
                          final ok = await showDialog<bool>(
                            context: ctx,
                            builder: (dialogCtx) => AlertDialog(
                              title: Text(s.logoutConfirmTitle),
                              content: Text(s.logoutConfirmBody),
                              actions: [
                                TextButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogCtx, false),
                                  child: Text(s.cancel),
                                ),
                                FilledButton(
                                  onPressed: () =>
                                      Navigator.pop(dialogCtx, true),
                                  child: Text(s.logout),
                                ),
                              ],
                            ),
                          );
                          if (ok != true) return;
                          Navigator.pop(ctx, false);
                          await onLogout();
                        },
                  onStart: () async {
                    setModalState(() => saving = true);
                    final result = await gameRepository.saveTransaction(
                      cashierId: session.cashierId,
                      roundNumber: game.roundNumber,
                      santim: game.price,
                      sew: game.cardCount,
                      income: income,
                      bonusAmount: prizeAmount,
                    );
                    if (!context.mounted) return;
                    if (result['status'] == 'success') {
                      final toggles =
                          profile.settings['toggles']
                              as Map<String, dynamic>? ??
                          {};
                      if (toggles['will_start'] != false) {
                        SoundService.instance.playWillStart();
                      }
                      await onBalanceChanged?.call();
                      if (!context.mounted) return;
                      Navigator.pop(ctx, true);
                    } else {
                      setModalState(() => saving = false);
                      if (isWalletExceededResult(result) ||
                          TrialService.isTrialExhaustedResult(result)) {
                        final balance =
                            result['package'] as String? ??
                            session.packageBalance;
                        final message = TrialService.isTrialExhaustedResult(result)
                            ? s.freeTrialExhaustedBody
                            : s.transactionExceedsWallet(
                                balance,
                                AppCurrency.fromSettings(profile.settings),
                              );
                        if (!context.mounted) return;
                        await showWalletExceededAlert(
                          context,
                          message: message,
                          reportLabel: s.goToProfileAction,
                          closeLabel: s.close,
                          onOpenReport: onOpenReport,
                        );
                      } else if (TrialService.isTrialRulesResult(result)) {
                        showAppToast(
                          context,
                          s.freeTrialRulesViolation(
                            AppCurrency.fromSettings(profile.settings),
                          ),
                          type: AppToastType.error,
                        );
                      } else {
                        showAppToast(
                          context,
                          '${result['message']}',
                          type: AppToastType.error,
                        );
                      }
                    }
                  },
                ),
              );
            },
          );
        },
      ) ??
      false;
    },
    blockedValue: false,
  );
  return result ?? false;
}

class _StartRoundDialog extends StatelessWidget {
  const _StartRoundDialog({
    required this.game,
    required this.derash,
    required this.prizeAmount,
    required this.bonusOn,
    required this.currencyCode,
    required this.packageBalance,
    required this.showPackageWarning,
    required this.showTrialBanner,
    required this.trialRoundsUsed,
    required this.trialExhausted,
    required this.saving,
    required this.onEditCards,
    this.onOpenReport,
    this.onLogout,
    required this.onStart,
  });

  final GameRound game;
  final double derash;
  final double prizeAmount;
  final bool bonusOn;
  final String currencyCode;
  final String packageBalance;
  final bool showPackageWarning;
  final bool showTrialBanner;
  final int trialRoundsUsed;
  final bool trialExhausted;
  final bool saving;
  final VoidCallback onEditCards;
  final VoidCallback? onOpenReport;
  final Future<void> Function()? onLogout;
  final VoidCallback onStart;

  Widget _actionWidthSlot({required Widget child}) {
    return Center(
      child: FractionallySizedBox(
        widthFactor: _startModalActionSlotFactor,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().strings;
    final patternLabel =
        s.selectedPatternLabel(s.patternName(game.pattern));

    final m = _StartRoundMetrics(
      context,
      showTrialBanner: showTrialBanner,
      showPackageWarning: showPackageWarning,
      trialExhausted: trialExhausted,
      showBonus: prizeAmount > 0,
    );

    return Dialog(
      backgroundColor: Colors.white.withValues(alpha: _startModalContentOpacity),
      alignment: Alignment.center,
      insetPadding: EdgeInsets.fromLTRB(
        m.insetH,
        m.insetTop,
        m.insetH,
        m.insetBottom,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_startModalContentRadius),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.08)),
      ),
      clipBehavior: Clip.antiAlias,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: _startModalContentOpacity),
          borderRadius: BorderRadius.circular(_startModalContentRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: m.dialogWidth,
            minWidth: m.desktop ? m.dialogWidth : 0,
            maxHeight: m.maxDialogHeight,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(
                  m.headerPadH,
                  m.headerPadV,
                  m.headerPadH,
                  m.headerPadV,
                ),
                decoration: BoxDecoration(
                  color: _startModalHeaderBg,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(_startModalContentRadius),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color.fromRGBO(50, 50, 50, 0.55),
                      blurRadius: 6,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Text(
                      s.roundShort(game.roundNumber),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: m.roundTitleSize,
                        color: Colors.white,
                      ),
                    ),
                    const Spacer(),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: _headerButtons(m, s),
                    ),
                  ],
                ),
              ),
              Flexible(
                fit: FlexFit.loose,
                child: _buildScrollableBody(m, s, patternLabel),
              ),
              ColoredBox(
                color: _startModalBodyBg,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    m.bodyPad,
                    0,
                    m.bodyPad,
                    m.bodyPad,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (showTrialBanner) ...[
                        TrialProgressBanner(
                          roundsUsed: trialRoundsUsed,
                          currencyCode: currencyCode,
                          minimal: true,
                          variant: TrialBannerVariant.light,
                          exhausted: trialExhausted,
                          onOpenReport: onOpenReport,
                        ),
                        SizedBox(height: m.footerGap),
                      ],
                      if (showPackageWarning && !showTrialBanner) ...[
                        _BlinkingPackageLowWarning(
                          metrics: m,
                          packageBalance: packageBalance,
                          currencyCode: currencyCode,
                        ),
                        SizedBox(height: m.footerGap),
                      ],
                      _actionWidthSlot(
                        child: _StartRoundStartButton(
                          metrics: m,
                          label: s.start,
                          saving: saving,
                          enabled: !trialExhausted && !saving,
                          onPressed: onStart,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScrollableBody(
    _StartRoundMetrics m,
    AppStrings s,
    String patternLabel,
  ) {
    final titleWidget = derash > 0
        ? Text(
            s.derashAmountLabel(derash, currencyCode),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: m.derashSize,
              fontWeight: FontWeight.w800,
              color: _startModalDerashColor,
              height: 1.15,
            ),
          )
        : Text(
            s.appName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: m.appTitleSize,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
              color: _startModalDerashColor,
            ),
          );

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxH = constraints.hasBoundedHeight
            ? math.min(m.maxBodyScrollHeight, constraints.maxHeight)
            : m.maxBodyScrollHeight;
        return ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxH),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            child: Padding(
              padding: EdgeInsets.all(m.bodyPad),
              child: ColoredBox(
                color: _startModalBodyBg,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    titleWidget,
                    if (prizeAmount > 0) ...[
                      SizedBox(height: m.sectionGap * 0.6),
                      Text(
                        s.prizeBonusLabel(prizeAmount),
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: m.bonusSize,
                          fontWeight: FontWeight.w800,
                          color: BingoColors.gold,
                          height: 1.15,
                        ),
                      ),
                    ],
                    SizedBox(height: m.sectionGap),
                    _StartRoundCardImage(metrics: m, bonusOn: bonusOn),
                    SizedBox(height: m.sectionGap),
                    _StartRoundHighlight(
                      metrics: m,
                      patternLabel: patternLabel,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _headerButtons(_StartRoundMetrics m, AppStrings s) {
    final buttons = <Widget>[
      if (onOpenReport != null)
        _StartRoundHeaderButton(
          label: s.navReport,
          onPressed: saving ? null : onOpenReport,
          metrics: m,
          variant: _HeaderButtonVariant.filledDarkTeal,
          compact: true,
        ),
      if (onLogout != null)
        _StartRoundHeaderButton(
          label: s.logout,
          onPressed: saving ? null : () => onLogout!(),
          metrics: m,
          variant: _HeaderButtonVariant.filledDarkTeal,
          compact: true,
        ),
      _StartRoundHeaderButton(
        label: s.registerCard,
        onPressed: saving ? null : onEditCards,
        metrics: m,
        variant: _HeaderButtonVariant.outlinedWhite,
      ),
    ];

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        for (var i = 0; i < buttons.length; i++) ...[
          if (i > 0) SizedBox(width: m.headerBtnGap),
          buttons[i],
        ],
      ],
    );
  }
}

class _BlinkingPackageLowWarning extends StatefulWidget {
  const _BlinkingPackageLowWarning({
    required this.metrics,
    required this.packageBalance,
    required this.currencyCode,
  });

  final _StartRoundMetrics metrics;
  final String packageBalance;
  final String currencyCode;

  @override
  State<_BlinkingPackageLowWarning> createState() =>
      _BlinkingPackageLowWarningState();
}

class _BlinkingPackageLowWarningState extends State<_BlinkingPackageLowWarning>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().strings;

    return FadeTransition(
      opacity: Tween<double>(begin: 1, end: 0.35).animate(_controller),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: widget.metrics.bodyPad * 0.35),
        child: Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: s.packageRunningLow,
                style: TextStyle(
                  fontSize: widget.metrics.warningSize,
                  fontWeight: FontWeight.w800,
                  color: BingoColors.accentRed,
                ),
              ),
              const TextSpan(text: ' '),
              TextSpan(
                text: s.remainingPackageAmount(
                  widget.packageBalance,
                  widget.currencyCode,
                ),
                style: TextStyle(
                  fontSize: widget.metrics.warningSize,
                  fontWeight: FontWeight.w800,
                  color: BingoColors.primary,
                ),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

class _StartRoundStartButton extends StatefulWidget {
  const _StartRoundStartButton({
    required this.metrics,
    required this.label,
    required this.saving,
    required this.enabled,
    required this.onPressed,
  });

  final _StartRoundMetrics metrics;
  final String label;
  final bool saving;
  final bool enabled;
  final VoidCallback onPressed;

  @override
  State<_StartRoundStartButton> createState() => _StartRoundStartButtonState();
}

class _StartRoundStartButtonState extends State<_StartRoundStartButton> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final hovered = _hovered && widget.enabled && !widget.saving;
    final bg = hovered ? _startModalStartBtnHover : Colors.white;
    final fg = hovered ? Colors.white : Colors.black;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: Material(
        color: Colors.transparent,
        elevation: hovered ? 6 : 3,
        shadowColor: Colors.black.withValues(alpha: hovered ? 0.3 : 0.2),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: widget.enabled ? widget.onPressed : null,
          borderRadius: BorderRadius.circular(8),
          child: _SnakeBorderFrame(
            active: widget.enabled && !widget.saving,
            borderRadius: 8,
            child: Ink(
              height: widget.metrics.startBtnHeight,
              decoration: BoxDecoration(
                color: widget.enabled && !widget.saving
                    ? bg
                    : Colors.white.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: _startModalStartBtnBorder,
                  width: 4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: hovered ? 0.3 : 0.2),
                    blurRadius: hovered ? 15 : 10,
                    offset: Offset(0, hovered ? 8 : 5),
                  ),
                ],
              ),
              child: Center(
                child: widget.saving
                    ? const AppButtonLoader(color: Colors.black, size: 24)
                    : Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: widget.metrics.startBtnFont,
                          fontWeight: FontWeight.w900,
                          color: widget.enabled
                              ? fg
                              : Colors.black.withValues(alpha: 0.4),
                        ),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mirrors ethiomark `.modal-start-btn.snake-border` animated red outline.
class _SnakeBorderFrame extends StatefulWidget {
  const _SnakeBorderFrame({
    required this.child,
    required this.active,
    required this.borderRadius,
  });

  final Widget child;
  final bool active;
  final double borderRadius;

  @override
  State<_SnakeBorderFrame> createState() => _SnakeBorderFrameState();
}

class _SnakeBorderFrameState extends State<_SnakeBorderFrame>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    );
    if (widget.active) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant _SnakeBorderFrame oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.active && !_controller.isAnimating) {
      _controller.repeat();
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
      builder: (context, child) => CustomPaint(
        foregroundPainter: _SnakeBorderPainter(
          progress: _controller.value,
          borderRadius: widget.borderRadius,
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}

class _SnakeBorderPainter extends CustomPainter {
  _SnakeBorderPainter({
    required this.progress,
    required this.borderRadius,
  });

  final double progress;
  final double borderRadius;

  static const _outline = Color(0xFFFF0000);
  static const _stroke = 3.0;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = RRect.fromRectAndRadius(
      rect,
      Radius.circular(borderRadius),
    );
    final path = Path()..addRRect(rrect);
    final metrics = path.computeMetrics().first;
    final total = metrics.length;
    final headLen = total * 0.12;
    final tailLen = total * 0.12;
    final headStart = (progress * total) % total;

    void drawSegment(double start, double length) {
      if (length <= 0) return;
      final extract = metrics.extractPath(start, start + length);
      final paint = Paint()
        ..color = _outline
        ..style = PaintingStyle.stroke
        ..strokeWidth = _stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawPath(extract, paint);
    }

    drawSegment(headStart, headLen);
    final tailStart = (headStart - tailLen) % total;
    drawSegment(tailStart < 0 ? tailStart + total : tailStart, tailLen);
  }

  @override
  bool shouldRepaint(covariant _SnakeBorderPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

class _StartRoundHighlight extends StatelessWidget {
  const _StartRoundHighlight({
    required this.metrics,
    required this.patternLabel,
  });

  final _StartRoundMetrics metrics;
  final String patternLabel;

  @override
  Widget build(BuildContext context) {
    return Text(
      patternLabel,
      textAlign: TextAlign.center,
      style: TextStyle(
        fontSize: metrics.patternSize,
        fontWeight: FontWeight.w800,
        color: BingoColors.accentRed,
        height: 1.2,
      ),
    );
  }
}

enum _HeaderButtonVariant {
  filledRed,
  filledGreen,
  filledYellow,
  filledDarkTeal,
  outlinedWhite,
}

class _StartRoundHeaderButton extends StatelessWidget {
  const _StartRoundHeaderButton({
    required this.label,
    required this.onPressed,
    required this.metrics,
    this.variant = _HeaderButtonVariant.filledGreen,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final _StartRoundMetrics metrics;
  final _HeaderButtonVariant variant;
  final bool compact;

  static const _headerGreen = Color(0xFF1E5B3E);
  static const _profileRed = Color(0xFF9E1616);

  ({Color bg, Color fg, Color disabledBg, Color? border, Color? hoverBg})
      _colors() =>
      switch (variant) {
        _HeaderButtonVariant.filledRed => (
            bg: _profileRed,
            fg: Colors.white,
            disabledBg: _profileRed.withValues(alpha: 0.45),
            border: null,
            hoverBg: null,
          ),
        _HeaderButtonVariant.filledGreen => (
            bg: _headerGreen,
            fg: Colors.white,
            disabledBg: _headerGreen.withValues(alpha: 0.45),
            border: null,
            hoverBg: null,
          ),
        _HeaderButtonVariant.filledYellow => (
            bg: BingoColors.gold,
            fg: BingoColors.bgDark,
            disabledBg: BingoColors.gold.withValues(alpha: 0.45),
            border: null,
            hoverBg: null,
          ),
        _HeaderButtonVariant.filledDarkTeal => (
            bg: _startModalHeaderBtnBg,
            fg: Colors.white,
            disabledBg: _startModalHeaderBtnBg.withValues(alpha: 0.45),
            border: null,
            hoverBg: _startModalHeaderBtnHover,
          ),
        _HeaderButtonVariant.outlinedWhite => (
            bg: _startModalHeaderBtnBg,
            fg: Colors.white,
            disabledBg: _startModalHeaderBtnBg.withValues(alpha: 0.45),
            border: Colors.white,
            hoverBg: _startModalRegisterHover,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final padding = EdgeInsets.symmetric(
      horizontal: compact ? metrics.headerBtnSmallPadH : metrics.headerBtnPadH,
      vertical: compact ? metrics.headerBtnSmallPadV : metrics.headerBtnPadV,
    );
    final textStyle = TextStyle(
      fontSize: compact ? metrics.headerBtnSmallFont : metrics.headerBtnFont,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.2,
    );
    final radius = BorderRadius.circular(metrics.headerBtnRadius);
    final minHeight =
        compact ? metrics.headerBtnSmallHeight : metrics.headerBtnHeight;
    final colors = _colors();
    final hoverBg = colors.hoverBg;

    if (variant == _HeaderButtonVariant.outlinedWhite) {
      return OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: colors.fg,
          disabledForegroundColor: colors.fg.withValues(alpha: 0.45),
          backgroundColor: colors.bg,
          disabledBackgroundColor: colors.disabledBg,
          padding: padding,
          minimumSize: Size(0, minHeight),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: textStyle,
          side: BorderSide(
            color: onPressed == null
                ? colors.border!.withValues(alpha: 0.45)
                : colors.border!,
            width: metrics.headerBtnBorderWidth,
          ),
          shape: RoundedRectangleBorder(borderRadius: radius),
        ).copyWith(
          backgroundColor: hoverBg == null
              ? null
              : WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.disabled)) {
                    return colors.disabledBg;
                  }
                  if (states.contains(WidgetState.hovered) ||
                      states.contains(WidgetState.pressed)) {
                    return hoverBg;
                  }
                  return colors.bg;
                }),
        ),
        child: Text(label),
      );
    }

    return Material(
      color: Colors.transparent,
      elevation: onPressed == null ? 0 : 2,
      shadowColor: Colors.black.withValues(alpha: 0.25),
      borderRadius: radius,
      child: FilledButton(
        onPressed: onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: colors.bg,
          foregroundColor: colors.fg,
          disabledBackgroundColor: colors.disabledBg,
          disabledForegroundColor: colors.fg.withValues(alpha: 0.7),
          padding: padding,
          minimumSize: Size(0, minHeight),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
          textStyle: textStyle,
          shape: RoundedRectangleBorder(borderRadius: radius),
          elevation: 0,
        ).copyWith(
          backgroundColor: hoverBg == null
              ? null
              : WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.disabled)) {
                    return colors.disabledBg;
                  }
                  if (states.contains(WidgetState.hovered) ||
                      states.contains(WidgetState.pressed)) {
                    return hoverBg;
                  }
                  return colors.bg;
                }),
        ),
        child: Text(label),
      ),
    );
  }
}

class _StartRoundCardImage extends StatelessWidget {
  const _StartRoundCardImage({
    required this.metrics,
    required this.bonusOn,
  });

  final _StartRoundMetrics metrics;
  final bool bonusOn;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      bonusOn ? AppAssets.startRoundBonusImage : AppAssets.startRoundCardImage,
      fit: BoxFit.contain,
      width: double.infinity,
      height: metrics.cardImageHeight,
      errorBuilder: (context, error, stackTrace) => SizedBox(
        height: metrics.cardImageHeight,
        child: Center(
          child: Icon(
            Icons.image_not_supported_outlined,
            size: 32,
            color: BingoColors.bgDark.withValues(alpha: 0.45),
          ),
        ),
      ),
    );

    return Align(
      alignment: Alignment.center,
      child: FractionallySizedBox(
        widthFactor: metrics.desktop ? 0.82 : 0.8,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: image,
          ),
        ),
      ),
    );
  }
}

class _StartRoundMetrics {
  _StartRoundMetrics(
    BuildContext context, {
    this.showTrialBanner = false,
    this.showPackageWarning = false,
    this.trialExhausted = false,
    this.showBonus = false,
  })
      : desktop = context.isDesktop,
        width = MediaQuery.sizeOf(context).width,
        height = MediaQuery.sizeOf(context).height {
    short = height < 720;
    narrowMobile = !desktop && width < 400;

    uiScale = desktop
        ? math.min(width / 1200.0, height / 760.0).clamp(1.0, 1.28)
        : math.min(width / 360.0, height / 640.0).clamp(0.92, 1.15);

    compact = desktop &&
        (width < 1080 ||
            width * _startModalWidthScreenFactor < scaled(520.0));

    insetBottom = scaled(desktop ? 40.0 : 16.0);
    insetH = scaled(desktop ? 28.0 : 12.0);
    insetTop = desktop
        ? (height * 0.04).clamp(scaled(20.0), scaled(48.0))
        : (height * 0.02).clamp(scaled(8.0), scaled(16.0));
    radius = _startModalContentRadius;
    headerPadH = scaled(desktop ? 14.0 : (narrowMobile ? 5.0 : 6.0));
    headerPadV = scaled(desktop ? 7.0 : (narrowMobile ? 4.0 : 5.0));
    bodyPad = scaled(desktop ? 10.0 : 4.0);
    headerGap = scaled(desktop ? 8.0 : 4.0);
    headerBtnGap = scaled(desktop ? 2.0 : 2.0);
    sectionGap = scaled(desktop ? 8.0 : 4.0);
    bannerGap = scaled(desktop ? 8.0 : 4.0);
    footerGap = scaled(desktop ? 10.0 : 6.0);

    roundTitleSize = scaled(
      desktop
          ? (compact ? 18.0 : 20.0)
          : (narrowMobile ? 11.0 : 12.0),
    );
    appTitleSize = scaled(desktop ? 17.0 : (narrowMobile ? 14.0 : 16.0));
    derashSize = scaled(desktop ? 24.0 : 18.0);
    derashLabelSize = scaled(desktop ? 17.0 : 14.0);
    patternSize = scaled(desktop ? 18.0 : 15.0);
    bonusSize = scaled(desktop ? 22.0 : 16.0);
    warningSize = scaled(desktop ? 14.0 : 12.0);
    startBtnHeight = scaled(desktop ? 50.0 : 40.0);
    startBtnFont = scaled(desktop ? 22.0 : 16.0);
    headerBtnPadH = scaled(
      desktop
          ? (compact ? 14.0 : 16.0)
          : (narrowMobile ? 6.0 : 8.0),
    );
    headerBtnPadV = scaled(
      desktop
          ? (compact ? 9.0 : 10.0)
          : (narrowMobile ? 4.0 : 5.0),
    );
    headerBtnFont = scaled(
      desktop
          ? (compact ? 13.0 : 14.0)
          : (narrowMobile ? 9.0 : 10.0),
    );
    headerBtnSmallPadH = scaled(
      desktop
          ? (compact ? 8.0 : 10.0)
          : (narrowMobile ? 4.0 : 5.0),
    );
    headerBtnSmallPadV = scaled(
      desktop
          ? (compact ? 7.0 : 8.0)
          : (narrowMobile ? 3.0 : 4.0),
    );
    headerBtnSmallFont = scaled(
      desktop
          ? (compact ? 11.0 : 12.0)
          : (narrowMobile ? 8.0 : 9.0),
    );
    headerBtnHeight = scaled(
      desktop
          ? (compact ? 36.0 : 38.0)
          : (narrowMobile ? 28.0 : 30.0),
    );
    headerBtnSmallHeight = scaled(
      desktop
          ? (compact ? 30.0 : 32.0)
          : (narrowMobile ? 24.0 : 26.0),
    );
    headerBtnBorderWidth = scaled(desktop ? 2.0 : 1.5);
    headerBtnRadius = scaled(5.0);

    availableDialogHeight = height - insetTop - insetBottom;

    if (desktop) {
      final maxDialogW = width - insetH * 2;
      final minDialogW = math.min(scaled(340.0), maxDialogW);
      dialogWidth = _clampBetween(
        width * _startModalWidthScreenFactor,
        minDialogW,
        math.min(maxDialogW, scaled(520.0)),
      );

      cardImageHeight = _clampBetween(
        dialogWidth * 0.78,
        scaled(160.0),
        scaled(300.0),
      );

      final headerChrome = headerPadV * 2 + headerBtnHeight;
      final trialBannerChrome = showTrialBanner
          ? scaled(trialExhausted ? 68.0 : 54.0) + footerGap
          : 0.0;
      final packageWarningChrome = showPackageWarning && !showTrialBanner
          ? scaled(34.0) + footerGap
          : 0.0;
      final footerChrome = startBtnHeight +
          bodyPad * 2 +
          footerGap +
          trialBannerChrome +
          packageWarningChrome;
      final textChrome = derashSize * 1.15 +
          patternSize * 1.2 +
          sectionGap * 2 +
          (showBonus ? bonusSize * 1.15 + sectionGap * 0.6 : 0.0);
      final bodyChrome = bodyPad * 2 + textChrome + cardImageHeight;
      maxBodyScrollHeight = bodyChrome;

      final contentHeight =
          headerChrome + bodyChrome + footerChrome + scaled(8);
      minDialogHeight = 0;
      maxDialogHeight = _clampBetween(
        contentHeight,
        scaled(short ? 320.0 : 380.0),
        math.min(availableDialogHeight * 0.86, scaled(680.0)),
      );
    } else {
      final maxDialogW = width - insetH * 2;
      dialogWidth = maxDialogW;

      minDialogHeight = 0;
      cardImageHeight = _clampBetween(
        height * 0.14,
        scaled(84.0),
        scaled(112.0),
      );

      final headerChrome = headerPadV * 2 + headerBtnSmallHeight;
      final trialBannerChrome = showTrialBanner
          ? scaled(trialExhausted ? 68.0 : 54.0) + footerGap
          : 0.0;
      final packageWarningChrome = showPackageWarning && !showTrialBanner
          ? scaled(34.0) + footerGap
          : 0.0;
      final footerChrome = startBtnHeight +
          bodyPad * 2 +
          footerGap +
          trialBannerChrome +
          packageWarningChrome;
      final textChrome = derashSize * 1.15 +
          patternSize * 1.2 +
          sectionGap * 2 +
          (showBonus ? bonusSize * 1.15 + sectionGap * 0.6 : 0.0);
      final bodyChrome = bodyPad * 2 + textChrome + cardImageHeight;
      final bodyBudget = availableDialogHeight * 0.52 -
          trialBannerChrome -
          packageWarningChrome;
      maxBodyScrollHeight = _clampBetween(
        bodyChrome,
        scaled(140.0),
        bodyBudget,
      );

      final contentHeight =
          headerChrome + maxBodyScrollHeight + footerChrome + scaled(8);
      maxDialogHeight = _clampBetween(
        contentHeight,
        scaled(300.0),
        math.min(availableDialogHeight * 0.82, scaled(560.0)),
      );
    }

    if (kDebugMode) {
      debugPrint(
        '[StartRoundModal] logical=${width.toStringAsFixed(0)}x'
        '${height.toStringAsFixed(0)} desktop=$desktop short=$short '
        'availableDialog=${availableDialogHeight.toStringAsFixed(0)} '
        'maxDialogH=${maxDialogHeight.toStringAsFixed(0)} '
        'cardImgH=${cardImageHeight.toStringAsFixed(0)}',
      );
    }
  }

  static double _clampBetween(double value, double lower, double upper) {
    final lo = math.min(lower, upper);
    final hi = math.max(lower, upper);
    return value.clamp(lo, hi);
  }

  double scaled(double value) => value * uiScale;

  final bool desktop;
  final bool showTrialBanner;
  final bool showPackageWarning;
  final bool trialExhausted;
  final bool showBonus;
  final double width;
  final double height;
  late final bool compact;
  late final bool short;
  late final bool narrowMobile;
  late final double uiScale;
  late final double dialogWidth;
  late final double minDialogHeight;
  late final double maxDialogHeight;
  late final double availableDialogHeight;
  late final double insetH;
  late final double insetTop;
  late final double insetBottom;
  late final double radius;
  late final double headerPadH;
  late final double headerPadV;
  late final double bodyPad;
  late final double headerGap;
  late final double headerBtnGap;
  late final double sectionGap;
  late final double bannerGap;
  late final double footerGap;
  late final double roundTitleSize;
  late final double appTitleSize;
  late final double cardImageHeight;
  late final double maxBodyScrollHeight;
  late final double derashSize;
  late final double derashLabelSize;
  late final double patternSize;
  late final double bonusSize;
  late final double warningSize;
  late final double startBtnHeight;
  late final double startBtnFont;
  late final double headerBtnPadH;
  late final double headerBtnPadV;
  late final double headerBtnFont;
  late final double headerBtnSmallPadH;
  late final double headerBtnSmallPadV;
  late final double headerBtnSmallFont;
  late final double headerBtnHeight;
  late final double headerBtnSmallHeight;
  late final double headerBtnBorderWidth;
  late final double headerBtnRadius;
}
