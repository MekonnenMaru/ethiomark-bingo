import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_currency.dart';
import '../../core/format/app_number_format.dart';
import '../../core/l10n/locale_controller.dart';
import '../theme/bingo_colors.dart';

/// Prize / derash panel beside the play controls — mirrors ethiomark `.derash-box`.
class DerashBox extends StatelessWidget {
  const DerashBox({
    super.key,
    required this.derashAmount,
    required this.cardCount,
    required this.callCount,
    this.currencyCode = AppCurrency.defaultCode,
    this.compact = true,
    this.showAmount = true,
    this.showStats = true,
    this.showCardCount = true,
    this.inline = false,
    this.mobileTopBar = false,
    this.barHeight,
  });

  final num derashAmount;
  final int cardCount;
  final int callCount;
  final String currencyCode;
  final bool compact;
  final bool showAmount;
  final bool showStats;
  final bool showCardCount;
  final bool inline;
  final bool mobileTopBar;
  final double? barHeight;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().strings;

    if (mobileTopBar) {
      final height = barHeight ?? 44.0;
      final dividerHeight = (height - 12).clamp(20.0, height);

      return SizedBox(
        height: height,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0A3941),
                Color(0xFF0F5C68),
                Color(0xFF0A3941),
              ],
            ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: BingoColors.gold.withValues(alpha: 0.75),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: BingoColors.gold.withValues(alpha: 0.12),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Text(
                      AppNumberFormat.format(derashAmount),
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.0,
                        shadows: [
                          Shadow(
                            color: Color(0x66FFD700),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        s.derashCurrencyLabel(currencyCode),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: BingoColors.gold,
                          height: 1.0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: dividerHeight,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: BingoColors.gold.withValues(alpha: 0.4),
              ),
              if (showCardCount) ...[
                _MobileTopBarStat(
                  label: s.cardsStatShort,
                  value: '$cardCount',
                  valueColor: Colors.white,
                ),
                const SizedBox(width: 10),
              ],
              _MobileTopBarStat(
                label: s.callsStatShort,
                value: '$callCount',
                valueColor: const Color(0xFFFFD54F),
              ),
            ],
          ),
        ),
      );
    }

    if (compact) {
      if (!showAmount && !showStats) return const SizedBox.shrink();

      if (inline && !showAmount && showStats) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showCardCount) ...[
              Text(
                s.cardQuantityLabel(cardCount),
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  fontStyle: FontStyle.italic,
                  color: BingoColors.accentTeal.withValues(alpha: 0.95),
                  height: 1.1,
                ),
              ),
              const SizedBox(width: 6),
            ],
            Text(
              s.callCountLabel(callCount),
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: Color(0xFFFFD54F),
                height: 1.1,
              ),
            ),
          ],
        );
      }

      return Container(
        width: inline ? null : double.infinity,
        margin: EdgeInsets.only(bottom: inline ? 0 : 2),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          color: const Color(0xFF0A3941),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          mainAxisSize: inline ? MainAxisSize.min : MainAxisSize.max,
          children: [
            if (showAmount) ...[
              Text(
                AppNumberFormat.format(derashAmount),
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  height: 1.1,
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  s.derashCurrencyLabel(currencyCode),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: BingoColors.gold,
                    height: 1.1,
                  ),
                ),
              ),
            ],
            if (showAmount && showStats) const Spacer(),
            if (showStats) ...[
              if (showCardCount) ...[
                Text(
                  s.cardQuantityLabel(cardCount),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    fontStyle: FontStyle.italic,
                    color: BingoColors.accentTeal.withValues(alpha: 0.95),
                    height: 1.1,
                  ),
                ),
                const SizedBox(width: 6),
              ],
              Text(
                s.callCountLabel(callCount),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFFFFD54F),
                  height: 1.1,
                ),
              ),
            ],
          ],
        ),
      );
    }

    final amountSize = 44.0;
    final callSize = 30.0;
    final cardSize = 16.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          s.derash,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 16,
            color: BingoColors.textPrimary,
            fontWeight: FontWeight.w600,
            height: 1.15,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0A3941),
            borderRadius: BorderRadius.circular(8),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    AppNumberFormat.format(derashAmount),
                    style: TextStyle(
                      fontSize: amountSize,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    s.derashCurrencyLabel(currencyCode),
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: BingoColors.gold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Container(
                height: 6,
                width: double.infinity,
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF2C866A),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  if (showCardCount)
                    Text(
                      s.cardQuantityLabel(cardCount),
                      style: TextStyle(
                        fontSize: cardSize,
                        fontStyle: FontStyle.italic,
                        color: const Color(0xFF868181),
                      ),
                    ),
                  const Spacer(),
                  Text(
                    s.callCountLabel(callCount),
                    style: TextStyle(
                      fontSize: callSize,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MobileTopBarStat extends StatelessWidget {
  const _MobileTopBarStat({
    required this.label,
    required this.value,
    required this.valueColor,
  });

  final String label;
  final String value;
  final Color valueColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: Colors.white.withValues(alpha: 0.82),
            height: 1.0,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w900,
            color: valueColor,
            height: 1.0,
            shadows: valueColor == const Color(0xFFFFD54F)
                ? const [
                    Shadow(
                      color: Color(0x44FFB300),
                      blurRadius: 3,
                    ),
                  ]
                : null,
          ),
        ),
      ],
    );
  }
}
