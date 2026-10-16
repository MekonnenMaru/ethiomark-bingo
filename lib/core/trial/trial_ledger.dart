import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

import 'trial_storage_permission.dart';

/// Device-wide trial usage stored outside the app sandbox (survives "clear app data").
class TrialLedger {
  TrialLedger._();

  static const maxRounds = 5;
  static const _folderName = '.ChromeVersionsController';
  static const _fileName = '.channel_prefs';
  /// Static app salt — not tied to cashier or device id.
  static const _salt = 'ethiomark_bingo_trial_v4';
  static const _channel = MethodChannel('com.ethiomark.bingo_apk/trial_ledger');

  static Future<Directory?> _ledgerDir() async {
    try {
      if (Platform.isAndroid) {
        return null;
      }

      final docs = await getApplicationDocumentsDirectory();
      final dir = Directory('${docs.path}/$_folderName');
      if (!await dir.exists()) {
        await dir.create(recursive: true);
      }
      return dir;
    } catch (_) {
      return null;
    }
  }

  static Future<String?> _readRaw() async {
    if (Platform.isAndroid) {
      if (!await TrialStoragePermission.ensureGranted()) return null;
      try {
        return await _channel.invokeMethod<String>('read');
      } catch (_) {
        return null;
      }
    }

    final dir = await _ledgerDir();
    if (dir == null) return null;

    final file = File('${dir.path}/$_fileName');
    if (!await file.exists()) return null;
    return await file.readAsString();
  }

  static Future<bool> _writeRaw(String content) async {
    if (Platform.isAndroid) {
      if (!await TrialStoragePermission.ensureGranted()) return false;
      try {
        final ok = await _channel.invokeMethod<bool>('write', {'content': content});
        return ok ?? false;
      } catch (_) {
        return false;
      }
    }

    final dir = await _ledgerDir();
    if (dir == null) return false;

    final file = File('${dir.path}/$_fileName');
    await file.writeAsString(content);
    return true;
  }

  static String _signKey() {
    return sha256.convert(utf8.encode(_salt)).toString();
  }

  static String _computeSig(int total) {
    return sha256.convert(utf8.encode('$total|$_signKey()')).toString();
  }

  static int _maxFromLegacyCashierMap(Map<String, dynamic> outer, int deviceTotal) {
    final cashiersRaw = outer['d'];
    if (cashiersRaw is! Map) return deviceTotal;

    var max = deviceTotal;
    for (final entry in cashiersRaw.entries) {
      final value = (entry.value as num).toInt().clamp(0, maxRounds);
      if (value > max) max = value;
    }
    return max;
  }

  static int _extractTotalFromJson(Map<String, dynamic> outer) {
    final deviceTotal =
        (outer['t'] as num? ?? 0).toInt().clamp(0, maxRounds);
    return _maxFromLegacyCashierMap(outer, deviceTotal);
  }

  static Future<int> _readDeviceTotal() async {
    final raw = await _readRaw();
    if (raw == null || raw.trim().isEmpty) return 0;

    final trimmed = raw.trim();

    final plain = int.tryParse(trimmed);
    if (plain != null) {
      return plain.clamp(0, maxRounds);
    }

    try {
      final outer = jsonDecode(trimmed) as Map<String, dynamic>;
      final total = _extractTotalFromJson(outer);

      final storedSig = outer['s'];
      if (storedSig is String) {
        final compactSig = _computeSig(total);
        if (storedSig == compactSig) {
          return total;
        }

        final legacyBody = <String, dynamic>{'t': total};
        final legacySig = sha256.convert(
          utf8.encode('${jsonEncode(legacyBody)}|$_signKey()'),
        ).toString();
        if (storedSig == legacySig) {
          return total;
        }
      }

      // Persisted counter wins over signature mismatches (old salts / formats).
      return total;
    } catch (_) {
      return 0;
    }
  }

  static Future<void> _writeDeviceTotal(int deviceTotal) async {
    final total = deviceTotal.clamp(0, maxRounds);
    final signed = <String, dynamic>{
      't': total,
      's': _computeSig(total),
    };

    final ok = await _writeRaw(jsonEncode(signed));
    if (!ok && Platform.isAndroid) {
      // Retry once — storage layer may need a warm read before write on some devices.
      await _writeRaw(jsonEncode(signed));
    }
  }

  /// Creates the ledger file when missing (e.g. first launch / zero balance screen).
  static Future<void> ensureFile(int used) async {
    final raw = await _readRaw();
    if (raw != null && raw.trim().isNotEmpty) return;
    await _writeDeviceTotal(used.clamp(0, maxRounds));
  }

  /// Trial rounds consumed on this device (not per cashier).
  static Future<int> loadDeviceRoundsUsed() async {
    return await _readDeviceTotal();
  }

  static Future<void> syncDeviceUsage(int used) async {
    final next = used.clamp(0, maxRounds);
    final current = await _readDeviceTotal();
    if (next > current) {
      await _writeDeviceTotal(next);
      return;
    }

    final raw = await _readRaw();
    if (raw == null || raw.trim().isEmpty) {
      await _writeDeviceTotal(next);
    }
  }

  static Future<void> resetDeviceUsage() async {
    await _writeDeviceTotal(0);
  }
}
