import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../bootstrap/bootstrap_cache.dart';

/// Resolves the disguised on-disk location for the encrypted local database.
///
/// Documented in `admin-remote/TECHNICAL_DOCUMENTATION.md` →
/// "Local SQLite storage (cashier app)".
abstract final class DatabaseStorage {
  static const storageFolderName = 'Edge Ver Control';
  static const databaseFileName = 'UpdateState';

  /// Windows: `%APPDATA%\Edge Ver Control\` (Roaming root).
  /// Other platforms: app-private support dir with the same folder name.
  static Future<Directory> storageDirectory() async {
    if (Platform.isWindows) {
      final roaming = Platform.environment['APPDATA'];
      if (roaming != null && roaming.isNotEmpty) {
        return Directory(p.join(roaming, storageFolderName));
      }
    }

    final root = await getApplicationSupportDirectory();
    return Directory(p.join(root.path, storageFolderName));
  }

  static Future<String> databasePath() async {
    final storageDir = await storageDirectory();
    await storageDir.create(recursive: true);
    if (!await BootstrapCache.areDecoysReady()) {
      await _ensureDecoyFiles(storageDir);
      await BootstrapCache.markDecoysReady();
    }
    return p.join(storageDir.path, databaseFileName);
  }

  static Future<void> _ensureDecoyFiles(Directory storageDir) async {
    const currentVersion = '131.0.6778.86';
    const previousVersion = '131.0.6778.85';

    await _writeDecoys(storageDir, {
      'Last Version': '$currentVersion\n',
      'previous_version': '$previousVersion\n',
      'pending_update_version': '',
      'last_successful_update': '2025-03-15T09:42:11.384Z\n',
      'update_check_time': '2025-03-15T12:00:04.127Z\n',
      'update_installation_state.json': '''
{
  "active_version": "$currentVersion",
  "install_progress": "complete",
  "is_rollback": false,
  "last_install_result": "success",
  "previous_version": "$previousVersion",
  "update_channel": "stable",
  "update_reason": "periodic_background_check"
}
''',
      'deferred_update_manifest.json': '''
{
  "deferred": false,
  "next_version": "",
  "priority": "background",
  "reason": "none"
}
''',
      'update_check_response.json': '''
{
  "appid": "{8A69D345-D564-463C-AFF1-A69D9E530F96}",
  "brand": "GGLS",
  "daystart_elapsed_seconds": 43218,
  "daystart_status": "ok",
  "nextversion": "$currentVersion",
  "status": "ok",
  "updatedisabled": false,
  "version": "$previousVersion"
}
''',
      'installer_prefs.json': '''
{
  "autoupdate": true,
  "cohort": "1:1y5:",
  "cohortname": "Stable",
  "eulaaccepted": true,
  "last_checked": "2025-03-15T12:00:04.127Z",
  "last_os_version": "10.0.26200",
  "usagestats": 0
}
''',
      'update_metrics.json': '''
{
  "install_duration_ms": 18432,
  "install_type": "incremental",
  "payload_size_bytes": 52428800,
  "rollback_attempted": false,
  "source": "omaha",
  "update_success": true
}
''',
      'component_updater.log': '''
[0315/115958.412:VERBOSE1:component_updater_service.cc(412)] Checking for component updates
[0315/115958.891:VERBOSE1:component_updater_service.cc(518)] Component widevine ready (current)
[0315/115959.204:VERBOSE1:component_updater_service.cc(518)] Component MEI Preload ready (current)
[0315/115959.447:VERBOSE1:component_updater_service.cc(890)] All components up to date
[0315/120004.118:VERBOSE1:update_client.cc(234)] Update check completed: status=ok version=$currentVersion
''',
      'chrome_update.log': '''
[0315/120001.003:INFO:chrome_updater.cc(891)] Google Chrome update service started
[0315/120001.118:INFO:update_engine.cc(445)] Current version: $currentVersion
[0315/120001.224:INFO:update_engine.cc(512)] No pending update — browser is current
[0315/120004.131:INFO:update_engine.cc(678)] Background update check finished (up to date)
''',
      'recovery_version': '$currentVersion\n',
      'update_policy.json': '''
{
  "auto_update_enabled": true,
  "download_preference": "background",
  "target_version_prefix": "131."
}
''',
    });

    final crxCache = Directory(p.join(storageDir.path, 'component_crx_cache'));
    await crxCache.create(recursive: true);
    await _writeDecoys(crxCache, {
      'metadata.json': '''
{
  "components": {
    "oimompecagnajdejgnnjijobeaeigek": {
      "last_check": "2025-03-15T12:00:00.000Z",
      "status": "up_to_date",
      "version": "1.0.6.166"
    }
  },
  "schema_version": 1
}
''',
      'component_updater_state': 'idle\n',
    });

    final crxDownloads = Directory(p.join(storageDir.path, 'CRX_Downloads'));
    await crxDownloads.create(recursive: true);
    await _writeDecoys(crxDownloads, {
      '.crx_staging_$currentVersion': '',
      'download_manifest.json': '''
{
  "bytes_received": 0,
  "complete": true,
  "package": "chrome_installer",
  "version": "$currentVersion"
}
''',
    });

    final staging = Directory(p.join(storageDir.path, 'UpdateStaging'));
    await staging.create(recursive: true);
    await _writeDecoys(staging, {
      'manifest.json': '''
{
  "arguments": "--do-not-de-elevate --verbose-logging",
  "installer_path": "",
  "operation": "install",
  "package": "chrome",
  "version": "$currentVersion"
}
''',
      'staging_state': 'committed\n',
    });
  }

  static Future<void> _writeDecoys(
    Directory directory,
    Map<String, String> files,
  ) async {
    for (final entry in files.entries) {
      final file = File(p.join(directory.path, entry.key));
      if (!await file.exists()) {
        await file.writeAsString(entry.value);
      }
    }
  }
}
