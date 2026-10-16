import 'package:flutter/material.dart';

/// ethiomark `bootstrap/css/bingon.css` — board + play number typography.
abstract final class BingoTypography {
  static const boardFontFamily = 'Helvetica Neue';
  static const boardFontFallback = ['Helvetica', 'Arial', 'Segoe UI'];

  static TextStyle board(double fontSize, Color color) => TextStyle(
        fontFamily: boardFontFamily,
        fontFamilyFallback: boardFontFallback,
        fontWeight: FontWeight.w700,
        fontSize: fontSize,
        color: color,
        height: 1.0,
      );
}
