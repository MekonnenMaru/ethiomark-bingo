import 'package:shared_preferences/shared_preferences.dart';

/// Fast-path flags so repeat launches skip heavy startup work.
abstract final class BootstrapCache {
  static const _cartelasReadyKey = 'bootstrap_cartelas_ready_v1';
  static const _cartelaCountKey = 'bootstrap_cartela_count_v1';
  static const _decoysReadyKey = 'bootstrap_decoys_ready_v1';
  static const _deviceSerialKey = 'cached_device_serial_v1';

  static Future<bool> isCartelasReady() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_cartelasReadyKey) ?? false;
  }

  static Future<int?> cachedCartelaCount() async {
    final prefs = await SharedPreferences.getInstance();
    if (!(prefs.getBool(_cartelasReadyKey) ?? false)) return null;
    return prefs.getInt(_cartelaCountKey);
  }

  static Future<void> markCartelasReady(int count) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_cartelasReadyKey, true);
    await prefs.setInt(_cartelaCountKey, count);
  }

  static Future<bool> areDecoysReady() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_decoysReadyKey) ?? false;
  }

  static Future<void> markDecoysReady() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_decoysReadyKey, true);
  }

  static Future<String?> cachedDeviceSerial() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_deviceSerialKey);
  }

  static Future<void> cacheDeviceSerial(String serial) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_deviceSerialKey, serial);
  }
}
