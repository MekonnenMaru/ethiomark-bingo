import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../data/database/app_database.dart';
import 'trial_ledger.dart';

/// Device-wide free trial counter. External ledger is the source of truth.
class TrialPrefs {
  TrialPrefs._();

  static const maxRounds = TrialLedger.maxRounds;
  static const _deviceRoundsKey = 'free_trial_rounds_used';

  /// Loads trial rounds used on this device. Cashier/partner id is ignored.
  static Future<int> loadRoundsUsed([String? cashierId]) async {
    final fromLedger = await TrialLedger.loadDeviceRoundsUsed();

    final db = await AppDatabase.instance.database;

    final cashierMaxResult = await db.rawQuery(
      'SELECT MAX(trial_rounds_used) AS m FROM cashier',
    );
    final fromCashiers =
        (Sqflite.firstIntValue(cashierMaxResult) ?? 0).clamp(0, maxRounds);

    final txResult = await db.rawQuery(
      'SELECT COUNT(*) AS c FROM "transaction" WHERE is_trial = 1',
    );
    final fromTransactions =
        (Sqflite.firstIntValue(txResult) ?? 0).clamp(0, maxRounds);

    final prefs = await SharedPreferences.getInstance();
    final fromPrefs =
        (prefs.getInt(_deviceRoundsKey) ?? 0).clamp(0, maxRounds);

    final used = _maxOf(
      fromLedger,
      fromCashiers,
      fromTransactions,
      fromPrefs,
    );

    await TrialLedger.ensureFile(used);

    if (used > fromLedger) {
      await TrialLedger.syncDeviceUsage(used);
    }

    if (used > fromPrefs) {
      await prefs.setInt(_deviceRoundsKey, used);
    }

    if (used > fromCashiers) {
      await _writeAllCashiersTrial(db, used);
    }

    return used;
  }

  static Future<int> increment([String? cashierId]) async {
    final current = await loadRoundsUsed();
    final next = (current + 1).clamp(0, maxRounds);

    await TrialLedger.syncDeviceUsage(next);
    await TrialLedger.ensureFile(next);

    final db = await AppDatabase.instance.database;
    await _writeAllCashiersTrial(db, next);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_deviceRoundsKey, next);

    return next;
  }

  static Future<void> reset() async {
    await TrialLedger.resetDeviceUsage();

    final db = await AppDatabase.instance.database;
    await _writeAllCashiersTrial(db, 0);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_deviceRoundsKey);
  }

  static int _maxOf(int a, int b, int c, int d) {
    return [a, b, c, d].reduce((left, right) => left > right ? left : right);
  }

  static Future<void> _writeAllCashiersTrial(Database db, int value) async {
    await db.update(
      'cashier',
      {'trial_rounds_used': value.clamp(0, maxRounds)},
    );
  }
}
