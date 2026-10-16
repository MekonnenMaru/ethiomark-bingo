import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../core/config/cashier_defaults.dart';
import '../../core/database/database_storage.dart';
import '../../core/database/sqlcipher_open.dart';
import '../../core/device/device_binding.dart';
import 'schema.dart';

/// Serializes DB access — required for sqflite FFI on desktop.
class _DbMutex {
  Future<void> _chain = Future.value();

  Future<T> run<T>(Future<T> Function() action) {
    final result = _chain.then((_) => action());
    _chain = result.then((_) {}, onError: (_) {});
    return result;
  }
}

class AppDatabase {
  AppDatabase._();
  static final AppDatabase instance = AppDatabase._();

  Database? _db;
  final _mutex = _DbMutex();

  Future<Database> get database async {
    if (_db != null) return _db!;
    _db = await _open();
    return _db!;
  }

  /// Run one DB operation at a time to avoid SQLITE_BUSY / lock warnings.
  Future<T> run<T>(Future<T> Function(Database db) action) {
    return _mutex.run(() async {
      final db = await database;
      return action(db);
    });
  }

  Future<Database> _open() async {
    final path = await DatabaseStorage.databasePath();
    final db = await SqlCipherOpen.open(
      path: path,
      version: 4,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
    await DeviceBinding.verify(db);
    // Safety net if upgrade path was skipped / already on v4 after a partial update.
    await _relaxLegacyLoginLocks(db);
    return db;
  }

  Future<void> _onCreate(Database db, int version) async {
    final statements = kCreateSchemaSql
        .split(';')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty);
    for (final statement in statements) {
      await db.execute(statement);
    }
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await _migrateTransactionIncomeToReal(db);
    }
    if (oldVersion < 3) {
      await _migrateTrialTracking(db);
    }
    if (oldVersion < 4) {
      await _relaxLegacyLoginLocks(db);
    }
  }

  /// Old builds locked after 5 wrong passwords. New limit is 100 — unlock anyone
  /// still locked with fewer than [CashierDefaults.maxLoginAttempts] attempts.
  Future<void> _relaxLegacyLoginLocks(Database db) async {
    await db.update(
      'cashier',
      {'is_locked': 0, 'login_attempts': 0},
      where: 'is_locked = 1 AND login_attempts < ?',
      whereArgs: [CashierDefaults.maxLoginAttempts],
    );
  }

  Future<void> _migrateTrialTracking(Database db) async {
    await db.execute(
      'ALTER TABLE cashier ADD COLUMN trial_rounds_used INTEGER NOT NULL DEFAULT 0',
    );
    await db.execute(
      'ALTER TABLE "transaction" ADD COLUMN is_trial INTEGER NOT NULL DEFAULT 0',
    );
  }

  Future<void> _migrateTransactionIncomeToReal(Database db) async {
    await db.execute('''
      CREATE TABLE IF NOT EXISTS "transaction_mig" (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        cashier_id TEXT NOT NULL,
        game_round INTEGER NOT NULL,
        santim TEXT NOT NULL,
        sew TEXT NOT NULL,
        income REAL NOT NULL,
        bonus REAL NOT NULL DEFAULT 0,
        date TEXT NOT NULL DEFAULT (datetime('now', 'localtime')),
        result TEXT,
        checked_number TEXT
      )
    ''');
    await db.execute('''
      INSERT INTO "transaction_mig"
      SELECT id, cashier_id, game_round, santim, sew, CAST(income AS REAL), bonus, date, result, checked_number
      FROM "transaction"
    ''');
    await db.execute('DROP TABLE "transaction"');
    await db.execute('ALTER TABLE "transaction_mig" RENAME TO "transaction"');
  }

  Future<int> countCashiers() async {
    return run((db) async {
      final result = await db.rawQuery('SELECT COUNT(*) AS c FROM cashier');
      return Sqflite.firstIntValue(result) ?? 0;
    });
  }

  Future<int> countCartelas() async {
    return run((db) async {
      final result = await db.rawQuery('SELECT COUNT(*) AS c FROM cartela');
      return Sqflite.firstIntValue(result) ?? 0;
    });
  }
}
