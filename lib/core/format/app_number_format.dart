abstract final class AppNumberFormat {
  static String format(
    num value, {
    int? decimalDigits,
  }) {
    final negative = value < 0;
    final abs = value.abs();

    final String raw;
    if (decimalDigits != null) {
      raw = abs.toStringAsFixed(decimalDigits);
    } else if (abs == abs.roundToDouble()) {
      raw = abs.toInt().toString();
    } else {
      raw = abs.toStringAsFixed(2).replaceAll(RegExp(r'\.?0+$'), '');
    }

    final formatted = _addGroupingSeparators(raw);
    return negative ? '-$formatted' : formatted;
  }

  static String formatString(
    String value, {
    int? decimalDigits,
  }) {
    final cleaned = value.replaceAll(',', '').trim();
    if (cleaned.isEmpty) return value;

    final parsed = num.tryParse(cleaned);
    if (parsed == null) return value;

    return format(parsed, decimalDigits: decimalDigits);
  }

  static String _addGroupingSeparators(String raw) {
    final parts = raw.split('.');
    final intPart = parts.first;
    final buffer = StringBuffer();

    for (var i = 0; i < intPart.length; i++) {
      if (i > 0 && (intPart.length - i) % 3 == 0) {
        buffer.write(',');
      }
      buffer.write(intPart[i]);
    }

    if (parts.length > 1) {
      buffer.write('.');
      buffer.write(parts[1]);
    }

    return buffer.toString();
  }
}
