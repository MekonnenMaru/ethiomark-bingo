import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'auth_info_controller.dart';
import 'auth_welcome_defaults.dart';

class AuthInfoSnapshot {
  const AuthInfoSnapshot({
    required this.notices,
    this.lastSyncedAt,
  });

  final List<AuthRemoteNotice> notices;
  final DateTime? lastSyncedAt;
}

/// Cached remote auth notices for offline login/setup screen.
class AuthInfoPrefs {
  AuthInfoPrefs._();

  static const _listCacheKey = 'auth_remote_notices_json';
  static const _syncedAtKey = 'auth_remote_notices_synced_at';
  static const _legacyCacheKey = 'auth_remote_notice_json';

  static Future<AuthInfoSnapshot> loadSnapshot() async {
    final prefs = await SharedPreferences.getInstance();

    final listRaw = prefs.getString(_listCacheKey);
    if (listRaw != null && listRaw.isNotEmpty) {
      try {
        final decoded = jsonDecode(listRaw);
        if (decoded is List) {
          final notices = decoded
              .whereType<Map>()
              .map((m) => AuthRemoteNotice.fromJson(Map<String, dynamic>.from(m)))
              .where((n) => n.isValid)
              .toList();
          final withWelcome = ensureBundledWelcome(notices);
          final syncedRaw = prefs.getString(_syncedAtKey);
          return AuthInfoSnapshot(
            notices: withWelcome,
            lastSyncedAt: syncedRaw != null ? DateTime.tryParse(syncedRaw) : null,
          );
        }
      } catch (_) {}
    }

    final legacyRaw = prefs.getString(_legacyCacheKey);
    if (legacyRaw == null || legacyRaw.isEmpty) {
      final bundled = [AuthWelcomeDefaults.bundled];
      await saveSnapshot(notices: bundled);
      return AuthInfoSnapshot(notices: bundled);
    }
    try {
      final map = jsonDecode(legacyRaw);
      if (map is! Map<String, dynamic>) {
        return const AuthInfoSnapshot(notices: []);
      }
      final notice = AuthRemoteNotice.fromJson(map);
      if (!notice.isValid) return const AuthInfoSnapshot(notices: []);
      final list = [notice];
      await saveSnapshot(notices: list);
      await prefs.remove(_legacyCacheKey);
      return AuthInfoSnapshot(notices: list);
    } catch (_) {
      return const AuthInfoSnapshot(notices: []);
    }
  }

  static Future<List<AuthRemoteNotice>> loadCached() async {
    final snapshot = await loadSnapshot();
    return snapshot.notices;
  }

  static Future<void> saveSnapshot({
    required List<AuthRemoteNotice> notices,
    DateTime? lastSyncedAt,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final valid = notices.where((n) => n.isValid).toList();
    if (valid.isEmpty) {
      await prefs.remove(_listCacheKey);
      await prefs.remove(_syncedAtKey);
      await prefs.remove(_legacyCacheKey);
      return;
    }
    await prefs.setString(
      _listCacheKey,
      jsonEncode(valid.map((n) => n.toJson()).toList()),
    );
    if (lastSyncedAt != null) {
      await prefs.setString(_syncedAtKey, lastSyncedAt.toIso8601String());
    } else {
      await prefs.remove(_syncedAtKey);
    }
    await prefs.remove(_legacyCacheKey);
  }

  static Future<void> saveCached(List<AuthRemoteNotice> notices) async {
    await saveSnapshot(notices: notices);
  }

  static List<AuthRemoteNotice> ensureBundledWelcome(
    List<AuthRemoteNotice> notices,
  ) {
    final hasWelcome = notices.any(
      (notice) => notice.messageType == AuthInfoController.welcomeMessageType,
    );
    if (hasWelcome) return notices;
    return [AuthWelcomeDefaults.bundled, ...notices];
  }
}
