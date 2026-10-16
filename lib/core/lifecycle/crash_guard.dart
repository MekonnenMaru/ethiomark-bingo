import 'dart:io';

import 'package:flutter/foundation.dart';

import '../config/app_version.dart';

/// Installs error handlers that log under the Desktop app folder and keep the
/// cashier window alive. Release builds used to call [exit] on every
/// FlutterError, which looked like a white flash then a dead app on weak PCs.
void installCrashGuard() {
  if (kIsWeb) return;

  FlutterError.onError = (details) {
    FlutterError.dumpErrorToConsole(details);
    appendAppLog(
      'FlutterError: ${details.exceptionAsString()}\n${details.stack}',
    );
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    appendAppLog('async error (non-fatal): $error\n$stack');
    if (kDebugMode) {
      debugPrint('Unhandled async error: $error\n$stack');
    }
    return true;
  };
}

/// Appends a line to
/// `Desktop/<AppVersion.name>/ethiomark-crash-YYYY-MM-DD.log`.
void appendAppLog(String message) {
  try {
    final dir = _desktopAppLogDirectory();
    if (dir == null) return;
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }
    final now = DateTime.now();
    final stamp =
        '${now.year.toString().padLeft(4, '0')}-'
        '${now.month.toString().padLeft(2, '0')}-'
        '${now.day.toString().padLeft(2, '0')}';
    final file = File(
      '${dir.path}${Platform.pathSeparator}ethiomark-crash-$stamp.log',
    );
    file.writeAsStringSync(
      '${now.toIso8601String()} $message\n',
      mode: FileMode.append,
      flush: true,
    );
  } catch (_) {}
}

Directory? _desktopAppLogDirectory() {
  final desktop = _desktopDirectory();
  if (desktop == null) return null;
  return Directory(
    '${desktop.path}${Platform.pathSeparator}${AppVersion.name}',
  );
}

Directory? _desktopDirectory() {
  if (Platform.isWindows) {
    final profile = Platform.environment['USERPROFILE'];
    if (profile == null || profile.isEmpty) return null;
    return Directory('$profile${Platform.pathSeparator}Desktop');
  }
  final home = Platform.environment['HOME'];
  if (home == null || home.isEmpty) return null;
  return Directory('$home${Platform.pathSeparator}Desktop');
}
