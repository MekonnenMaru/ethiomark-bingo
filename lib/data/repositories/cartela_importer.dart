import 'dart:convert';

import 'package:flutter/services.dart' show rootBundle;
import 'package:sqflite_sqlcipher/sqflite.dart';

import '../../core/bootstrap/bootstrap_cache.dart';
import '../../core/crypto/cartela_crypto.dart';
import '../../core/performance/managed_loader.dart';
import '../../core/performance/resource_budget.dart';
import '../database/app_database.dart';

class CartelaImporter {
  CartelaImporter(this._db);

  final AppDatabase _db;

  static const encryptedAssetPath =
      'assets/data/all_card_with_all_categotry.enc';

  Future<int> importIfEmpty({
    void Function(int current, int total)? onProgress,
  }) async {
    if (await BootstrapCache.isCartelasReady()) {
      final cached = await BootstrapCache.cachedCartelaCount();
      if (cached != null && cached > 0) return cached;
    }

    final existing = await _db.countCartelas();
    if (existing > 0) {
      await BootstrapCache.markCartelasReady(existing);
      return existing;
    }

    final encrypted = await rootBundle.loadString(encryptedAssetPath);
    final imported = await importFromEncryptedText(
      encrypted,
      onProgress: onProgress,
    );
    await BootstrapCache.markCartelasReady(imported);
    return imported;
  }

  Future<int> importFromEncryptedText(
    String encrypted, {
    void Function(int current, int total)? onProgress,
    bool merge = true,
  }) async {
    final json = CartelaCrypto.decrypt(encrypted);
    return importFromJsonString(json, onProgress: onProgress, merge: merge);
  }

  Future<int> importFromJsonString(
    String raw, {
    void Function(int current, int total)? onProgress,
    bool merge = true,
  }) async {
    final rows = parseCartelaRows(raw);
    return _importRows(rows, onProgress: onProgress, merge: merge);
  }

  static List<Map<String, dynamic>> parseCartelaRows(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! List) {
      throw FormatException('Cartela JSON must be a list.');
    }

    Map<String, dynamic>? table;
    for (final item in decoded) {
      if (item is Map<String, dynamic> && item['type'] == 'table') {
        table = item;
        break;
      }
    }

    final data = table?['data'];
    if (data is! List || data.isEmpty) {
      throw FormatException('No cartela rows found in JSON export.');
    }

    final rows = <Map<String, dynamic>>[];
    for (final row in data) {
      if (row is Map) {
        rows.add(Map<String, dynamic>.from(row));
      }
    }
    return rows;
  }

  /// Imports in short per-chunk transactions under the DB mutex.
  /// Yields between chunks so the UI can paint (never inside an open txn).
  Future<int> _importRows(
    List<Map<String, dynamic>> data, {
    void Function(int current, int total)? onProgress,
    bool merge = true,
  }) async {
    final chunkSize = ResourceBudget.importChunkSize;
    var imported = 0;

    return _db.run((db) async {
      if (merge) {
        final categories = data
            .map((row) => '${row['category'] ?? 'default'}')
            .toSet();
        await db.transaction((txn) async {
          for (final category in categories) {
            await txn.delete(
              'cartela',
              where: 'category = ?',
              whereArgs: [category],
            );
          }
        });
      }

      for (var i = 0; i < data.length; i += chunkSize) {
        final end = i + chunkSize > data.length ? data.length : i + chunkSize;
        await db.transaction((txn) async {
          final batch = txn.batch();
          for (var j = i; j < end; j++) {
            final row = data[j];
            batch.insert('cartela', {
              'cartela_number': int.tryParse('${row['cartela_number']}') ?? 0,
              'b': '${row['b']}',
              'i': '${row['i']}',
              'n': '${row['n']}',
              'g': '${row['g']}',
              'o': '${row['o']}',
              'date': row['date'] ?? DateTime.now().toIso8601String(),
              'category': row['category'] ?? 'default',
            }, conflictAlgorithm: ConflictAlgorithm.ignore);
          }
          await batch.commit(noResult: true);
        });
        imported = end;
        onProgress?.call(end, data.length);
        await ManagedLoader.breathe();
      }

      onProgress?.call(imported, data.length);
      return imported;
    });
  }
}
