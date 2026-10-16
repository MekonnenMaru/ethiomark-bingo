import 'package:shared_preferences/shared_preferences.dart';

/// Remote admin domain — same idea as `config/deposit.domain.php`.
class AppConfig {
  static const defaultDomain = 'ethiomark.com';
  static const defaultPartnerId = 27;
  /// Package sync API (legacy off1919 host).
  static const subdomain = 'off1919';
  static const syncPath = '/admin/sync_cashier_package.php';
  static const scheme = 'http';

  /// Login/setup notices — ad19 admin panel (flat /19p/ deploy on server).
  static const authInfoSubdomain = 'ad19';
  static const authInfoPath = '/19p/auth_info.php';
  static const authInfoScheme = 'https';

  static const _domainKey = 'remote_domain';

  static Future<String> getRemoteDomain() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_domainKey) ?? defaultDomain;
  }

  static Future<void> setRemoteDomain(String domain) async {
    final normalized = domain
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'^https?://'), '')
        .replaceAll(RegExp(r'/.*$'), '')
        .replaceAll(RegExp(r'^off1919\.'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _domainKey,
      normalized.isEmpty ? defaultDomain : normalized,
    );
  }

  static String buildSyncUrl(String domain) {
    final clean = domain.trim().isEmpty ? defaultDomain : domain.trim();
    return '$scheme://$subdomain.$clean$syncPath';
  }

  static Future<String> remoteSyncUrl() async {
    return buildSyncUrl(await getRemoteDomain());
  }

  static String buildAuthInfoUrl(String domain) {
    final clean = domain.trim().isEmpty ? defaultDomain : domain.trim();
    return '$authInfoScheme://$authInfoSubdomain.$clean$authInfoPath';
  }

  static Future<String> remoteAuthInfoUrl() async {
    return buildAuthInfoUrl(await getRemoteDomain());
  }
}
