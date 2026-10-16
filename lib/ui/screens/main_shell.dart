import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/desktop/desktop_overlay_actions.dart';
import '../../core/desktop/desktop_window_controller.dart';
import '../../core/device/device_date_validator.dart';
import '../../core/config/app_currency.dart';
import '../../core/config/app_version.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/l10n/locale_controller.dart';
import '../../data/models/cashier_session.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/cartela_importer.dart';
import '../../data/repositories/game_repository.dart';
import '../layout/responsive_layout.dart';
import '../widgets/app_card.dart';
import '../widgets/app_loading.dart';
import '../widgets/app_logo.dart';
import '../theme/bingo_colors.dart';
import '../widgets/desktop_top_bar.dart';
import '../widgets/device_date_alert.dart';
import '../widgets/deposit_action_buttons.dart';
import '../widgets/deposit_history_dialog.dart';
import '../widgets/manual_deposit_modal.dart';
import '../widgets/package_deposit_modal.dart';
import '../../services/deposit_service.dart';
import 'cartela_management_screen.dart';
import 'help_screen.dart';
import 'game_flow_screen.dart';
import 'report_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({
    super.key,
    required this.session,
    required this.authRepository,
    required this.setupRepository,
    required this.gameRepository,
    required this.cartelaImporter,
    required this.onLoggedOut,
    this.onAccountDeleted,
  });

  final CashierSession session;
  final AuthRepository authRepository;
  final SetupRepository setupRepository;
  final GameRepository gameRepository;
  final CartelaImporter cartelaImporter;
  final VoidCallback onLoggedOut;
  final VoidCallback? onAccountDeleted;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with WidgetsBindingObserver {
  static const _tabSwitchMinLoading = Duration(milliseconds: 280);

  int _index = 1;
  late CashierSession _session = widget.session;
  bool _tabSwitching = false;
  int _tabSwitchToken = 0;
  bool _dateDialogVisible = false;
  bool _playFullscreen = false;
  bool _loggingOut = false;
  final Map<int, int> _tabRefreshTokens = {0: 0, 1: 0, 2: 0, 3: 0};
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _verifyDeviceDate();
    });
  }

  @override
  void dispose() {
    DeviceDateAlertHandle.dismissIfOpen();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _verifyDeviceDate();
    }
  }

  Future<void> _verifyDeviceDate() async {
    if (!mounted || _dateDialogVisible) return;

    final mismatch = await DeviceDateValidator.findMismatch(
      gameRepository: widget.gameRepository,
      cashierId: _session.cashierId,
    );
    if (!mounted || mismatch == null) return;

    _dateDialogVisible = true;
    final s = context.read<LocaleController>().strings;

    await showDeviceDateMismatchAlert(
      context,
      strings: s,
      mismatch: mismatch,
      recheck: () => DeviceDateValidator.findMismatch(
        gameRepository: widget.gameRepository,
        cashierId: _session.cashierId,
      ),
    );

    _dateDialogVisible = false;
  }

  List<({IconData icon, IconData selected, String label})> _destinations(
    BuildContext context,
  ) {
    final s = context.watch<LocaleController>().strings;
    return [
      (icon: Icons.assessment_outlined, selected: Icons.assessment, label: s.navReport),
      (icon: Icons.casino_outlined, selected: Icons.casino, label: s.navPlay),
      (
        icon: Icons.grid_view_outlined,
        selected: Icons.grid_view,
        label: s.navCartelaManagement,
      ),
      (icon: Icons.help_outline, selected: Icons.help, label: s.navHelp),
    ];
  }

  Future<void> _refreshSession() async {
    final profile = await widget.gameRepository.getCashierProfile(
      _session.cashierId,
    );

    if (!mounted) return;

    setState(() {
      _session = CashierSession(
        cashierId: profile.cashierId,

        partnerId: profile.partnerId,

        category: profile.category,

        packageBalance: profile.packageBalance,

        isActive: profile.isActive,
      );
    });
  }

  Future<void> _openManualDepositModal() async {
    await showManualDepositModal(
      context: context,
      cashierId: _session.cashierId,
      partnerId: '${_session.partnerId}',
      packageBalance: _session.packageBalance,
      gameRepository: widget.gameRepository,
      onApplied: () async {
        await _refreshSession();
        if (!mounted) return;
        setState(() {
          _tabRefreshTokens[0] = (_tabRefreshTokens[0] ?? 0) + 1;
        });
      },
    );
  }

  Future<void> _openPackageModal() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => PackageDepositModal(
        cashierId: _session.cashierId,
        depositService: DepositService(),
        gameRepository: widget.gameRepository,
        onApplied: () async {
          await _refreshSession();
          if (!mounted) return;
          setState(() {
            _tabRefreshTokens[0] = (_tabRefreshTokens[0] ?? 0) + 1;
          });
        },
      ),
    );
  }

  Future<void> _openDepositHistory() async {
    await showDepositHistoryDialog(
      context,
      cashierId: _session.cashierId,
      gameRepository: widget.gameRepository,
    );
  }

  Widget _buildMobileReportAppBarActions() {
    return Padding(
      padding: const EdgeInsets.only(right: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 32,
            child: OfflineDepositButton(
              onPressed: _openManualDepositModal,
              tight: true,
            ),
          ),
          const SizedBox(width: 2),
          SizedBox(
            height: 32,
            child: OnlineDepositButton(
              onPressed: _openPackageModal,
              tight: true,
            ),
          ),
          const SizedBox(width: 2),
          SizedBox(
            height: 32,
            child: DepositHistoryButton(
              onPressed: _openDepositHistory,
              tight: true,
            ),
          ),
        ],
      ),
    );
  }

  Widget _pageFor(int index) {
    switch (index) {
      case 0:
        return ReportScreen(
          key: ValueKey(
            'report-${_session.cashierId}-${_tabRefreshTokens[0] ?? 0}',
          ),

          session: _session,

          gameRepository: widget.gameRepository,

          onBalanceChanged: _refreshSession,
          refreshToken: _tabRefreshTokens[0] ?? 0,
          isActive: true,
        );

      case 1:
        return GameFlowScreen(
          key: ValueKey('game-flow-${_tabRefreshTokens[1] ?? 0}'),
          session: _session,
          gameRepository: widget.gameRepository,
          cartelaImporter: widget.cartelaImporter,
          setupRepository: widget.setupRepository,
          onBalanceChanged: _refreshSession,
          onIdentityUpdated: (session) => setState(() => _session = session),
          onOpenReport: () => _selectTab(0),
          onLogout: () async {
            if (context.isDesktop) {
              context.read<DesktopOverlayActions>().clearPlayToolbar();
              context.read<DesktopOverlayActions>().clearRegisterBar();
            }
            await widget.authRepository.logout(_session.cashierId);
            widget.onLoggedOut();
          },
          onPlayFullscreenChanged: (playActive) {
            if (_playFullscreen == playActive) return;
            setState(() => _playFullscreen = playActive);
          },
          refreshToken: _tabRefreshTokens[1] ?? 0,
          isActive: true,
        );

      case 2:
        return CartelaManagementScreen(
          key: ValueKey(
            'cartela-management-${_session.category}-${_tabRefreshTokens[2] ?? 0}',
          ),
          gameRepository: widget.gameRepository,
          activeCategory: _session.category,
          refreshToken: _tabRefreshTokens[2] ?? 0,
          isActive: true,
        );

      case 3:
        return HelpScreen(
          key: ValueKey(
            'help-${_session.cashierId}-${_tabRefreshTokens[3] ?? 0}',
          ),
          refreshToken: _tabRefreshTokens[3] ?? 0,
          isActive: true,
        );

      default:
        return const SizedBox.shrink();
    }
  }

  String _tabLoadingMessage(AppStrings s, int index) {
    switch (index) {
      case 0:
        return s.loadingReport;
      case 1:
        return s.loadingGame;
      default:
        return s.loading;
    }
  }

  Widget _buildCurrentTab() {
    if (_tabSwitching) {
      final s = context.watch<LocaleController>().strings;
      return AppLoadingView(message: _tabLoadingMessage(s, _index));
    }
    return _pageFor(_index);
  }

  Future<void> _confirmLogout() async {
    final s = context.read<LocaleController>().strings;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.logoutConfirmTitle),
        content: Text(s.logoutConfirmBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.logout),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    setState(() => _loggingOut = true);
    try {
      DeviceDateAlertHandle.dismissIfOpen();
      if (context.isDesktop) {
        context.read<DesktopOverlayActions>().clearPlayToolbar();
        context.read<DesktopOverlayActions>().clearRegisterBar();
      }
      await widget.authRepository.logout(_session.cashierId);
      if (!mounted) return;
      widget.onLoggedOut();
    } finally {
      if (mounted) setState(() => _loggingOut = false);
    }
  }

  Widget _buildSideNavFooter(AppStrings s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const Divider(height: 1, color: BingoColors.border),
          const SizedBox(height: 10),
          Text(
            s.appName,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: BingoColors.sideNavText.withValues(alpha: 0.92),
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _versionBadge(),
              const SizedBox(width: 6),
              Flexible(
                child: Text(
                  '${s.loginInfoVersionLabel} ${AppVersion.version}',
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _loggingOut ? null : _confirmLogout,
              style: OutlinedButton.styleFrom(
                foregroundColor: BingoColors.lastCalled,
                side: BorderSide(
                  color: BingoColors.lastCalled.withValues(alpha: 0.75),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                visualDensity: VisualDensity.compact,
              ),
              icon: _loggingOut
                  ? const AppButtonLoader(
                      color: BingoColors.lastCalled,
                      size: 16,
                    )
                  : const Icon(Icons.logout, size: 18),
              label: Text(
                s.logout,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _versionBadge({double size = 22, double fontSize = 11}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: BingoColors.primary.withValues(alpha: 0.14),
        border: Border.all(
          color: BingoColors.sideNavText.withValues(alpha: 0.35),
        ),
      ),
      child: Center(
        child: Text(
          'V',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w900,
            color: BingoColors.sideNavText.withValues(alpha: 0.88),
            height: 1,
          ),
        ),
      ),
    );
  }

  void _selectTab(int i) {
    if (i == _index && !_tabSwitching) return;

    if (context.isDesktop && i != 1) {
      context.read<DesktopOverlayActions>().clearPlayToolbar();
      context.read<DesktopOverlayActions>().clearRegisterBar();
    }
    if (_index == 1 && i != 1) {
      _playFullscreen = false;
    }

    final switchToken = ++_tabSwitchToken;

    setState(() {
      _tabSwitching = true;
      _index = i;
      _tabRefreshTokens[i] = (_tabRefreshTokens[i] ?? 0) + 1;
    });

    unawaited(_finishTabSwitch(switchToken));
  }

  Future<void> _finishTabSwitch(int switchToken) async {
    await Future<void>.delayed(_tabSwitchMinLoading);
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted || _tabSwitchToken != switchToken) return;
    setState(() => _tabSwitching = false);
  }

  void _openDrawer() {
    _scaffoldKey.currentState?.openDrawer();
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = context.isDesktop;
    final destinations = _destinations(context);
    final hidePlayChrome = isDesktop && _index == 1 && _playFullscreen;
    final fullScreen = DesktopWindowController.isSupported &&
        context.watch<DesktopWindowController>().isFullScreen;

    return GradientBackground(
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor: Colors.transparent,
        drawer: _buildAppDrawer(destinations),
        appBar: isDesktop || (_index == 1 && _playFullscreen)
            ? null
            : AppBar(
                backgroundColor: BingoColors.sideNavBg,
                foregroundColor: BingoColors.sideNavText,
                elevation: 0,
                toolbarHeight: 44,
                leading: IconButton(
                  icon: const Icon(Icons.menu),
                  tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
                  onPressed: _openDrawer,
                ),
                title: Text(
                  destinations[_index].label,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                actions: [
                  if (_index == 0) _buildMobileReportAppBarActions(),
                ],
              ),
        body: SafeArea(
          top: !(isDesktop && fullScreen) && !hidePlayChrome,
          bottom: false,
          child: isDesktop
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (!hidePlayChrome)
                      DesktopTopBar(onMenuPressed: _openDrawer),
                    Expanded(child: _buildCurrentTab()),
                  ],
                )
              : _buildCurrentTab(),
        ),
      ),
    );
  }

  Widget _buildAppDrawer(
    List<({IconData icon, IconData selected, String label})> destinations,
  ) {
    final s = context.watch<LocaleController>().strings;
    return Drawer(
      backgroundColor: BingoColors.sideNavBg,
      width: 300,
      child: SafeArea(
        child: _buildNavigationMenu(
          s: s,
          destinations: destinations,
          onItemTap: () => Navigator.of(context).pop(),
        ),
      ),
    );
  }

  Widget _buildNavigationMenu({
    required AppStrings s,
    required List<({IconData icon, IconData selected, String label})>
        destinations,
    VoidCallback? onItemTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildFullProfileHeader(s),
        const Divider(height: 1, color: BingoColors.border),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 8),
            children: List.generate(destinations.length, (i) {
              final d = destinations[i];
              final selected = _index == i;
              return ListTile(
                leading: Icon(
                  selected ? d.selected : d.icon,
                  color: selected ? Colors.white : BingoColors.sideNavText,
                  size: 22,
                ),
                title: Text(
                  d.label,
                  style: TextStyle(
                    color: selected ? Colors.white : BingoColors.sideNavText,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 15,
                  ),
                ),
                selected: selected,
                selectedTileColor: BingoColors.sideNavSelected,
                onTap: () {
                  onItemTap?.call();
                  _selectTab(i);
                },
              );
            }),
          ),
        ),
        _buildSideNavFooter(s),
      ],
    );
  }

  BoxDecoration _navProfileDecoration() {
    return BoxDecoration(
      color: BingoColors.primary.withValues(alpha: 0.12),
      border: Border(
        bottom: BorderSide(
          color: BingoColors.border.withValues(alpha: 0.45),
        ),
      ),
    );
  }

  BoxDecoration _navLogoDecoration() {
    return BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: BingoColors.gold, width: 2),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.18),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
    );
  }

  Widget _profileDetailsColumn(AppStrings s) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.cashierId,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: BingoColors.sideNavText.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          _session.cashierId,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.red,
            fontWeight: FontWeight.w800,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          s.remainingPackage,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: BingoColors.sideNavText.withValues(alpha: 0.75),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          s.remainingPackageAmount(
            _session.packageBalance,
            AppCurrency.defaultCode,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: BingoColors.gold,
            fontWeight: FontWeight.w800,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildFullProfileHeader(AppStrings s) {
    return Container(
      width: double.infinity,
      clipBehavior: Clip.hardEdge,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: _navProfileDecoration(),
      child: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth < 120) {
            return const SizedBox.shrink();
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: _navLogoDecoration(),
                child: const AppLogo(size: 68, circular: true, padding: 4),
              ),
              const SizedBox(width: 14),
              Expanded(child: _profileDetailsColumn(s)),
            ],
          );
        },
      ),
    );
  }
}
