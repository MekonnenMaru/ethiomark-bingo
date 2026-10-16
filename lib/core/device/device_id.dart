import 'dart:async';
import 'dart:io';

import 'package:device_info_plus/device_info_plus.dart';

import '../bootstrap/bootstrap_cache.dart';

/// Device identifier used for package encryption (replaces BIOS serial on desktop).
class DeviceId {
  static String? _cached;
  static const _readTimeout = Duration(seconds: 10);

  static Future<String> getSerial() async {
    if (_cached != null) return _cached!;

    final stored = await BootstrapCache.cachedDeviceSerial();
    if (stored != null && stored.isNotEmpty) {
      _cached = stored;
      return stored;
    }

    try {
      _cached = await _readPlatformSerial().timeout(_readTimeout);
    } catch (_) {
      _cached = _localFallbackId();
    }

    if (_cached == null || _cached!.isEmpty) {
      _cached = _localFallbackId();
    }
    await BootstrapCache.cacheDeviceSerial(_cached!);
    return _cached!;
  }

  static Future<String> _readPlatformSerial() async {
    final plugin = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final info = await plugin.androidInfo;
      return info.id;
    } else if (Platform.isWindows) {
      final info = await plugin.windowsInfo;
      return info.deviceId;
    } else if (Platform.isMacOS) {
      final info = await plugin.macOsInfo;
      return info.systemGUID ?? info.computerName;
    } else if (Platform.isLinux) {
      final info = await plugin.linuxInfo;
      return info.machineId ?? info.name;
    }
    return 'DEVICE-UNKNOWN';
  }

  static String _localFallbackId() {
    final host = Platform.localHostname.trim();
    if (host.isNotEmpty) {
      return 'DEVICE-LOCAL-$host';
    }
    return 'DEVICE-FALLBACK';
  }
}
