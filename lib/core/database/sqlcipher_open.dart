import 'dart:io';

import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_sqlcipher/sqflite.dart' as sqlcipher;

import '../crypto/database_key.dart';

/// Opens [bingo.db] with SQLCipher, migrating legacy plain SQLite if needed.
abstract final class SqlCipherOpen {
  static const plainBackupSuffix = '.plain.backup';
  static const _encryptingSuffix = '.encrypting';
  static const _sqliteMagic = 'SQLite format 3';

  static Future<Database> open({
    required String path,
    required int version,
    required Future<void> Function(Database db, int version) onCreate,
    Future<void> Function(Database db, int oldVersion, int newVersion)?
        onUpgrade,
  }) async {
    final key = await DatabaseKey.passphrase();
    final escapedKey = DatabaseKey.escapeForPragma(key);

    if (Platform.isAndroid || Platform.isIOS) {
      return _openMobile(
        path: path,
        key: key,
        escapedKey: escapedKey,
        version: version,
        onCreate: onCreate,
        onUpgrade: onUpgrade,
      );
    }

    return _openDesktop(
      path: path,
      escapedKey: escapedKey,
      version: version,
      onCreate: onCreate,
      onUpgrade: onUpgrade,
    );
  }

  static Future<Database> _openMobile({
    required String path,
    required String key,
    required String escapedKey,
    required int version,
    required Future<void> Function(Database db, int version) onCreate,
    Future<void> Function(Database db, int oldVersion, int newVersion)?
        onUpgrade,
  }) async {
    final file = File(path);
    if (await file.exists()) {
      await _cleanupStaleMigrationArtifacts(path);

      if (await _isPlainSqliteFile(path)) {
        await _migratePlainToEncrypted(
          plainPath: path,
          escapedKey: escapedKey,
          openPlain: (plainPath) => sqlcipher.openDatabase(plainPath),
        );
      } else {
        final opened = await _tryOpenMobileEncrypted(
          path: path,
          key: key,
          version: version,
          onCreate: onCreate,
          onUpgrade: onUpgrade,
        );
        if (opened != null) return opened;

        throw StateError(
          'Could not open encrypted bingo.db on this device. '
          'The database may belong to another machine or be corrupted.',
        );
      }
    }

    return sqlcipher.openDatabase(
      path,
      password: key,
      version: version,
      onConfigure: _configureEncrypted,
      onCreate: onCreate,
      onUpgrade: onUpgrade,
    );
  }

  static Future<Database?> _tryOpenMobileEncrypted({
    required String path,
    required String key,
    required int version,
    required Future<void> Function(Database db, int version) onCreate,
    Future<void> Function(Database db, int oldVersion, int newVersion)?
        onUpgrade,
  }) async {
    try {
      final db = await sqlcipher.openDatabase(
        path,
        password: key,
        version: version,
        onConfigure: _configureEncrypted,
        onCreate: onCreate,
        onUpgrade: onUpgrade,
      );
      await _verifyReadable(db);
      return db;
    } catch (_) {
      return null;
    }
  }

  static Future<Database> _openDesktop({
    required String path,
    required String escapedKey,
    required int version,
    required Future<void> Function(Database db, int version) onCreate,
    Future<void> Function(Database db, int oldVersion, int newVersion)?
        onUpgrade,
  }) async {
    final file = File(path);
    if (await file.exists()) {
      await _cleanupStaleMigrationArtifacts(path);

      if (await _isPlainSqliteFile(path)) {
        await _migratePlainToEncrypted(
          plainPath: path,
          escapedKey: escapedKey,
          openPlain: (plainPath) => databaseFactoryFfi.openDatabase(
            plainPath,
            options: OpenDatabaseOptions(version: version),
          ),
        );
      } else {
        final opened = await _tryOpenDesktopEncrypted(
          path: path,
          escapedKey: escapedKey,
          version: version,
          onCreate: onCreate,
          onUpgrade: onUpgrade,
        );
        if (opened != null) return opened;

        throw StateError(
          'Could not open encrypted bingo.db on this device. '
          'The database may belong to another machine or be corrupted.',
        );
      }
    }

    return databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: version,
        onConfigure: (db) => _applyKey(db, escapedKey),
        onCreate: onCreate,
        onUpgrade: onUpgrade,
      ),
    );
  }

  static Future<Database?> _tryOpenDesktopEncrypted({
    required String path,
    required String escapedKey,
    required int version,
    required Future<void> Function(Database db, int version) onCreate,
    Future<void> Function(Database db, int oldVersion, int newVersion)?
        onUpgrade,
  }) async {
    try {
      final db = await databaseFactoryFfi.openDatabase(
        path,
        options: OpenDatabaseOptions(
          version: version,
          onConfigure: (db) => _applyKey(db, escapedKey),
          onCreate: onCreate,
          onUpgrade: onUpgrade,
        ),
      );
      await _verifyReadable(db);
      return db;
    } catch (_) {
      return null;
    }
  }

  /// Encrypts a legacy plain [bingo.db] in place via `PRAGMA rekey`.
  static Future<void> _migratePlainToEncrypted({
    required String plainPath,
    required String escapedKey,
    required Future<Database> Function(String plainPath) openPlain,
  }) async {
    final plainFile = File(plainPath);
    if (!await plainFile.exists()) return;
    if (!await _isPlainSqliteFile(plainPath)) return;

    final backupPath = '$plainPath$plainBackupSuffix';
    final backupFile = File(backupPath);
    if (await backupFile.exists()) {
      await backupFile.delete();
    }
    await plainFile.copy(backupPath);

    final db = await openPlain(plainPath);
    try {
      await _prepareCipherForRekey(db);
      await db.rawQuery("PRAGMA rekey = '$escapedKey'");
      await db.rawQuery("PRAGMA key = '$escapedKey'");
      await _verifyReadable(db);
    } catch (e) {
      await db.close();
      await plainFile.delete();
      await backupFile.copy(plainPath);
      rethrow;
    }
    await db.close();
  }

  static Future<void> _cleanupStaleMigrationArtifacts(String dbPath) async {
    final encrypting = File('$dbPath$_encryptingSuffix');
    if (await encrypting.exists()) {
      await encrypting.delete();
    }
  }

  static Future<bool> _isPlainSqliteFile(String path) async {
    final file = File(path);
    if (!await file.exists()) return false;

    final raf = await file.open();
    try {
      final bytes = await raf.read(16);
      if (bytes.length < _sqliteMagic.length) return false;
      return String.fromCharCodes(bytes.sublist(0, _sqliteMagic.length)) ==
          _sqliteMagic;
    } finally {
      await raf.close();
    }
  }

  /// sqlite3mc on desktop needs SQLCipher compatibility pragmas before rekey.
  static Future<void> _prepareCipherForRekey(Database db) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await db.rawQuery('PRAGMA cipher = "sqlcipher"');
      await db.rawQuery('PRAGMA legacy = 4');
    }
  }

  static Future<void> _configureEncrypted(Database db) async {
    await db.rawQuery('PRAGMA foreign_keys = ON');
    await db.rawQuery('PRAGMA journal_mode = WAL');
    await db.rawQuery('PRAGMA busy_timeout = 30000');
  }

  static Future<void> _applyKey(Database db, String escapedKey) async {
    if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      await db.rawQuery('PRAGMA cipher = "sqlcipher"');
      await db.rawQuery('PRAGMA legacy = 4');
    }
    await db.rawQuery("PRAGMA key = '$escapedKey'");
    await _assertCipherLoaded(db);
    await db.rawQuery('SELECT count(*) FROM sqlite_master');
    await _configureEncrypted(db);
  }

  static Future<void> _assertCipherLoaded(Database db) async {
    final versionRows = await db.rawQuery('PRAGMA cipher_version');
    final version = versionRows.isNotEmpty
        ? '${versionRows.first.values.first}'.trim()
        : '';
    if (version.isNotEmpty) return;

    // sqlite3mc (Windows/desktop) exposes cipher_list / cipher instead.
    final cipherListRows = await db.rawQuery('PRAGMA cipher_list');
    if (cipherListRows.isNotEmpty) return;

    final cipherRows = await db.rawQuery('PRAGMA cipher');
    if (cipherRows.isNotEmpty) return;

    throw StateError('SQLCipher is not available in this SQLite build.');
  }

  static Future<void> _verifyReadable(Database db) async {
    await _assertCipherLoaded(db);
    await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table' LIMIT 1",
    );
  }
}
