import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../core/config/app_config.dart';
import '../../core/config/cashier_defaults.dart';
import '../../core/crypto/package_crypto.dart';
import '../../core/device/device_binding.dart';
import '../../core/device/device_id.dart';
import '../../core/trial/trial_prefs.dart';
import '../database/app_database.dart';
import '../models/cashier_session.dart';

/// Wrong password / locked account details for login alerts.
class LoginAuthException implements Exception {
  LoginAuthException.wrongPassword({
    required this.attemptsUsed,
    required this.attemptsRemaining,
  })  : locked = false,
        inactive = false;

  LoginAuthException.locked({
    required this.attemptsUsed,
  })  : attemptsRemaining = 0,
        locked = true,
        inactive = false;

  LoginAuthException.inactive()
      : attemptsUsed = 0,
        attemptsRemaining = 0,
        locked = false,
        inactive = true;

  final int attemptsUsed;
  final int attemptsRemaining;
  final bool locked;
  final bool inactive;

  @override
  String toString() => locked
      ? 'Cashier account is locked.'
      : inactive
          ? 'Cashier account is not active.'
          : 'Invalid credentials ($attemptsRemaining left).';
}

class AuthRepository {
  AuthRepository(this._db);

  final AppDatabase _db;

  /// Failed passwords allowed before `is_locked` is set.
  static const maxLoginAttempts = CashierDefaults.maxLoginAttempts;

  String _md5(String input) {
    return md5.convert(utf8.encode(input)).toString();
  }

  Future<CashierSession?> login(String cashierId, String password) async {
    final db = await _db.database;
    await DeviceBinding.verify(db);
    final rows = await db.query(
      'cashier',
      where: 'cashier_id = ?',
      whereArgs: [cashierId.trim()],
      limit: 1,
    );
    if (rows.isEmpty) return null;

    final row = rows.first;
    final storedHash = row['password'] as String? ?? '';
    if (storedHash != _md5(password)) {
      final attempts = (row['login_attempts'] as int? ?? 0) + 1;
      final lockedNow = attempts >= maxLoginAttempts;
      await db.update(
        'cashier',
        {
          'login_attempts': attempts,
          'is_locked': lockedNow ? 1 : 0,
        },
        where: 'cashier_id = ?',
        whereArgs: [cashierId],
      );
      final remaining =
          (maxLoginAttempts - attempts).clamp(0, maxLoginAttempts);
      if (lockedNow) {
        throw LoginAuthException.locked(attemptsUsed: attempts);
      }
      throw LoginAuthException.wrongPassword(
        attemptsUsed: attempts,
        attemptsRemaining: remaining,
      );
    }

    if ((row['is_locked'] as int? ?? 0) == 1) {
      final used = row['login_attempts'] as int? ?? maxLoginAttempts;
      throw LoginAuthException.locked(attemptsUsed: used);
    }
    if ((row['is_active'] as int? ?? 0) != 1) {
      throw LoginAuthException.inactive();
    }

    await db.update(
      'cashier',
      {'login_attempts': 0, 'is_locked': 0, 'is_loggedin': 1},
      where: 'cashier_id = ?',
      whereArgs: [cashierId],
    );

    final balance = await _readPackageBalance(row);

    return CashierSession(
      cashierId: cashierId,
      partnerId: row['partner_id'] as int,
      category: row['category'] as String? ?? 'default',
      packageBalance: balance,
      isActive: true,
    );
  }

  Future<void> logout(String cashierId) async {
    final db = await _db.database;
    await db.update(
      'cashier',
      {'is_loggedin': 0},
      where: 'cashier_id = ?',
      whereArgs: [cashierId],
    );
  }

  Future<String> _readPackageBalance(Map<String, Object?> row) async {
    final stored = row['cashier_package'] as String?;
    final mid = row['mid'] as String?;
    var balance = PackageCrypto.decryptCashierPackage(
      stored,
      encryptedMid: mid,
    );
    if (balance == '0' &&
        stored != null &&
        stored.trim().isNotEmpty &&
        num.tryParse(stored.trim()) == null) {
      final serial = await DeviceId.getSerial();
      balance = PackageCrypto.decryptCashierPackage(
        stored,
        serial: serial,
        encryptedMid: mid,
      );
    }
    return balance;
  }
}

class SetupRepository {
  SetupRepository(this._db);

  final AppDatabase _db;

  String _md5(String input) {
    return md5.convert(utf8.encode(input)).toString();
  }

  Future<void> createInitialCashier({
    required String cashierId,
    required String password,
    required String initialPackage,
    int partnerId = AppConfig.defaultPartnerId,
  }) async {
    if (partnerId < 1) {
      throw ArgumentError('Partner ID must be at least 1.');
    }

    final db = await _db.database;
    final serial = await DeviceId.getSerial();
    final encryptedMid = PackageCrypto.encryptMachineMid(serial);
    final encryptedPackage = PackageCrypto.encryptCashierPackage(
      initialPackage,
      serial,
    );

    await ensurePartnerExists(partnerId);

    final trimmedId = cashierId.trim();
    final priorTrials = await TrialPrefs.loadRoundsUsed(trimmedId);

    await db.transaction((txn) async {
      await txn.insert('cashier', {
        'cashier_id': trimmedId,
        'password': _md5(password),
        'partner_id': partnerId,
        'is_loggedin': 0,
        'is_locked': 0,
        'is_active': 1,
        'cashier_package': encryptedPackage,
        'mid': encryptedMid,
        'trial_rounds_used': priorTrials,
        'sound': CashierDefaults.callerVoice,
        'speed_range': CashierDefaults.speedRange,
        'cashier_profit': 0,
        'auto_check_result': CashierDefaults.checkMode,
        'good_bingo_sound': CashierDefaults.goodBingoSound,
        'new_bonus_status': 'on',
        'max_new_bonus_per_day': 1,
        'settings_json': CashierDefaults.settingsJson,
      });
    });
  }

  Future<void> ensurePartnerExists(int partnerId) async {
    final db = await _db.database;
    final rows = await db.query(
      'partner',
      where: 'partner_id = ?',
      whereArgs: [partnerId],
      limit: 1,
    );
    if (rows.isNotEmpty) return;

    await db.insert('partner', {
      'partner_id': partnerId,
      'partner_full_name': 'Partner $partnerId',
      'partner_phone': '0000000000',
      'partner_balance': 0,
      'user_name': 'partner$partnerId',
      'password': _md5('partner$partnerId'),
      'percent': 20,
    });
  }

  /// Update cashier ID (primary key) and partner ID on this device.
  Future<void> updateCashierIdentity({
    required String oldCashierId,
    required String newCashierId,
    required int partnerId,
  }) async {
    final newId = newCashierId.trim();
    final oldId = oldCashierId.trim();
    if (newId.isEmpty) throw ArgumentError('Cashier ID cannot be empty.');
    if (partnerId < 1) throw ArgumentError('Partner ID must be at least 1.');

    final db = await _db.database;
    final rows = await db.query(
      'cashier',
      where: 'cashier_id = ?',
      whereArgs: [oldId],
      limit: 1,
    );
    if (rows.isEmpty) throw StateError('Cashier not found.');

    if (newId != oldId) {
      final clash = await db.query(
        'cashier',
        where: 'cashier_id = ?',
        whereArgs: [newId],
        limit: 1,
      );
      if (clash.isNotEmpty)
        throw StateError('Cashier ID "$newId" already exists.');
    }

    await ensurePartnerExists(partnerId);

    await db.transaction((txn) async {
      if (newId != oldId) {
        final data = Map<String, Object?>.from(rows.first);
        data['cashier_id'] = newId;
        data['partner_id'] = partnerId;
        await txn.insert('cashier', data);

        for (final table in [
          'game',
          '"transaction"',
          'new_bonus',
          'game_bonus',
          'transaction_logs',
        ]) {
          await txn.update(
            table,
            {'cashier_id': newId},
            where: 'cashier_id = ?',
            whereArgs: [oldId],
          );
        }

        await txn.delete(
          'cashier',
          where: 'cashier_id = ?',
          whereArgs: [oldId],
        );
      } else {
        await txn.update(
          'cashier',
          {'partner_id': partnerId},
          where: 'cashier_id = ?',
          whereArgs: [oldId],
        );
      }
    });
  }

  /// Remove cashier and related local data; deletes partner if no other cashiers use it.
  Future<void> deleteCashierAccount(String cashierId) async {
    final db = await _db.database;
    final rows = await db.query(
      'cashier',
      where: 'cashier_id = ?',
      whereArgs: [cashierId.trim()],
      limit: 1,
    );
    if (rows.isEmpty) return;

    final partnerId = rows.first['partner_id'];

    await db.transaction((txn) async {
      for (final table in [
        'game',
        '"transaction"',
        'new_bonus',
        'game_bonus',
        'transaction_logs',
      ]) {
        await txn.delete(
          table,
          where: 'cashier_id = ?',
          whereArgs: [cashierId],
        );
      }
      await txn.delete(
        'cashier',
        where: 'cashier_id = ?',
        whereArgs: [cashierId],
      );

      final others = await txn.query(
        'cashier',
        where: 'partner_id = ?',
        whereArgs: [partnerId],
      );
      if (others.isEmpty) {
        await txn.delete(
          'partner',
          where: 'partner_id = ?',
          whereArgs: [partnerId],
        );
      }
    });
  }
}
