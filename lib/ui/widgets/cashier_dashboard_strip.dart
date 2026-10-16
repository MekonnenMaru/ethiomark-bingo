import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_currency.dart';
import '../../core/l10n/locale_controller.dart';
import 'app_loading.dart';
import '../theme/bingo_colors.dart';

class CashierDashboardExtra {
  const CashierDashboardExtra({
    required this.label,
    required this.value,
    this.valueColor,
    this.tint,
  });

  final String label;
  final String value;
  final Color? valueColor;
  final Color? tint;
}

/// ethiomark `.cashier-dashboard-connected.compact` stats strip.

class CashierDashboardStrip extends StatelessWidget {
  const CashierDashboardStrip({
    super.key,

    required this.cashierId,

    required this.packageBalance,

    this.currencyCode = AppCurrency.defaultCode,

    this.lastTransaction,
    this.thirdLabel,
    this.thirdValue,
    this.extras = const [],
  });

  final String cashierId;

  final String packageBalance;

  final String currencyCode;

  final String? lastTransaction;
  final String? thirdLabel;
  final String? thirdValue;
  final List<CashierDashboardExtra> extras;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().strings;
    final compact = extras.length >= 2;
    final trailing = extras.isNotEmpty
        ? extras
        : [
            CashierDashboardExtra(
              label: thirdLabel ?? s.lastTransaction,
              value: thirdValue ?? lastTransaction ?? s.noTransaction,
              tint: const Color(0xFF6AB04C).withValues(alpha: 0.08),
            ),
          ];

    return Container(
      height: compact ? 62 : 70,

      decoration: BoxDecoration(
        color: const Color(0xFF0F2E50),

        borderRadius: BorderRadius.circular(8),

        border: Border.all(color: const Color(0xFF05535D)),
      ),

      clipBehavior: Clip.antiAlias,

      child: Row(
        children: [
          _section(
            label: s.cashierId,
            value: cashierId,
            tint: const Color(0xFF16A085).withValues(alpha: 0.08),
            compact: compact,
          ),
          _section(
            label: s.remainingPackage,
            value: s.remainingPackageAmount(packageBalance, currencyCode),
            tint: const Color(0xFFE59400).withValues(alpha: 0.08),
            compact: compact,
          ),
          ...trailing.asMap().entries.map((entry) {
            final last = entry.key == trailing.length - 1;
            return _section(
              label: entry.value.label,
              value: entry.value.value,
              valueColor: entry.value.valueColor,
              tint: entry.value.tint ??
                  const Color(0xFF6AB04C).withValues(alpha: 0.08),
              compact: compact,
              showDivider: !last,
            );
          }),
        ],
      ),
    );
  }

  Widget _section({
    required String label,
    required String value,
    required Color tint,
    Color? valueColor,
    bool compact = false,
    bool showDivider = true,
  }) {
    return Expanded(
      child: Container(
        color: tint,
        padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12),
        child: Stack(
          children: [
            if (showDivider)
              Positioned(
                right: 0,
                top: 12,
                bottom: 12,
                child: Container(
                  width: 1,
                  color: const Color(0xFFC0BDBD).withValues(alpha: 0.3),
                ),
              ),
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: const Color(0xFFC0BDBD),
                      fontSize: compact ? 11 : 13,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: compact ? 2 : 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: valueColor ?? Colors.white,
                      fontSize: compact ? 15 : 16,
                      fontWeight: FontWeight.bold,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// ethiomark orange `.cashier_option_submit_button` / `.package-sync-btn`.

class EthiomarkActionButton extends StatelessWidget {
  const EthiomarkActionButton({
    super.key,

    required this.label,

    required this.onPressed,

    this.loading = false,

    this.minWidth = 150,

    this.height = 44,

    this.fontSize = 18,

    this.horizontalPadding = 14,

    this.attention = false,
  });

  final String label;

  final VoidCallback? onPressed;

  final bool loading;

  final double minWidth;

  final double height;

  final double fontSize;

  final double horizontalPadding;

  final bool attention;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: loading ? null : onPressed,

      style: FilledButton.styleFrom(
        minimumSize: Size(minWidth, height),
        maximumSize: Size(double.infinity, height),
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
        backgroundColor: attention
            ? const Color(0xFFEF4444)
            : const Color(0xFFE59400),

        foregroundColor: attention ? Colors.white : Colors.black,

        textStyle: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          height: 1,
        ),

        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
      ),

      child: loading
          ? AppButtonLoader(
              color: attention ? Colors.white : Colors.black,
              size: 20,
            )
          : Text(label),
    );
  }
}

/// ethiomark `.cashier_option_table` header row styling.

class EthiomarkTableHeader extends StatelessWidget {
  const EthiomarkTableHeader({
    super.key,
    required this.columns,
    this.columnColors,
    this.highlightColumnIndex = 3,
  });

  final List<String> columns;
  final List<Color>? columnColors;
  final int highlightColumnIndex;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0F2E50),
      child: Row(
        children: columns.asMap().entries.map((entry) {
          final i = entry.key;
          final c = entry.value;
          final isWinner = i == highlightColumnIndex;
          final color = columnColors != null && i < columnColors!.length
              ? columnColors![i]
              : (isWinner ? BingoColors.primary : Colors.white);
          return Expanded(
            flex: isWinner ? 2 : 1,
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 12,
              ),
              child: Text(
                c,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

/// ethiomark `tfoot` totals row.

class EthiomarkTotalsFooter extends StatelessWidget {
  const EthiomarkTotalsFooter({
    super.key,

    required this.label,

    required this.values,

    this.valueColors,

    this.emphasizedIndices = const {},
  });

  final String label;

  final List<String> values;

  final List<Color?>? valueColors;

  final Set<int> emphasizedIndices;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF0D2E2E),

        border: Border(top: BorderSide(color: Color(0xFF124843), width: 2)),
      ),

      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),

      child: Row(
        children: [
          Expanded(
            flex: 2,

            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 16,
                fontStyle: FontStyle.italic,
              ),
            ),
          ),

          ...values.asMap().entries.map((entry) {
            final i = entry.key;
            final v = entry.value;
            final emphasized = emphasizedIndices.contains(i);
            final color = valueColors != null && i < valueColors!.length
                ? valueColors![i]
                : Colors.white;

            return Expanded(
              child: Container(
                margin: emphasized
                    ? const EdgeInsets.symmetric(horizontal: 2)
                    : null,
                padding: emphasized
                    ? const EdgeInsets.symmetric(horizontal: 4, vertical: 6)
                    : null,
                decoration: emphasized
                    ? BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            const Color(0xFF1B5E20).withValues(alpha: 0.6),
                            const Color(0xFF0A3D2E),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: BingoColors.gold, width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: BingoColors.gold.withValues(alpha: 0.25),
                            blurRadius: 8,
                          ),
                        ],
                      )
                    : null,
                child: Text(
                  v,

                  textAlign: TextAlign.center,

                  style: TextStyle(
                    color: color ?? Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: emphasized ? 18 : 16,
                    fontStyle: emphasized ? FontStyle.normal : FontStyle.italic,
                    letterSpacing: emphasized ? 0.5 : 0,
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
