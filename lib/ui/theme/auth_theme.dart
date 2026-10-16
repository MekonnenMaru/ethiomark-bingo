import 'package:flutter/material.dart';

import '../../core/performance/resource_budget.dart';
import 'bingo_colors.dart';

/// Login & setup screen palette — unified professional dark theme.
abstract final class AuthTheme {
  static const pageTop = Color(0xFF0B1524);
  static const pageMid = Color(0xFF0F2832);
  static const pageBottom = Color(0xFF0A1F28);

  static const panelBg = Color(0xFF141E2E);
  static const panelBgElevated = Color(0xFF1A2638);
  static const panelBorder = Color(0x33FFFFFF);
  static const panelBorderAccent = Color(0x4D00BBBB);

  static const textPrimary = Color(0xFFF4F7FA);
  static const textSecondary = Color(0xFF94A3B8);
  static const textMuted = Color(0xFF64748B);

  static const fieldFill = Color(0xFF1E2A3D);
  static const fieldBorder = Color(0xFF334155);
  static const fieldFocus = BingoColors.accentTeal;

  static const brandGold = Color(0xFFE8A317);
  static const brandGoldLight = Color(0xFFFFC857);

  static LinearGradient get pageGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [pageTop, pageMid, pageBottom],
        stops: [0.0, 0.55, 1.0],
      );

  static LinearGradient get panelSheen => LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withValues(alpha: 0.06),
          Colors.transparent,
        ],
      );

  static LinearGradient get primaryButtonGradient => const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [brandGoldLight, brandGold],
      );

  static List<BoxShadow> get panelShadow => [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.35),
          blurRadius: 32,
          offset: const Offset(0, 12),
        ),
        BoxShadow(
          color: BingoColors.accentTeal.withValues(alpha: 0.08),
          blurRadius: 48,
          spreadRadius: -8,
        ),
      ];

  static BoxDecoration panelDecoration({bool elevated = false}) {
    return BoxDecoration(
      color: elevated ? panelBgElevated : panelBg,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(
        color: elevated ? panelBorderAccent : panelBorder,
        width: 1,
      ),
      boxShadow: ResourceBudget.reduceDecorations ? null : panelShadow,
    );
  }

  static Widget pageBackground({required Widget child}) {
    if (ResourceBudget.reduceDecorations) {
      return ColoredBox(
        color: pageMid,
        child: child,
      );
    }

    return DecoratedBox(
      decoration: BoxDecoration(gradient: pageGradient),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: BingoColors.accentTeal.withValues(alpha: 0.07),
              ),
            ),
          ),
          Positioned(
            bottom: -100,
            left: -40,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: brandGold.withValues(alpha: 0.05),
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}
