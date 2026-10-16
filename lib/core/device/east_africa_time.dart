/// East Africa Time (EAT) — UTC+3, used in Nairobi and Addis Ababa.
abstract final class EastAfricaTime {
  static const offsetMinutes = 180;

  static const requiredZoneLabel = 'East Africa Time (UTC+3)';

  static bool isValidOffset(Duration offset) => offset.inMinutes == offsetMinutes;

  static bool isDeviceTimeZoneValid([DateTime? at]) {
    final now = at ?? DateTime.now();
    return isValidOffset(now.timeZoneOffset);
  }

  static String formatOffset(Duration offset) {
    final totalMinutes = offset.inMinutes;
    final sign = totalMinutes >= 0 ? '+' : '-';
    final abs = totalMinutes.abs();
    final hours = abs ~/ 60;
    final minutes = abs % 60;
    if (minutes == 0) return 'UTC$sign$hours';
    final minuteText = minutes.toString().padLeft(2, '0');
    return 'UTC$sign$hours:$minuteText';
  }

  static String deviceZoneDescription(DateTime at) {
    final name = at.timeZoneName.trim();
    final offset = formatOffset(at.timeZoneOffset);
    if (name.isEmpty) return offset;
    return '$name ($offset)';
  }
}
