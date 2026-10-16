import '../device/device_id.dart';
import 'package_crypto.dart';

/// Derives the SQLCipher passphrase for [bingo.db] on this device.
abstract final class DatabaseKey {
  static Future<String> passphrase() async {
    final serial = await DeviceId.getSerial();
    return '${PackageCrypto.baseKey}|${serial.trim()}|ethiomark-bingo-v1';
  }

  /// Escape single quotes for `PRAGMA key = '...'`.
  static String escapeForPragma(String key) => key.replaceAll("'", "''");
}
