import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/app_version.dart';
import 'core/config/login_prefs.dart';
import 'core/bootstrap/bootstrap_cache.dart';
import 'core/bootstrap/cartela_load_service.dart';
import 'core/desktop/desktop_overlay_actions.dart';
import 'core/device/device_binding.dart';
import 'core/l10n/locale_controller.dart';
import 'data/database/app_database.dart';
import 'data/models/cashier_session.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/cartela_importer.dart';
import 'data/repositories/game_repository.dart';
import 'ui/screens/login_screen.dart';
import 'ui/screens/main_shell.dart';
import 'ui/screens/setup_screen.dart';
import 'ui/theme/app_theme.dart';
import 'ui/widgets/app_loading.dart';
import 'ui/widgets/app_logo.dart';
import 'ui/widgets/desktop_fullscreen_overlay.dart';
import 'ui/widgets/page_zoom_host.dart';

enum AppRoute { bootstrap, setup, login, home }

enum _BootstrapPhase { preparing, error }

class BingoApp extends StatefulWidget {
  const BingoApp({super.key});

  @override
  State<BingoApp> createState() => _BingoAppState();
}

class _BingoAppState extends State<BingoApp> {
  final _db = AppDatabase.instance;
  late final AuthRepository _authRepository = AuthRepository(_db);
  late final SetupRepository _setupRepository = SetupRepository(_db);
  late final GameRepository _gameRepository = GameRepository(_db);
  late final CartelaImporter _cartelaImporter = CartelaImporter(_db);

  AppRoute _route = AppRoute.bootstrap;
  CashierSession? _session;
  _BootstrapPhase _bootstrapPhase = _BootstrapPhase.preparing;
  String? _bootstrapError;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      await _db.database;
      final cashierCount = await _db.countCashiers();

      if (await BootstrapCache.isCartelasReady()) {
        CartelaLoadService.instance.markReady();
      } else {
        unawaited(
          CartelaLoadService.instance
              .ensureLoaded(_cartelaImporter)
              .catchError((Object e, StackTrace st) {
            debugPrint('Background cartela load failed: $e\n$st');
          }),
        );
      }

      if (!mounted) return;

      setState(() {
        _route = cashierCount == 0 ? AppRoute.setup : AppRoute.login;
      });
    } on DeviceBindingException {
      if (!mounted) return;
      final s = context.read<LocaleController>().strings;
      setState(() {
        _bootstrapPhase = _BootstrapPhase.error;
        _bootstrapError = s.databaseDeviceMismatch;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _bootstrapPhase = _BootstrapPhase.error;
        _bootstrapError = '$e';
      });
    }
  }

  void _clearDesktopOverlay() {
    if (!mounted) return;
    final actions = context.read<DesktopOverlayActions>();
    actions.clearPlayToolbar();
    actions.clearRegisterBar();
    actions.clearRefresh();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      actions.clearPlayToolbar();
      actions.clearRegisterBar();
      actions.clearRefresh();
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        actions.clearPlayToolbar();
        actions.clearRegisterBar();
        actions.clearRefresh();
      });
    });
  }

  void _onLoggedIn(CashierSession session) {
    setState(() {
      _session = session;
      _route = AppRoute.home;
    });
  }

  void _onLoggedOut() {
    _clearDesktopOverlay();
    setState(() {
      _session = null;
      _route = AppRoute.login;
    });
  }

  void _onAccountDeleted() {
    _clearDesktopOverlay();
    setState(() {
      _session = null;
      _route = AppRoute.setup;
    });
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.watch<LocaleController>();
    return MaterialApp(
      title: locale.strings.appVersion(AppVersion.version),
      debugShowCheckedModeBanner: false,
      theme: AppTheme.dark(),
      builder: (context, child) {
        return PageZoomHost(child: child ?? const SizedBox.shrink());
      },
      home: DesktopFullscreenOverlay(
        child: _buildScreen(context),
      ),
    );
  }

  Widget _buildScreen(BuildContext context) {
    final s = context.watch<LocaleController>().strings;
    switch (_route) {
      case AppRoute.bootstrap:
        final bootstrapMessage = switch (_bootstrapPhase) {
          _BootstrapPhase.preparing => s.preparingDatabase,
          _BootstrapPhase.error => s.startupError(_bootstrapError ?? ''),
        };
        return Scaffold(
          backgroundColor: const Color(0xFF0C474E),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      AppLogo(size: 100),
                      const SizedBox(height: 24),
                      Text(
                        s.appVersion(AppVersion.version),
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 20),
                      const AppLoadingIndicator(color: Color(0xFFFF9800)),
                      const SizedBox(height: 20),
                      Text(
                        bootstrapMessage,
                        textAlign: TextAlign.center,
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      case AppRoute.setup:
        return SetupScreen(
          setupRepository: _setupRepository,
          onComplete: () async {
            final saved = await LoginPrefs.load();
            if (saved.cashierId != null && saved.password != null) {
              final session = await _authRepository.login(
                saved.cashierId!,
                saved.password!,
              );
              if (!mounted) return;
              if (session != null) {
                _onLoggedIn(session);
                return;
              }
            }
            if (mounted) setState(() => _route = AppRoute.login);
          },
        );
      case AppRoute.login:
        return LoginScreen(
          authRepository: _authRepository,
          onLoggedIn: _onLoggedIn,
        );
      case AppRoute.home:
        final session = _session;
        if (session == null) {
          return LoginScreen(
            authRepository: _authRepository,
            onLoggedIn: _onLoggedIn,
          );
        }
        return MainShell(
          session: session,
          authRepository: _authRepository,
          setupRepository: _setupRepository,
          gameRepository: _gameRepository,
          cartelaImporter: _cartelaImporter,
          onLoggedOut: _onLoggedOut,
          onAccountDeleted: _onAccountDeleted,
        );
    }
  }
}
