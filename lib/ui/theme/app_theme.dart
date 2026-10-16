import 'package:flutter/material.dart';

import 'bingo_colors.dart';

class AppTheme {
  static ThemeData dark() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: BingoColors.bgDark,
      colorScheme: const ColorScheme.dark(
        primary: BingoColors.primary,
        secondary: BingoColors.gold,
        surface: BingoColors.surface,
        error: BingoColors.lastCalled,
        onPrimary: Colors.white,
        onSurface: BingoColors.textPrimary,
      ),
    );

    // System fonts only — avoids blank/white UI on offline shop PCs when
    // Google Fonts cannot download or blocks first paint.
    final textTheme = base.textTheme.apply(
      bodyColor: BingoColors.textPrimary,
      displayColor: BingoColors.textPrimary,
    );

    return base.copyWith(
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: BingoColors.textPrimary,
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: BingoColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: BingoColors.border),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: BingoColors.bgDark,
        indicatorColor: BingoColors.primary.withValues(alpha: 0.25),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return textTheme.labelSmall?.copyWith(
            color: selected ? BingoColors.primary : BingoColors.textSecondary,
            fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          );
        }),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: BingoColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          textStyle: textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: BingoColors.surface.withValues(alpha: 0.6),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BingoColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: BingoColors.primary, width: 2),
        ),
        labelStyle: const TextStyle(color: BingoColors.textSecondary),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: BingoColors.surface,
        labelStyle: textTheme.bodyMedium,
        side: const BorderSide(color: BingoColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
