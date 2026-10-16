import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:screen_retriever/screen_retriever.dart';
import 'package:window_manager/window_manager.dart';

import '../config/app_version.dart';

/// Desktop window controls (full-screen, size) via [window_manager].
class DesktopWindowController extends ChangeNotifier {
  bool _isFullScreen = false;
  bool _busy = false;

  bool get isFullScreen => _isFullScreen;

  static bool get isSupported =>
      !kIsWeb &&
      (Platform.isWindows || Platform.isLinux || Platform.isMacOS);

  Future<void> _syncFullScreenState() async {
    _isFullScreen = await windowManager.isFullScreen();
  }

  Future<void> _applyFullScreen(bool enabled) async {
    await windowManager.setFullScreen(enabled);

    if (!Platform.isWindows) {
      await windowManager.setTitleBarStyle(
        enabled ? TitleBarStyle.hidden : TitleBarStyle.normal,
      );
    }

    await _syncFullScreenState();
  }

  Future<Rect> _primaryWorkArea() async {
    final display = await screenRetriever.getPrimaryDisplay();
    final size = display.visibleSize ?? display.size;
    final origin = display.visiblePosition ?? Offset.zero;
    return Rect.fromLTWH(
      origin.dx,
      origin.dy,
      size.width.toDouble(),
      size.height.toDouble(),
    );
  }

  Future<void> initialize() async {
    if (!isSupported) return;

    await windowManager.ensureInitialized();

    var workArea = await _primaryWorkArea();
    // Guard against broken display metrics that yield a 0-size Flutter surface
    // (white client area with only the title bar visible).
    if (workArea.width < 800 || workArea.height < 500) {
      workArea = const Rect.fromLTWH(40, 40, 1100, 640);
    }

    final windowOptions = WindowOptions(
      size: Size(
        workArea.width.clamp(800, 4096),
        workArea.height.clamp(500, 4096),
      ),
      backgroundColor: const Color(0xFF0C474E),
      title: '${AppVersion.name} v${AppVersion.version}',
    );

    await windowManager.waitUntilReadyToShow(windowOptions);
    await windowManager.setBounds(workArea);
    await windowManager.show();
    await windowManager.focus();
    _isFullScreen = false;
  }

  Future<void> toggleFullScreen() async {
    if (!isSupported || _busy) return;

    _busy = true;
    try {
      final next = !(await windowManager.isFullScreen());
      await _applyFullScreen(next);
      notifyListeners();
    } finally {
      _busy = false;
    }
  }

  Future<void> setFullScreen(bool enabled) async {
    if (!isSupported || _busy) return;

    final current = await windowManager.isFullScreen();
    if (current == enabled) {
      _isFullScreen = current;
      return;
    }

    _busy = true;
    try {
      await _applyFullScreen(enabled);
      notifyListeners();
    } finally {
      _busy = false;
    }
  }
}

class ToggleFullScreenIntent extends Intent {
  const ToggleFullScreenIntent();
}

class ExitFullScreenIntent extends Intent {
  const ExitFullScreenIntent();
}
