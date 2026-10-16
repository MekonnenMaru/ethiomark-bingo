import 'package:sqflite_sqlcipher/sqflite.dart';

import '../crypto/package_crypto.dart';
import 'device_id.dart';

/// Thrown when the local database is bound to a different device serial.
class DeviceBindingException implements Exception {
  const DeviceBindingException();
}

/// Binds the encrypted local database to one machine via [cashier.mid].
abstract final class DeviceBinding {
  /// Verifies every cashier row's encrypted machine id matches this device.
  ///
  /// Empty [mid] on an existing cashier is bound to the current device once.
  static Future<void> verify(Database db) async {
    final current = (await DeviceId.getSerial()).trim();
    if (current.isEmpty || current == 'DEVICE-UNKNOWN') {
      throw const DeviceBindingException();
    }

    final rows = await db.query('cashier', columns: ['cashier_id', 'mid']);
    if (rows.isEmpty) return;

    for (final row in rows) {
      final cashierId = row['cashier_id'] as String?;
      final mid = row['mid'] as String?;

      if (mid == null || mid.trim().isEmpty) {
        if (cashierId == null) continue;
        await db.update(
          'cashier',
          {'mid': PackageCrypto.encryptMachineMid(current)},
          where: 'cashier_id = ?',
          whereArgs: [cashierId],
        );
        continue;
      }

      final boundSerial = PackageCrypto.decryptValue(mid, current);
      if (boundSerial != current) {
        throw const DeviceBindingException();
      }
    }
  }
}
