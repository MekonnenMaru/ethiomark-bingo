import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'app.dart';
import 'core/auth/auth_info_controller.dart';
import 'core/bootstrap/cartela_load_service.dart';
import 'core/database/desktop_sqlite_init.dart';
import 'core/desktop/desktop_overlay_actions.dart';
import 'core/desktop/desktop_window_controller.dart';
import 'core/desktop/page_zoom_controller.dart';
import 'core/lifecycle/crash_guard.dart';
import 'core/l10n/locale_controller.dart';
import 'core/performance/resource_budget.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  ResourceBudget.applyImageCacheLimits();
  installCrashGuard();

  if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
    desktopSqliteFfiInit();
    databaseFactory = createDatabaseFactoryFfi(
      ffiInit: desktopSqliteFfiInit,
      noIsolate: true,
    );
  }

  final localeController = LocaleController();
  final authInfoController = AuthInfoController();
  final pageZoomController = PageZoomController();
  final desktopWindowController = DesktopWindowController();
  final desktopOverlayActions = DesktopOverlayActions();

  // Paint the first frame immediately. Waiting on prefs/network before runApp
  // leaves a white Win32 client area with only the title bar on some PCs.
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: localeController),
        ChangeNotifierProvider.value(value: pageZoomController),
        ChangeNotifierProvider.value(value: desktopWindowController),
        ChangeNotifierProvider.value(value: authInfoController),
        ChangeNotifierProvider.value(value: CartelaLoadService.instance),
        ChangeNotifierProvider.value(value: desktopOverlayActions),
      ],
      child: const BingoApp(),
    ),
  );

  unawaited(_loadStartupPrefs(
    localeController: localeController,
    authInfoController: authInfoController,
    pageZoomController: pageZoomController,
  ));

  if (DesktopWindowController.isSupported) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      desktopWindowController.initialize().catchError((Object e, StackTrace st) {
        debugPrint('Desktop window init failed: $e\n$st');
      });
    });
  }
}

Future<void> _loadStartupPrefs({
  required LocaleController localeController,
  required AuthInfoController authInfoController,
  required PageZoomController pageZoomController,
}) async {
  try {
    await Future.wait([
      localeController.load(),
      authInfoController.loadCached(),
      pageZoomController.load(),
    ]).timeout(const Duration(seconds: 4));
  } catch (e, st) {
    debugPrint('Startup prefs load failed/timed out: $e\n$st');
  }

  unawaited(
    authInfoController.refreshIfOnline().catchError((Object e, StackTrace st) {
      debugPrint('Auth info refresh failed: $e\n$st');
    }),
  );
}
