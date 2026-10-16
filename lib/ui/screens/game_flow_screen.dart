import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/bootstrap/cartela_load_service.dart';
import '../../core/desktop/desktop_overlay_actions.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/performance/managed_loader.dart';
import '../../core/performance/resource_budget.dart';
import '../../data/models/cashier_session.dart';
import '../../data/models/game_round.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/cartela_importer.dart';
import '../../data/repositories/game_repository.dart';
import '../layout/responsive_layout.dart';
import '../widgets/app_loading.dart';
import '../widgets/app_toast.dart';
import 'play_bingo_screen.dart';
import 'register_game_screen.dart';

/// Single Play tab: register cards when needed, otherwise show the play screen.
class GameFlowScreen extends StatefulWidget {
  const GameFlowScreen({
    super.key,
    required this.session,
    required this.gameRepository,
    required this.cartelaImporter,
    required this.onBalanceChanged,
    this.setupRepository,
    this.onIdentityUpdated,
    this.onOpenReport,
    this.onLogout,
    this.onPlayFullscreenChanged,
    this.refreshToken = 0,
    this.isActive = true,
  });

  final CashierSession session;
  final GameRepository gameRepository;
  final CartelaImporter cartelaImporter;
  final Future<void> Function() onBalanceChanged;
  final SetupRepository? setupRepository;
  final void Function(CashierSession session)? onIdentityUpdated;
  final VoidCallback? onOpenReport;
  final Future<void> Function()? onLogout;
  /// `true` when the active play screen is shown (hide shell chrome on desktop).
  final ValueChanged<bool>? onPlayFullscreenChanged;
  final int refreshToken;
  final bool isActive;

  @override
  State<GameFlowScreen> createState() => _GameFlowScreenState();
}

class _GameFlowScreenState extends State<GameFlowScreen> {
  bool _loading = true;
  bool _showRegister = true;
  int _flowKey = 0;
  String? _error;
  bool _toolbarClearScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _resolve(showLoadingOverlay: false);
      _notifyPlayFullscreen();
    });
  }

  @override
  void didUpdateWidget(covariant GameFlowScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _notifyPlayFullscreen();
    }
    if (oldWidget.isActive && !widget.isActive) {
      _scheduleClearPlayToolbarIfNeeded(false);
    }
    if (!oldWidget.isActive && widget.isActive) {
      _scheduleClearPlayToolbarIfNeeded(
        !_loading && _error == null && !_showRegister,
      );
    }
    if (widget.isActive &&
        oldWidget.refreshToken != widget.refreshToken) {
      final token = widget.refreshToken;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || widget.refreshToken != token) return;
        _reloadFromTab();
      });
    }
  }

  Future<void> _reloadFromTab() async {
    await widget.onBalanceChanged();
    if (!mounted) return;
    if (_showRegister) {
      await _resolve(keepRegisterIfIncomplete: true);
    }
  }

  void _notifyPlayFullscreen() {
    if (!widget.isActive || !mounted) return;
  final hideShellChrome = context.isDesktop
      ? (!_loading && !_showRegister && _error == null)
      : (!_loading && _error == null);
    widget.onPlayFullscreenChanged?.call(hideShellChrome);
  }

  Future<void> _resolve({
    bool forceRegister = false,
    bool keepRegisterIfIncomplete = false,
    bool showLoadingOverlay = true,
  }) async {
    final wasShowingPlay = !_loading && !_showRegister && _error == null;

    if (mounted) {
      setState(() {
        if (showLoadingOverlay) _loading = true;
        _error = null;
      });
      if (showLoadingOverlay) _notifyPlayFullscreen();
    }

    try {
      await context.read<CartelaLoadService>().ensureLoaded(widget.cartelaImporter);

      late final GameRound? incomplete;
      late final GameRound? active;
      if (ResourceBudget.sequentialScreenLoads) {
        final results = await ManagedLoader.runSequential<GameRound?>([
          () => widget.gameRepository.getIncompleteGame(widget.session.cashierId),
          () => widget.gameRepository.getActivePlayGame(widget.session.cashierId),
        ]);
        incomplete = results[0];
        active = results[1];
      } else {
        final results = await Future.wait<GameRound?>([
          widget.gameRepository.getIncompleteGame(widget.session.cashierId),
          widget.gameRepository.getActivePlayGame(widget.session.cashierId),
        ]);
        incomplete = results[0];
        active = results[1];
      }

      if (!mounted) return;
      final showRegister = forceRegister ||
          (keepRegisterIfIncomplete && incomplete != null) ||
          active == null;
      setState(() {
        _showRegister = showRegister;
        _loading = false;
        _flowKey++;
      });
      if (wasShowingPlay && showRegister) {
        _scheduleClearPlayToolbarIfNeeded(false);
      }
      _scheduleClearRegisterBarIfNeeded(showRegister);
      _notifyPlayFullscreen();
    } catch (e) {
      if (!mounted) return;
      final s = context.read<LocaleController>().strings;
      setState(() {
        _loading = false;
        _error = s.couldNotLoadGame('$e');
        _showRegister = true;
      });
      _notifyPlayFullscreen();
    }
  }

  void _clearPlayToolbarIfDesktop() {
    if (!context.isDesktop) return;
    context.read<DesktopOverlayActions>().clearPlayToolbar();
  }

  void _clearRegisterBarIfDesktop() {
    if (!context.isDesktop) return;
    context.read<DesktopOverlayActions>().clearRegisterBar();
  }

  void _scheduleClearPlayToolbarIfNeeded(bool showingPlayBingo) {
    if (!context.isDesktop || showingPlayBingo) return;
    if (_toolbarClearScheduled) return;
    _toolbarClearScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _toolbarClearScheduled = false;
      if (!mounted) return;
      _clearPlayToolbarIfDesktop();
    });
  }

  void _scheduleClearRegisterBarIfNeeded(bool showingRegister) {
    if (!context.isDesktop || showingRegister) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _clearRegisterBarIfDesktop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().strings;

    if (_loading) {
      final loader = context.watch<CartelaLoadService>();
      final message = loader.isLoading && loader.total > 0
          ? s.loadingCartelasProgress(loader.current, loader.total)
          : s.loadingGame;
      return AppLoadingView(message: message);
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: () => _resolve(),
                child: Text(s.retry),
              ),
            ],
          ),
        ),
      );
    }

    if (_showRegister) {
      return RegisterGameScreen(
        key: ValueKey('register-$_flowKey'),
        session: widget.session,
        gameRepository: widget.gameRepository,
        setupRepository: widget.setupRepository,
        cartelaImporter: widget.cartelaImporter,
        onBalanceChanged: widget.onBalanceChanged,
        onIdentityUpdated: widget.onIdentityUpdated,
        onRegistered: () => _resolve(),
        onOpenReport: widget.onOpenReport,
      );
    }

    return PlayBingoScreen(
      key: ValueKey('play-$_flowKey'),
      session: widget.session,
      gameRepository: widget.gameRepository,
      setupRepository: widget.setupRepository,
      cartelaImporter: widget.cartelaImporter,
      isActive: widget.isActive,
      onBalanceChanged: widget.onBalanceChanged,
      onIdentityUpdated: widget.onIdentityUpdated,
      onFinished: () => _resolve(),
      onOpenReport: widget.onOpenReport,
      onLogout: widget.onLogout,
      onEditRegistration: () async {
        final game = await widget.gameRepository.getActivePlayGame(
          widget.session.cashierId,
        );
        if (!mounted) return;
        if (game != null &&
            await widget.gameRepository.hasTransactionForRound(
              widget.session.cashierId,
              game.roundNumber,
            )) {
          if (!context.mounted) return;
          showAppToast(
            context,
            s.roundAlreadyStarted,
            type: AppToastType.warning,
          );
          return;
        }
        _resolve(forceRegister: true);
      },
    );
  }
}
