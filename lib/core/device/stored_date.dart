/// Parses SQLite `datetime('now', 'localtime')` values stored in the app DB.
abstract final class StoredDate {
  static DateTime? parseDateTime(String? raw) {
    if (raw == null || raw.trim().isEmpty) return null;

    final normalized = raw.trim().replaceFirst('T', ' ');
    final parts = normalized.split(' ');
    if (parts.length >= 2) {
      final date = parseDateOnly(parts.first);
      final timeParts = parts[1].split(':');
      if (date != null && timeParts.length >= 2) {
        final hour = int.tryParse(timeParts[0]);
        final minute = int.tryParse(timeParts[1]);
        final second =
            timeParts.length >= 3 ? int.tryParse(timeParts[2]) ?? 0 : 0;
        if (hour != null && minute != null) {
          return DateTime(
            date.year,
            date.month,
            date.day,
            hour,
            minute,
            second,
          );
        }
      }
    }

    return DateTime.tryParse(normalized);
  }

  static DateTime? parseDateOnly(String? raw) {
    final parsed = parseDateTime(raw);
    if (parsed == null) return null;
    return DateTime(parsed.year, parsed.month, parsed.day);
  }

  static DateTime dateOnly(DateTime value) =>
      DateTime(value.year, value.month, value.day);

  static String formatYmd(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  static String formatDateTime(DateTime value) {
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');
    return '${formatYmd(value)} $hour:$minute';
  }
}
