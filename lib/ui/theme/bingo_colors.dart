import 'package:flutter/material.dart';

/// Palette inspired by ethiomark `style.css` / `bingon.css`.
abstract final class BingoColors {
  /// ethiomark body: rgb(3, 46, 59)
  static const bgDark = Color(0xFF032E3B);
  static const bgGradientEnd = Color(0xFF24243E);

  static const surface = Color(0xFF2B3158);
  static const surfaceLight = Color(0xFF3A3F6D);

  static const primary = Color(0xFF4CAF50);
  static const primaryDark = Color(0xFF388E3C);
  static const gold = Color(0xFFFFC107);
  static const accentRed = Color(0xFFE94560);
  static const accentTeal = Color(0xFF077C6C);

  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xB3FFFFFF);
  static const border = Color(0x1AFFFFFF);

  static const called = Color(0xFF43A047);
  static const lastCalled = Color(0xFFF44336);
  static const selectedCard = Color(0xFF1E5B3E);

  /// ethiomark B-I-N-G-O letter boxes
  static const columnB = Color(0xFFFF0404);
  static const columnI = Color(0xFF0C3D75);
  static const columnN = Color(0xFFFFFFFF);
  static const columnNText = Color(0xFF0FB900);
  static const columnG = Color(0xFFDAB71C);
  static const columnO = Color(0xFF0A591F);

  /// ethiomark `.numbox` default
  static const numBoxBg = Color(0xFF555555);
  static const numBoxText = Color(0xFFF2F2F2);

  /// Desktop play board — darker charcoal cells.
  static const desktopNumBoxBg = Color(0xFF3A3F48);
  static const desktopNumBoxBorder = Color(0xFF2A2F38);

  /// Mobile play board — dark navy cells (not pure black).
  static const mobileNumBoxBg = Color(0xFF1A2233);
  static const mobileNumBoxBorder = Color(0xFF2E3A52);
  static const mobileBoardBg = Color(0xFF232D4B);

  /// ethiomark side-nav
  static const sideNavBg = Color(0xFFF7F7F7);
  static const sideNavSelected = Color(0xFF00BBBB);
  static const sideNavText = Color(0xFF000000);

  /// ethiomark play buttons
  static const bingoButtonStart = Color(0xFFFFFF00);
  static const bingoButtonEnd = Color(0xFF999914);

  /// Mobile register screen — deep navy background (card selection grid).
  static const registerMobileBgTop = Color(0xFF0A0E2B);
  static const registerMobileBgBottom = Color(0xFF12123E);
  static const registerMobileCellBg = Color(0xFF1D234D);
  static const registerMobileCellBorder = Color(0xFF3A4568);
  static const registerMobileText = Color(0xFFB8C0D4);
  static const registerMobileTextMuted = Color(0xFF9AA3B8);

  static LinearGradient get registerMobileGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [registerMobileBgTop, registerMobileBgBottom],
      );

  static LinearGradient get pageGradient => const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [bgDark, bgDark],
      );

  /// ethiomark body background — rgb(3, 46, 59)
  static const pageBackground = bgDark;

  static LinearGradient get cardGradient => const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [surface, surfaceLight],
  );

  static Color columnColor(String letter) => switch (letter) {
    'B' => columnB,
    'I' => columnI,
    'N' => columnN,
    'G' => columnG,
    'O' => columnO,
    _ => surface,
  };

  static Color columnTextColor(String letter) => switch (letter) {
    'N' => columnNText,
    'G' => Colors.black,
    _ => Colors.white,
  };

  /// Check-card modal header — saturated colors so the B I N G O row
  /// stays visible from a distance (N is green, not white).
  static Color checkCardHeaderColor(String letter) => switch (letter) {
    'B' => columnB,
    'I' => columnI,
    'N' => const Color(0xFF00838F),
    'G' => columnG,
    'O' => columnO,
    _ => surface,
  };

  static Color checkCardHeaderTextColor(String letter) => switch (letter) {
    'G' => Colors.black,
    _ => Colors.white,
  };

  static const checkCardCellBg = Color(0xFFFFFFFF);
  static const checkCardCellBorder = Color(0xFFD0D0D0);
}
