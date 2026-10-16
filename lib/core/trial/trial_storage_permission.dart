import 'dart:io';

import 'package:flutter/services.dart';

/// Storage permission for the device-wide trial ledger (native Android only).
abstract final class TrialStoragePermission {
  TrialStoragePermission._();

  static const _channel = MethodChannel('com.ethiomark.bingo_apk/trial_ledger');

  static Future<bool> isGranted() async {
    if (!Platform.isAndroid) return true;
    try {
      final ok = await _channel.invokeMethod<bool>('hasStorageAccess');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Opens the system permission screen when needed.
  static Future<bool> ensureGranted() async {
    if (!Platform.isAndroid) return true;
    try {
      final ok = await _channel.invokeMethod<bool>('requestStorageAccess');
      return ok ?? false;
    } catch (_) {
      return false;
    }
  }
}
