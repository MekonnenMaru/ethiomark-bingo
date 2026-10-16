import '../../data/repositories/game_repository.dart';
import 'east_africa_time.dart';
import 'stored_date.dart';

/// Detects device clock issues: wrong timezone and/or date behind last activity.
abstract final class DeviceDateValidator {
  static Future<DeviceDateMismatch?> findMismatch({
    required GameRepository gameRepository,
    required String cashierId,
  }) async {
    final deviceNow = DateTime.now();
    final wrongTimezone = !EastAfricaTime.isDeviceTimeZoneValid(deviceNow);

    final lastActivity = await gameRepository.getLatestRecordedActivityAt(
      cashierId,
    );

    var dateBehind = false;
    if (lastActivity != null) {
      final deviceDate = StoredDate.dateOnly(deviceNow);
      final lastActivityDate = StoredDate.dateOnly(lastActivity);
      dateBehind = deviceDate.isBefore(lastActivityDate);
    }

    if (!wrongTimezone && !dateBehind) return null;

    return DeviceDateMismatch(
      deviceTime: deviceNow,
      lastActivityTime: lastActivity,
      dateBehind: dateBehind,
      wrongTimezone: wrongTimezone,
    );
  }
}

class DeviceDateMismatch {
  const DeviceDateMismatch({
    required this.deviceTime,
    required this.lastActivityTime,
    required this.dateBehind,
    required this.wrongTimezone,
  });

  final DateTime deviceTime;
  final DateTime? lastActivityTime;
  final bool dateBehind;
  final bool wrongTimezone;
}
