import 'package:flutter/material.dart';

import 'package:provider/provider.dart';



import '../../core/config/app_currency.dart';
import '../../core/l10n/locale_controller.dart';

import '../../core/trial/trial_service.dart';

import '../theme/bingo_colors.dart';



enum TrialBannerVariant { dark, light }



class TrialProgressBanner extends StatelessWidget {

  const TrialProgressBanner({
    super.key,
    required this.roundsUsed,
    this.currencyCode = AppCurrency.defaultCode,
    this.compact = false,
    this.minimal = false,
    this.exhausted = false,
    this.variant = TrialBannerVariant.dark,
    this.onOpenReport,
  });

  final int roundsUsed;
  final String currencyCode;
  final bool compact;
  /// Single-line layout without rules — for registration page.
  final bool minimal;
  final bool exhausted;
  final TrialBannerVariant variant;
  final VoidCallback? onOpenReport;



  bool get _light => variant == TrialBannerVariant.light;



  Color get _titleColor =>

      _light ? BingoColors.bgDark : Colors.white;



  Color get _bodyColor => _light

      ? BingoColors.bgDark.withValues(alpha: 0.72)

      : BingoColors.textSecondary;



  Color get _progressTextColor => _light

      ? BingoColors.bgDark

      : Colors.white.withValues(alpha: 0.95);



  Color get _accentColor =>

      exhausted ? BingoColors.lastCalled : BingoColors.gold;



  Color get _bgColor {

    if (exhausted) {

      return _light

          ? BingoColors.lastCalled.withValues(alpha: 0.1)

          : BingoColors.lastCalled.withValues(alpha: 0.12);

    }

    return _light

        ? BingoColors.gold.withValues(alpha: 0.18)

        : BingoColors.gold.withValues(alpha: 0.14);

  }



  Color get _borderColor {

    if (exhausted) {

      return _light

          ? BingoColors.lastCalled.withValues(alpha: 0.65)

          : BingoColors.lastCalled.withValues(alpha: 0.55);

    }

    return _light

        ? BingoColors.gold.withValues(alpha: 0.75)

        : BingoColors.gold.withValues(alpha: 0.65);

  }



  Color get _trackColor => _light

      ? Colors.black.withValues(alpha: 0.1)

      : Colors.white.withValues(alpha: 0.12);



  @override

  Widget build(BuildContext context) {

    final s = context.watch<LocaleController>().strings;

    final maxRounds = TrialService.maxRounds;

    final progress = exhausted ? 1.0 : roundsUsed / maxRounds;

    final remaining = TrialService.roundsRemaining(roundsUsed);

    final progressLabel = s.freeTrialProgress(roundsUsed, maxRounds, remaining);



    if (minimal) {
      return _buildMinimal(
        context,
        title: exhausted ? s.freeTrialExhaustedTitle : s.freeTrialTitle,
        progressLabel: exhausted ? s.freeTrialExhaustedBody : progressLabel,
        progress: progress,
      );
    }



    final hPad = compact ? 12.0 : 14.0;

    final vPad = compact ? 8.0 : 10.0;



    return Container(

      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),

      decoration: BoxDecoration(

        color: _bgColor,

        borderRadius: BorderRadius.circular(compact ? 10 : 12),

        border: Border.all(color: _borderColor),

      ),

      child: Column(

        crossAxisAlignment: CrossAxisAlignment.stretch,

        mainAxisSize: MainAxisSize.min,

        children: [

          Row(

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [

              Icon(

                exhausted ? Icons.lock_outline : Icons.card_giftcard_outlined,

                size: compact ? 17 : 19,

                color: _accentColor,

              ),

              const SizedBox(width: 8),

              Expanded(

                child: Column(

                  crossAxisAlignment: CrossAxisAlignment.start,

                  children: [

                    Text(

                      exhausted ? s.freeTrialExhaustedTitle : s.freeTrialTitle,

                      style: TextStyle(

                        color: _titleColor,

                        fontSize: compact ? 13 : 14,

                        fontWeight: FontWeight.w800,

                        height: 1.2,

                      ),

                    ),

                    if (!compact && !exhausted) ...[
                      const SizedBox(height: 3),
                      Text(
                        s.freeTrialRules(currencyCode),
                        style: TextStyle(
                          color: _bodyColor,
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                    ],

                  ],

                ),

              ),

            ],

          ),

          if (!exhausted) ...[
            SizedBox(height: compact ? 8 : 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: compact ? 6 : 7,
                backgroundColor: _trackColor,
                color: _accentColor,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              progressLabel,
              style: TextStyle(
                color: _progressTextColor,
                fontSize: compact ? 12 : 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ] else ...[
            const SizedBox(height: 6),
            Text(
              s.freeTrialExhaustedBody,
              style: TextStyle(
                color: _bodyColor,
                fontSize: compact ? 11 : 12,
                height: 1.3,
              ),
            ),
            _buildReportLink(context),
          ],

        ],

      ),

    );

  }



  Widget _buildMinimal(
    BuildContext context, {
    required String title,
    required String progressLabel,
    required double progress,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Icon(
                exhausted ? Icons.lock_outline : Icons.card_giftcard_outlined,
                size: 14,
                color: _accentColor,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: _titleColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          if (!exhausted) ...[
            const SizedBox(height: 3),
            Row(
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 3,
                      backgroundColor: _trackColor,
                      color: _accentColor,
                    ),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  progressLabel,
                  style: TextStyle(
                    color: _progressTextColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ] else ...[
            const SizedBox(height: 2),
            Text(
              progressLabel,
              style: TextStyle(
                color: _bodyColor,
                fontSize: 10,
                height: 1.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            _buildReportLink(context),
          ],
        ],
      ),
    );
  }

  Widget _buildReportLink(BuildContext context) {
    if (!exhausted || onOpenReport == null) return const SizedBox.shrink();

    final s = context.watch<LocaleController>().strings;
    final linkColor =
        _light ? BingoColors.accentTeal : BingoColors.gold;

    return Padding(
      padding: EdgeInsets.only(top: minimal ? 2 : 4),
      child: Align(
        alignment: Alignment.centerLeft,
        child: TextButton(
          onPressed: onOpenReport,
          style: TextButton.styleFrom(
            padding: EdgeInsets.zero,
            minimumSize: Size.zero,
            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            foregroundColor: linkColor,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.account_circle_outlined, size: minimal ? 14 : 16),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  s.goToProfileAction,
                  style: TextStyle(
                    fontSize: minimal ? 11 : 12,
                    fontWeight: FontWeight.w800,
                    decoration: TextDecoration.underline,
                    decorationColor: linkColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 2),
              Icon(Icons.arrow_forward_rounded, size: minimal ? 14 : 16),
            ],
          ),
        ),
      ),
    );
  }
}


