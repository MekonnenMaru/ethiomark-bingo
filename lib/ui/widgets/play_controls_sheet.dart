import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/cashier_defaults.dart';
import '../../core/config/app_currency.dart';
import '../../core/bingo/bingo_claim_mode.dart';
import '../../core/bingo/player_bonus.dart';
import '../../core/l10n/app_language.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/ui/modal_guard.dart';
import '../../data/models/cashier_profile.dart';
import '../../data/models/cashier_session.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/cartela_importer.dart';
import '../../data/repositories/game_repository.dart';
import '../layout/responsive_layout.dart';
import '../theme/bingo_colors.dart';
import 'app_loading.dart';
import 'app_toast.dart';
import 'desktop_play_toolbar_controls.dart';
import 'play_setup_panel.dart';

/// House profit % options — matches ethiomark `settings_cashier_profit`.
const kHouseProfitOptions = <int>[
  0,
  10,
  12,
  15,
  17,
  20,
  23,
  25,
  27,
  30,
  33,
  35,
  37,
  40,
];


/// Instant-bingo late-claim rules (maraki / ethiomark claim systems).
const kBingoClaimModeOptions = BingoClaimMode.settingsOptions;

const _settingsDialogRadius = 18.0;
const _settingsButtonRadius = 12.0;

class PlayControlsSheet extends StatefulWidget {
  const PlayControlsSheet({
    super.key,
    required this.cashierId,
    required this.gameRepository,
    required this.settings,
    required this.goodBingoSound,
    required this.cashierProfit,
    required this.bingoClaimMode,
    required this.initialLanguage,
    required this.initialCurrency,
    this.houseCutLocked = false,
    this.embedded = false,
    this.session,
    this.setupRepository,
    this.cartelaImporter,
    this.onBalanceChanged,
    this.onIdentityUpdated,
  });

  final String cashierId;
  final GameRepository gameRepository;
  final Map<String, dynamic> settings;
  final int goodBingoSound;
  final int cashierProfit;
  final BingoClaimMode bingoClaimMode;
  final AppLanguage initialLanguage;
  final String initialCurrency;
  final bool houseCutLocked;
  final bool embedded;
  final CashierSession? session;
  final SetupRepository? setupRepository;
  final CartelaImporter? cartelaImporter;
  final Future<void> Function()? onBalanceChanged;
  final void Function(CashierSession session)? onIdentityUpdated;

  bool get hasSetupPanel =>
      session != null &&
      setupRepository != null &&
      cartelaImporter != null &&
      onBalanceChanged != null;

  @override
  State<PlayControlsSheet> createState() => _PlayControlsSheetState();
}

class _PlayControlsSheetState extends State<PlayControlsSheet>
    with SingleTickerProviderStateMixin {
  final _setupPanelKey = GlobalKey<PlaySetupPanelState>();
  late Map<String, dynamic> _settings;
  late PlayerBonusRound _bonusRound;
  late int _bonusCount;
  late int _bonusPerDay;
  late int _bonusAmount;
  late int _bonusMinBet;
  late int _goodSound;
  late int _profit;
  late BingoClaimMode _bingoClaimMode;
  late bool _willStartSound;
  late bool _startedSound;
  late bool _stoppedSound;
  late bool _showCardCount;
  late bool _showPatternOnStart; // settings: show pattern beside Derash on play
  late AppLanguage _language;
  late String _currency;
  late bool _allowIncomeRounding;
  late String _category;
  List<String> _categories = const [];
  int _savedProfit = 0;
  BingoClaimMode _savedBingoClaimMode = BingoClaimMode.noRestriction;
  bool _savedIncomeRounding = false;
  String _savedCategory = 'default';
  bool _saving = false;
  TabController? _tabController;

  static bool _readShowPatternOnPlay(Map<String, dynamic> toggles) {
    if (toggles.containsKey('show_pattern_on_play')) {
      return toggles['show_pattern_on_play'] == true;
    }
    if (toggles.containsKey('show_pattern_on_start')) {
      return toggles['show_pattern_on_start'] == true;
    }
    return true;
  }

  int get _tabCount => 2;

  bool get _useTabs => _tabCount > 1;

  @override
  void initState() {
    super.initState();
    _settings = Map<String, dynamic>.from(widget.settings);
    _goodSound = widget.goodBingoSound;
    _profit = widget.cashierProfit;
    _bingoClaimMode = widget.bingoClaimMode;
    final bonus = PlayerBonusSettings.fromSettings(widget.settings);
    final toggles = widget.settings['toggles'] as Map<String, dynamic>? ?? {};
    final system = widget.settings['system'] as Map<String, dynamic>? ?? {};
    _bonusRound = bonus.round;
    _bonusCount = bonus.count;
    _bonusPerDay = bonus.perDay;
    _bonusAmount = PlayerBonusLimits.clampAmount(bonus.amount);
    _bonusMinBet = PlayerBonusLimits.clampMinBet(bonus.minBet);
    _willStartSound = toggles['will_start'] != false;
    _startedSound = toggles['started'] != false;
    _stoppedSound = toggles['stopped'] != false;
    _showCardCount = toggles['show_card_count'] != false;
    _showPatternOnStart = _readShowPatternOnPlay(toggles);
    _language = widget.initialLanguage;
    _currency = AppCurrency.normalize(widget.initialCurrency);
    _allowIncomeRounding = system['income_rounding'] == 'on';
    _category = (widget.session?.category.trim().isNotEmpty ?? false)
        ? widget.session!.category.trim()
        : 'default';
    _savedCategory = _category;
    _tabController = TabController(length: _tabCount, vsync: this);
    _refreshFromProfile();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    try {
      final cats = await widget.gameRepository.listCartelaCategories();
      if (!mounted) return;
      setState(() {
        final merged = <String>{
          'default',
          _category,
          ...cats.map((c) => c.trim()).where((c) => c.isNotEmpty),
        }.toList()
          ..sort();
        _categories = merged;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _categories = <String>{
          'default',
          _category,
        }.toList()
          ..sort();
      });
    }
  }

  Future<void> _refreshFromProfile() async {
    try {
      final profile =
          await widget.gameRepository.getCashierProfile(widget.cashierId);
      if (!mounted) return;
      _applyProfile(profile);
    } catch (_) {
      // Keep widget-passed values if profile read fails.
    }
  }

  void _applyProfile(CashierProfile profile) {
    final system = profile.settings['system'] as Map<String, dynamic>? ?? {};
    final bonus = PlayerBonusSettings.fromSettings(profile.settings);
    final toggles = profile.settings['toggles'] as Map<String, dynamic>? ?? {};
    setState(() {
      _settings = Map<String, dynamic>.from(profile.settings);
      _goodSound =
          int.tryParse('${system['good_bingo_sound']}') ??
          CashierDefaults.goodBingoSound;
      _profit = profile.cashierProfit;
      _bingoClaimMode = BingoClaimMode.fromSettings(system);
      _willStartSound = toggles['will_start'] != false;
      _startedSound = toggles['started'] != false;
      _stoppedSound = toggles['stopped'] != false;
      _showCardCount = toggles['show_card_count'] != false;
      _showPatternOnStart = _readShowPatternOnPlay(toggles);
      _bonusRound = bonus.round;
      _bonusCount = bonus.count;
      _bonusPerDay = bonus.perDay;
      _bonusAmount = PlayerBonusLimits.clampAmount(bonus.amount);
      _bonusMinBet = PlayerBonusLimits.clampMinBet(bonus.minBet);
      _allowIncomeRounding = profile.allowIncomeRounding;
      _currency = AppCurrency.fromSettings(profile.settings);
      final langCode = system['language'] as String?;
      if (langCode != null) {
        _language = AppLanguage.fromCode(langCode);
      }
      _savedProfit = profile.cashierProfit;
      _savedBingoClaimMode = BingoClaimMode.fromSettings(system);
      _savedIncomeRounding = profile.allowIncomeRounding;
      _category = profile.category.trim().isEmpty ? 'default' : profile.category.trim();
      _savedCategory = _category;
      if (!_categories.contains(_category)) {
        _categories = [..._categories, _category]..sort();
      }
    });
  }

  Map<String, dynamic> _ethiomarkSettingsPayload() {
    final system = Map<String, dynamic>.from(
      _settings['system'] as Map<String, dynamic>? ?? {},
    );
    system['profit'] = _profit;
    system['good_bingo_sound'] = _goodSound;
    system[BingoClaimMode.storageKey] = _bingoClaimMode.id;
    system['bingo_claim_limit'] = _bingoClaimMode.legacyLimit;
    system['currency'] = _currency;
    system['language'] = _language.code;
    system['income_rounding'] = _allowIncomeRounding ? 'on' : 'off';

    final toggles = Map<String, dynamic>.from(
      _settings['toggles'] as Map<String, dynamic>? ?? {},
    );
    toggles['will_start'] = _willStartSound;
    toggles['started'] = _startedSound;
    toggles['stopped'] = _stoppedSound;
    toggles['show_card_count'] = _showCardCount;
    toggles['show_pattern_on_play'] = _showPatternOnStart;
    toggles.remove('show_pattern_on_start');

    final payload = Map<String, dynamic>.from(_settings);
    payload['bonus'] = PlayerBonusSettings(
      round: _bonusRound,
      count: _bonusCount,
      perDay: _bonusPerDay,
      amount: PlayerBonusLimits.clampAmount(_bonusAmount),
      minBet: PlayerBonusLimits.clampMinBet(_bonusMinBet),
    ).toMap();
    payload['system'] = system;
    payload['toggles'] = toggles;
    return payload;
  }

  Map<String, dynamic> _instantApplyResult() => {
        'goodSound': _goodSound,
        'currency': _currency,
        'language': _language.code,
        'startedSound': _startedSound,
        'stoppedSound': _stoppedSound,
        'showCardCount': _showCardCount,
        'showPatternOnStart': _showPatternOnStart,
        'allowIncomeRounding': _allowIncomeRounding,
        'category': _category,
      };

  void _closeSheet() {
    Navigator.pop(context, _instantApplyResult());
  }

  bool _playerSaveTouchesNextRound() {
    return _profit != _savedProfit ||
        _bingoClaimMode != _savedBingoClaimMode ||
        _allowIncomeRounding != _savedIncomeRounding ||
        _category != _savedCategory;
  }

  bool _systemSaveTouchesNextRound() => false;

  Widget _wrapForPop(Widget child) {
    return PopScope(
      // Close only via the header close button — not barrier, Escape, or system back.
      canPop: false,
      child: child,
    );
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  Future<void> _savePlayerSettings() async {
    setState(() => _saving = true);
    final s = context.read<LocaleController>().strings;
    final nextRoundChanged = _playerSaveTouchesNextRound();
    final categoryChanged = _category != _savedCategory;

    await widget.gameRepository.updateSettings(
      widget.cashierId,
      _ethiomarkSettingsPayload(),
    );
    if (categoryChanged) {
      await widget.gameRepository.updateCashierCategory(
        cashierId: widget.cashierId,
        category: _category,
      );
      final session = widget.session;
      if (session != null) {
        widget.onIdentityUpdated?.call(
          CashierSession(
            cashierId: session.cashierId,
            partnerId: session.partnerId,
            category: _category,
            packageBalance: session.packageBalance,
            isActive: session.isActive,
          ),
        );
      }
    }
    if (!mounted) return;
    await _refreshFromProfile();
    if (!mounted) return;
    await context.read<LocaleController>().setLanguage(_language);
    if (!mounted) return;
    setState(() => _saving = false);
    showAppToast(
      context,
      widget.houseCutLocked && nextRoundChanged
          ? s.settingsGroupNextRoundHint
          : (categoryChanged ? s.categorySetTo(_category) : s.settingsSaved),
      type: AppToastType.success,
    );
  }

  Future<void> _saveSystemSettings() async {
    setState(() => _saving = true);
    final s = context.read<LocaleController>().strings;
    final nextRoundChanged = _systemSaveTouchesNextRound();

    final setupState = _setupPanelKey.currentState;
    if (setupState != null) {
      final ok = await setupState.savePendingChanges();
      if (!ok) {
        if (mounted) setState(() => _saving = false);
        return;
      }
    }

    await widget.gameRepository.updateSettings(
      widget.cashierId,
      _ethiomarkSettingsPayload(),
    );
    if (!mounted) return;
    await _refreshFromProfile();
    if (!mounted) return;
    await context.read<LocaleController>().setLanguage(_language);
    if (!mounted) return;
    setState(() => _saving = false);
    showAppToast(
      context,
      widget.houseCutLocked && nextRoundChanged
          ? s.settingsGroupNextRoundHint
          : s.settingsSaved,
      type: AppToastType.success,
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().strings;
    final desktop = context.isDesktop;
    final header = _PlaySettingsHeader(
      title: s.settingsTitleEthiomark,
      closeLabel: s.close,
      saving: _saving,
      onClose: _closeSheet,
      showDragHandle: !widget.embedded,
      desktop: desktop,
    );
    final body = AppLoadingOverlay(
      loading: _saving,
      message: s.savingSettings,
      child: _PlaySettingsBody(
        desktop: desktop,
        embedded: widget.embedded,
        saving: _saving,
        bonusRound: _bonusRound,
        bonusCount: _bonusCount,
        bonusPerDay: _bonusPerDay,
        bonusAmount: _bonusAmount,
        bonusMinBet: _bonusMinBet,
        goodSound: _goodSound,
        profit: _profit,
        bingoClaimMode: _bingoClaimMode,
        category: _category,
        categories: _categories,
        willStartSound: _willStartSound,
        startedSound: _startedSound,
        stoppedSound: _stoppedSound,
        showCardCount: _showCardCount,
        showPatternOnStart: _showPatternOnStart,
        allowIncomeRounding: _allowIncomeRounding,
        language: _language,
        currency: _currency,
        onLanguageChanged: (v) => setState(() => _language = v),
        onCurrencyChanged: (v) => setState(() => _currency = v),
        onBonusRoundChanged: (v) => setState(() => _bonusRound = v),
        onBonusCountChanged: (v) => setState(() => _bonusCount = v),
        onBonusPerDayChanged: (v) => setState(() => _bonusPerDay = v),
        onBonusAmountChanged: (v) => setState(() => _bonusAmount = v),
        onBonusMinBetChanged: (v) => setState(() => _bonusMinBet = v),
        onGoodSoundChanged: (v) => setState(() => _goodSound = v),
        onProfitChanged: (v) => setState(() => _profit = v),
        onBingoClaimModeChanged: (v) => setState(() => _bingoClaimMode = v),
        onCategoryChanged: (v) => setState(() => _category = v),
        onWillStartSoundChanged: (v) => setState(() => _willStartSound = v),
        onStartedSoundChanged: (v) => setState(() => _startedSound = v),
        onStoppedSoundChanged: (v) => setState(() => _stoppedSound = v),
        onShowCardCountChanged: (v) => setState(() => _showCardCount = v),
        onShowPatternOnStartChanged: (v) => setState(() => _showPatternOnStart = v),
        onAllowIncomeRoundingChanged: (v) =>
            setState(() => _allowIncomeRounding = v),
      ),
    );
    final setupPanel = widget.hasSetupPanel
        ? PlaySetupPanel(
            key: _setupPanelKey,
            session: widget.session!,
            gameRepository: widget.gameRepository,
            setupRepository: widget.setupRepository!,
            cartelaImporter: widget.cartelaImporter!,
            onBalanceChanged: widget.onBalanceChanged!,
            onIdentityUpdated: widget.onIdentityUpdated,
            embedded: true,
            saving: _saving,
          )
        : null;

    final systemBody = AppLoadingOverlay(
      loading: _saving,
      message: s.savingSettings,
      child: _SystemSettingsBody(
        desktop: desktop,
        embedded: widget.embedded,
        cardsAndSync: setupPanel,
      ),
    );

    Widget stickyFooter({required Future<void> Function() onSave}) {
      return _SettingsModalFooter(
        desktop: desktop,
        saving: _saving,
        label: s.saveChanges,
        onPressed: () => onSave(),
      );
    }

    if (_useTabs) {
      final tabbed = Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1F413E), Color(0xFFF0F0F0)],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            header,
            Material(
              color: Colors.transparent,
              child: TabBar(
                controller: _tabController,
                labelColor: BingoColors.gold,
                unselectedLabelColor: BingoColors.textSecondary,
                indicatorColor: BingoColors.gold,
                labelStyle: TextStyle(
                  fontSize: desktop ? 14 : 12,
                  fontWeight: FontWeight.w700,
                ),
                tabs: [
                  Tab(text: s.playerSettings),
                  Tab(text: s.systemSettings),
                ],
              ),
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _SettingsScrollPane(child: body),
                  _SettingsScrollPane(child: systemBody),
                ],
              ),
            ),
            stickyFooter(
              onSave: () async {
                if (_tabController?.index == 1) {
                  await _saveSystemSettings();
                } else {
                  await _savePlayerSettings();
                }
              },
            ),
          ],
        ),
      );

      return _wrapForPop(tabbed);
    }

    if (widget.embedded) {
      return _wrapForPop(
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1F413E), Color(0xFFF0F0F0)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              header,
              Expanded(child: _SettingsScrollPane(child: body)),
              stickyFooter(onSave: _savePlayerSettings),
            ],
          ),
        ),
      );
    }

    return _wrapForPop(
      Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1F413E), Color(0xFFF0F0F0)],
          ),
        ),
        child: DraggableScrollableSheet(
          expand: false,
          initialChildSize: desktop ? 0.92 : 0.88,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          builder: (context, scrollController) {
            return Column(
              children: [
                header,
                Expanded(
                  child: _SettingsScrollPane(
                    controller: scrollController,
                    child: body,
                  ),
                ),
                stickyFooter(onSave: _savePlayerSettings),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _PlaySettingsHeader extends StatelessWidget {
  const _PlaySettingsHeader({
    required this.title,
    required this.closeLabel,
    required this.saving,
    required this.onClose,
    required this.showDragHandle,
    required this.desktop,
  });

  final String title;
  final String closeLabel;
  final bool saving;
  final VoidCallback onClose;
  final bool showDragHandle;
  final bool desktop;

  @override
  Widget build(BuildContext context) {
    const ethiomarkGreen = Color(0xFF28A745);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border(
          bottom: BorderSide(color: ethiomarkGreen, width: 2),
        ),
        borderRadius: showDragHandle
            ? const BorderRadius.vertical(top: Radius.circular(22))
            : const BorderRadius.vertical(top: Radius.circular(_settingsDialogRadius)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (showDragHandle) ...[
            const SizedBox(height: 8),
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.black26,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Padding(
            padding: EdgeInsets.fromLTRB(
              desktop ? 16 : 12,
              showDragHandle ? 0 : 12,
              desktop ? 6 : 4,
              12,
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: desktop ? 25 : 20,
                      fontWeight: FontWeight.w800,
                      color: ethiomarkGreen,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: closeLabel,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 40, minHeight: 40),
                  onPressed: saving ? null : onClose,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFFFEBEE),
                    foregroundColor: const Color(0xFFD32F2F),
                    disabledBackgroundColor: const Color(0xFFFFEBEE),
                    disabledForegroundColor:
                        const Color(0xFFD32F2F).withValues(alpha: 0.4),
                  ),
                  icon: Icon(
                    Icons.close,
                    size: desktop ? 26 : 24,
                    color: saving
                        ? const Color(0xFFD32F2F).withValues(alpha: 0.4)
                        : const Color(0xFFD32F2F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SystemSettingsBody extends StatelessWidget {
  const _SystemSettingsBody({
    required this.desktop,
    required this.embedded,
    this.cardsAndSync,
  });

  final bool desktop;
  final bool embedded;
  final Widget? cardsAndSync;

  @override
  Widget build(BuildContext context) {
    final sectionGap = desktop ? 10.0 : 8.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        desktop ? 12 : 8,
        embedded ? 8 : 5,
        desktop ? 12 : 8,
        desktop ? 8 : 6,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (cardsAndSync != null) ...[
            cardsAndSync!,
            SizedBox(height: sectionGap),
          ],
        ],
      ),
    );
  }
}

class _PlaySettingsBody extends StatelessWidget {
  const _PlaySettingsBody({
    required this.desktop,
    required this.embedded,
    required this.saving,
    required this.bonusRound,
    required this.bonusCount,
    required this.bonusPerDay,
    required this.bonusAmount,
    required this.bonusMinBet,
    required this.goodSound,
    required this.profit,
    required this.bingoClaimMode,
    required this.category,
    required this.categories,
    required this.willStartSound,
    required this.startedSound,
    required this.stoppedSound,
    required this.showCardCount,
    required this.showPatternOnStart,
    required this.allowIncomeRounding,
    required this.language,
    required this.currency,
    required this.onLanguageChanged,
    required this.onCurrencyChanged,
    required this.onBonusRoundChanged,
    required this.onBonusCountChanged,
    required this.onBonusPerDayChanged,
    required this.onBonusAmountChanged,
    required this.onBonusMinBetChanged,
    required this.onGoodSoundChanged,
    required this.onProfitChanged,
    required this.onBingoClaimModeChanged,
    required this.onCategoryChanged,
    required this.onWillStartSoundChanged,
    required this.onStartedSoundChanged,
    required this.onStoppedSoundChanged,
    required this.onShowCardCountChanged,
    required this.onShowPatternOnStartChanged,
    required this.onAllowIncomeRoundingChanged,
  });

  final bool desktop;
  final bool embedded;
  final bool saving;
  final PlayerBonusRound bonusRound;
  final int bonusCount;
  final int bonusPerDay;
  final int bonusAmount;
  final int bonusMinBet;
  final int goodSound;
  final int profit;
  final BingoClaimMode bingoClaimMode;
  final String category;
  final List<String> categories;
  final bool willStartSound;
  final bool startedSound;
  final bool stoppedSound;
  final bool showCardCount;
  final bool showPatternOnStart;
  final bool allowIncomeRounding;
  final AppLanguage language;
  final String currency;
  final ValueChanged<AppLanguage> onLanguageChanged;
  final ValueChanged<String> onCurrencyChanged;
  final ValueChanged<PlayerBonusRound> onBonusRoundChanged;
  final ValueChanged<int> onBonusCountChanged;
  final ValueChanged<int> onBonusPerDayChanged;
  final ValueChanged<int> onBonusAmountChanged;
  final ValueChanged<int> onBonusMinBetChanged;
  final ValueChanged<int> onGoodSoundChanged;
  final ValueChanged<int> onProfitChanged;
  final ValueChanged<BingoClaimMode> onBingoClaimModeChanged;
  final ValueChanged<String> onCategoryChanged;
  final ValueChanged<bool> onWillStartSoundChanged;
  final ValueChanged<bool> onStartedSoundChanged;
  final ValueChanged<bool> onStoppedSoundChanged;
  final ValueChanged<bool> onShowCardCountChanged;
  final ValueChanged<bool> onShowPatternOnStartChanged;
  final ValueChanged<bool> onAllowIncomeRoundingChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().strings;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        desktop ? 16 : 12,
        embedded ? 10 : 8,
        desktop ? 16 : 12,
        desktop ? 12 : 10,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _EthiomarkGroupedSettingsCard(
            desktop: desktop,
            showRowDividers: true,
            children: [
              _EthiomarkToggleRow(
                desktop: desktop,
                label: s.bonus,
                value: bonusRound != PlayerBonusRound.off,
                enabled: !saving,
                activeColor: const Color(0xFFE6A800),
                labelSize: desktop ? 13.0 : 12.0,
                onChanged: (on) {
                  if (on) {
                    onBonusRoundChanged(
                      bonusRound == PlayerBonusRound.off
                          ? PlayerBonusSettings.defaults.round
                          : bonusRound,
                    );
                  } else {
                    onBonusRoundChanged(PlayerBonusRound.off);
                  }
                },
              ),
              if (bonusRound != PlayerBonusRound.off)
                _BonusSettingsPanel(
                  desktop: desktop,
                  saving: saving,
                  bonusRound: bonusRound,
                  bonusCount: bonusCount,
                  bonusPerDay: bonusPerDay,
                  bonusAmount: bonusAmount,
                  bonusMinBet: bonusMinBet,
                  onBonusRoundChanged: onBonusRoundChanged,
                  onBonusCountChanged: onBonusCountChanged,
                  onBonusPerDayChanged: onBonusPerDayChanged,
                  onBonusAmountChanged: onBonusAmountChanged,
                  onBonusMinBetChanged: onBonusMinBetChanged,
                ),
              _EthiomarkSettingsInputRow(
                desktop: desktop,
                label: s.goodBingoSoundSettingsLabel,
                child: settingsDropdown<int>(
                  desktop: desktop,
                  value: goodSound.clamp(0, 2),
                  items: [
                    DropdownMenuItem(
                      value: 0,
                      child: Text(s.goodBingoSoundEthiomark0),
                    ),
                    DropdownMenuItem(
                      value: 1,
                      child: Text(s.goodBingoSoundEthiomark1),
                    ),
                    DropdownMenuItem(
                      value: 2,
                      child: Text(s.goodBingoSoundEthiomark2),
                    ),
                  ],
                  onChanged:
                      saving ? null : (v) => onGoodSoundChanged(v ?? goodSound),
                ),
              ),
              _EthiomarkSettingsInputRow(
                desktop: desktop,
                label: s.setProfitLabel,
                child: settingsDropdown<int>(
                  desktop: desktop,
                  value: kHouseProfitOptions.contains(profit) ? profit : 0,
                  items: kHouseProfitOptions.map((p) {
                    final label = p == 0 ? s.useDefaultPlan : '$p%';
                    return DropdownMenuItem(value: p, child: Text(label));
                  }).toList(),
                  onChanged: saving ? null : (v) => onProfitChanged(v ?? profit),
                ),
              ),
              _EthiomarkSettingsInputRow(
                desktop: desktop,
                label: s.bingoClaimTime,
                child: settingsDropdown<BingoClaimMode>(
                  desktop: desktop,
                  value: bingoClaimMode,
                  items: kBingoClaimModeOptions.map((mode) {
                    return DropdownMenuItem(
                      value: mode,
                      child: Text(s.bingoClaimModeLabel(mode)),
                    );
                  }).toList(),
                  onChanged: saving
                      ? null
                      : (v) => onBingoClaimModeChanged(v ?? bingoClaimMode),
                ),
              ),
              _EthiomarkSettingsInputRow(
                desktop: desktop,
                label: s.cartelaCategory,
                child: settingsDropdown<String>(
                  desktop: desktop,
                  value: categories.contains(category)
                      ? category
                      : (categories.isNotEmpty ? categories.first : category),
                  items: (categories.isEmpty ? <String>[category] : categories)
                      .map(
                        (name) => DropdownMenuItem(
                          value: name,
                          child: Text(name),
                        ),
                      )
                      .toList(),
                  onChanged: saving
                      ? null
                      : (v) {
                          final next = (v ?? category).trim();
                          if (next.isNotEmpty) onCategoryChanged(next);
                        },
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _EthiomarkGroupedSettingsCard(
            desktop: desktop,
            showRowDividers: true,
            children: [
              _EthiomarkToggleRow(
                desktop: desktop,
                label: s.toggleWillStartSound,
                value: willStartSound,
                enabled: !saving,
                activeColor: const Color(0xFF28A745),
                labelSize: desktop ? 13.0 : 12.0,
                onChanged: onWillStartSoundChanged,
              ),
              _EthiomarkToggleRow(
                desktop: desktop,
                label: s.toggleStartedSound,
                value: startedSound,
                enabled: !saving,
                activeColor: const Color(0xFF28A745),
                labelSize: desktop ? 13.0 : 12.0,
                onChanged: onStartedSoundChanged,
              ),
              _EthiomarkToggleRow(
                desktop: desktop,
                label: s.toggleStoppedSound,
                value: stoppedSound,
                enabled: !saving,
                activeColor: const Color(0xFF28A745),
                labelSize: desktop ? 13.0 : 12.0,
                onChanged: onStoppedSoundChanged,
              ),
              _EthiomarkToggleRow(
                desktop: desktop,
                label: s.toggleShowCardCount,
                value: showCardCount,
                enabled: !saving,
                activeColor: const Color(0xFF28A745),
                labelSize: desktop ? 13.0 : 12.0,
                onChanged: onShowCardCountChanged,
              ),
              _EthiomarkToggleRow(
                desktop: desktop,
                label: s.toggleShowPatternOnStart,
                value: showPatternOnStart,
                enabled: !saving,
                activeColor: const Color(0xFF28A745),
                labelSize: desktop ? 13.0 : 12.0,
                onChanged: onShowPatternOnStartChanged,
              ),
              _EthiomarkToggleRow(
                desktop: desktop,
                label: s.toggleAllowIncomeRounding,
                value: allowIncomeRounding,
                enabled: !saving,
                activeColor: const Color(0xFF28A745),
                labelSize: desktop ? 13.0 : 12.0,
                onChanged: onAllowIncomeRoundingChanged,
              ),
              _EthiomarkSettingsInputRow(
                desktop: desktop,
                label: s.languageLabel,
                child: settingsDropdown<AppLanguage>(
                  desktop: desktop,
                  value: language,
                  items: AppLanguage.values
                      .map(
                        (lang) => DropdownMenuItem(
                          value: lang,
                          child: Text(lang.nativeName),
                        ),
                      )
                      .toList(),
                  onChanged:
                      saving ? null : (v) => onLanguageChanged(v ?? language),
                ),
              ),
              _EthiomarkSettingsInputRow(
                desktop: desktop,
                label: s.currencyFieldLabel,
                child: settingsDropdown<String>(
                  desktop: desktop,
                  value: AppCurrency.normalize(currency),
                  items: AppCurrency.codes
                      .map(
                        (code) => DropdownMenuItem(
                          value: code,
                          child: Text(s.currencyLabel(code)),
                        ),
                      )
                      .toList(),
                  onChanged: saving
                      ? null
                      : (v) => onCurrencyChanged(AppCurrency.normalize(v)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget settingsDropdown<T>({
    required bool desktop,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
    bool onLightBar = true,
  }) {
    final textColor = onLightBar
        ? const Color(0xFF1A1A1A)
        : Colors.white;
    final iconColor = onLightBar
        ? const Color(0xFF5F6368)
        : Colors.white.withValues(alpha: 0.85);
    final textStyle = TextStyle(
      fontSize: desktop ? 13 : 12,
      fontWeight: FontWeight.w600,
      color: textColor,
    );

    // Cap menu height so long lists (e.g. cartela categories) scroll with a
    // clearly visible scrollbar column — matches ethiomark select behavior.
    final menuMaxHeight = desktop ? 280.0 : 240.0;

    return Theme(
      data: ThemeData(
        brightness: Brightness.light,
        scrollbarTheme: ScrollbarThemeData(
          thumbVisibility: WidgetStateProperty.all(true),
          trackVisibility: WidgetStateProperty.all(true),
          thickness: WidgetStateProperty.all(12),
          radius: const Radius.circular(6),
          thumbColor: WidgetStateProperty.all(const Color(0xFFFFC107)),
          trackColor: WidgetStateProperty.all(const Color(0xFF1A1A1A)),
          trackBorderColor: WidgetStateProperty.all(const Color(0xFFFFE082)),
          crossAxisMargin: 2,
          mainAxisMargin: 4,
          minThumbLength: 40,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          key: ValueKey(value),
          value: value,
          isExpanded: true,
          isDense: true,
          dropdownColor: Colors.white,
          menuMaxHeight: menuMaxHeight,
          borderRadius: BorderRadius.circular(10),
          icon: Icon(Icons.arrow_drop_down, color: iconColor, size: 22),
          style: textStyle,
          alignment: AlignmentDirectional.centerEnd,
          selectedItemBuilder: (context) {
            return [
              for (final item in items)
                Align(
                  alignment: Alignment.centerRight,
                  child: DefaultTextStyle.merge(
                    style: textStyle,
                    child: item.child ?? const SizedBox.shrink(),
                  ),
                ),
            ];
          },
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _EthiomarkNumberField extends StatelessWidget {
  const _EthiomarkNumberField({
    required this.desktop,
    required this.value,
    required this.min,
    required this.max,
    required this.step,
    required this.enabled,
    required this.onChanged,
  });

  final bool desktop;
  final int value;
  final int min;
  final int max;
  final int step;
  final bool enabled;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      initialValue: '$value',
      enabled: enabled,
      keyboardType: TextInputType.number,
      textAlign: TextAlign.right,
      style: TextStyle(
        fontSize: desktop ? 14 : 13,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF333333),
      ),
      decoration: InputDecoration(
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        filled: true,
        fillColor: const Color(0xFFF9F9F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(5),
          borderSide: const BorderSide(color: Color(0xFFDDDDDD)),
        ),
      ),
      onChanged: (raw) {
        final parsed = int.tryParse(raw);
        if (parsed == null) return;
        final clamped = parsed.clamp(min, max);
        final stepped = ((clamped / step).round() * step).clamp(min, max);
        onChanged(stepped);
      },
    );
  }
}

class _BonusSettingsPanel extends StatelessWidget {
  const _BonusSettingsPanel({
    required this.desktop,
    required this.saving,
    required this.bonusRound,
    required this.bonusCount,
    required this.bonusPerDay,
    required this.bonusAmount,
    required this.bonusMinBet,
    required this.onBonusRoundChanged,
    required this.onBonusCountChanged,
    required this.onBonusPerDayChanged,
    required this.onBonusAmountChanged,
    required this.onBonusMinBetChanged,
  });

  final bool desktop;
  final bool saving;
  final PlayerBonusRound bonusRound;
  final int bonusCount;
  final int bonusPerDay;
  final int bonusAmount;
  final int bonusMinBet;
  final ValueChanged<PlayerBonusRound> onBonusRoundChanged;
  final ValueChanged<int> onBonusCountChanged;
  final ValueChanged<int> onBonusPerDayChanged;
  final ValueChanged<int> onBonusAmountChanged;
  final ValueChanged<int> onBonusMinBetChanged;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().strings;
    final activeRound =
        bonusRound == PlayerBonusRound.off ? PlayerBonusRound.every1 : bonusRound;

    return Padding(
      padding: EdgeInsets.fromLTRB(desktop ? 18 : 14, 4, 0, 6),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFFF8E7),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFFE6C35C)),
        ),
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            desktop ? 10 : 8,
            desktop ? 8 : 6,
            desktop ? 8 : 6,
            desktop ? 8 : 6,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _EthiomarkSettingsInputRow(
                desktop: desktop,
                label: s.bonusRoundLabel,
                child: _PlaySettingsBody.settingsDropdown<PlayerBonusRound>(
                  desktop: desktop,
                  value: activeRound,
                  items: [
                    DropdownMenuItem(
                      value: PlayerBonusRound.every1,
                      child: Text(s.bonusRoundEvery1),
                    ),
                    DropdownMenuItem(
                      value: PlayerBonusRound.every3,
                      child: Text(s.bonusRoundEvery3),
                    ),
                    DropdownMenuItem(
                      value: PlayerBonusRound.every4,
                      child: Text(s.bonusRoundEvery4),
                    ),
                    DropdownMenuItem(
                      value: PlayerBonusRound.every10,
                      child: Text(s.bonusRoundEvery10),
                    ),
                    DropdownMenuItem(
                      value: PlayerBonusRound.random,
                      child: Text(s.bonusRoundRandom),
                    ),
                  ],
                  onChanged: saving
                      ? null
                      : (v) => onBonusRoundChanged(v ?? activeRound),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: Divider(height: 1, thickness: 1, color: Color(0xFFE8D9A8)),
              ),
              _EthiomarkSettingsInputRow(
                desktop: desktop,
                label: s.bonusPerDayLabel,
                child: _PlaySettingsBody.settingsDropdown<int>(
                  desktop: desktop,
                  value: bonusPerDay.clamp(1, 20),
                  items: List.generate(
                    20,
                    (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text('${i + 1}'),
                    ),
                  ),
                  onChanged: saving
                      ? null
                      : (v) => onBonusPerDayChanged(v ?? bonusPerDay),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: Divider(height: 1, thickness: 1, color: Color(0xFFE8D9A8)),
              ),
              _EthiomarkSettingsInputRow(
                desktop: desktop,
                label: s.bonusLuckyCountLabel,
                child: _PlaySettingsBody.settingsDropdown<int>(
                  desktop: desktop,
                  value: bonusCount.clamp(1, 10),
                  items: List.generate(
                    10,
                    (i) => DropdownMenuItem(
                      value: i + 1,
                      child: Text('${i + 1}'),
                    ),
                  ),
                  onChanged: saving
                      ? null
                      : (v) => onBonusCountChanged(v ?? bonusCount),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: Divider(height: 1, thickness: 1, color: Color(0xFFE8D9A8)),
              ),
              _EthiomarkSettingsInputRow(
                desktop: desktop,
                label: s.bonusAmountLabel,
                child: _EthiomarkNumberField(
                  desktop: desktop,
                  value: PlayerBonusLimits.clampAmount(bonusAmount),
                  min: PlayerBonusLimits.minAmount,
                  max: PlayerBonusLimits.maxAmount,
                  step: 10,
                  enabled: !saving,
                  onChanged: (v) =>
                      onBonusAmountChanged(PlayerBonusLimits.clampAmount(v)),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: Divider(height: 1, thickness: 1, color: Color(0xFFE8D9A8)),
              ),
              _EthiomarkSettingsInputRow(
                desktop: desktop,
                label: s.bonusMinBetLabel,
                child: _EthiomarkNumberField(
                  desktop: desktop,
                  value: PlayerBonusLimits.clampMinBet(bonusMinBet),
                  min: PlayerBonusLimits.minTotalBet,
                  max: PlayerBonusLimits.maxTotalBet,
                  step: 50,
                  enabled: !saving,
                  onChanged: (v) =>
                      onBonusMinBetChanged(PlayerBonusLimits.clampMinBet(v)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EthiomarkGroupedSettingsCard extends StatelessWidget {
  const _EthiomarkGroupedSettingsCard({
    required this.desktop,
    required this.children,
    this.showRowDividers = false,
  });

  final bool desktop;
  final List<Widget> children;
  final bool showRowDividers;

  List<Widget> _layoutChildren() {
    if (!showRowDividers || children.isEmpty) return children;

    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      if (i > 0) {
        rows.add(
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 1),
            child: Divider(
              height: 1,
              thickness: 1,
              color: Color(0xFFE2E6EA),
            ),
          ),
        );
      }
      rows.add(children[i]);
    }
    return rows;
  }

  @override
  Widget build(BuildContext context) {
    final rowInset = desktop ? 6.0 : 4.0;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: desktop ? 8 : 6,
        vertical: desktop ? 5 : 4,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF091318)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: rowInset, vertical: 2),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: _layoutChildren(),
        ),
      ),
    );
  }
}

/// Compact row — label left, control right (matches toggle rows).
class _EthiomarkSettingsInputRow extends StatelessWidget {
  const _EthiomarkSettingsInputRow({
    required this.desktop,
    required this.label,
    required this.child,
    this.subtitle,
  });

  final bool desktop;
  final String label;
  final String? subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final labelSize = desktop ? 13.0 : 12.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: labelSize,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF2A3446),
                    height: 1.2,
                  ),
                ),
                if (subtitle != null) ...[
                  const SizedBox(height: 1),
                  Text(
                    subtitle!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: desktop ? 10.5 : 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF5F6368),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: desktop ? 220 : 170,
              minWidth: desktop ? 120 : 96,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}

class _EthiomarkToggleRow extends StatelessWidget {
  const _EthiomarkToggleRow({
    required this.desktop,
    required this.label,
    required this.value,
    required this.enabled,
    required this.activeColor,
    required this.labelSize,
    required this.onChanged,
  });

  final bool desktop;
  final String label;
  final bool value;
  final bool enabled;
  final Color activeColor;
  final double labelSize;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: labelSize,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF2A3446),
                height: 1.2,
              ),
            ),
          ),
          const SizedBox(width: 8),
          ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: desktop ? 220 : 170,
              minWidth: _CompactSettingsSwitch.width,
            ),
            child: Align(
              alignment: Alignment.centerRight,
              child: _CompactSettingsSwitch(
                value: value,
                enabled: enabled,
                activeColor: activeColor,
                onChanged: onChanged,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ethiomark `.sound-settings-switch` — 52×28, tighter than Material default.
class _CompactSettingsSwitch extends StatelessWidget {
  const _CompactSettingsSwitch({
    required this.value,
    required this.enabled,
    required this.activeColor,
    required this.onChanged,
  });

  final bool value;
  final bool enabled;
  final Color activeColor;
  final ValueChanged<bool> onChanged;

  static const width = 52.0;
  static const height = 28.0;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: height,
      child: Transform.scale(
        scale: 0.82,
        alignment: Alignment.center,
        child: Switch(
          value: value,
          onChanged: enabled ? onChanged : null,
          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          activeThumbColor: Colors.white,
          activeTrackColor: activeColor,
          inactiveThumbColor: Colors.white,
          inactiveTrackColor: const Color(0xFFE4E9F1),
        ),
      ),
    );
  }
}

class _EthiomarkSaveButton extends StatelessWidget {
  const _EthiomarkSaveButton({
    required this.desktop,
    required this.saving,
    required this.label,
    required this.onPressed,
    this.compact = false,
  });

  final bool desktop;
  final bool saving;
  final String label;
  final VoidCallback? onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    const ethiomarkGreen = Color(0xFF28A745);
    final radius = compact ? 8.0 : 10.0;

    return Center(
      child: Material(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(radius),
        elevation: compact ? 1 : 2,
        shadowColor: Colors.black26,
        child: InkWell(
          onTap: saving ? null : onPressed,
          borderRadius: BorderRadius.circular(radius),
          child: Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 10 : (desktop ? 20 : 16),
              vertical: compact ? (desktop ? 4 : 3) : (desktop ? 14 : 12),
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(color: Colors.black.withValues(alpha: 0.08)),
            ),
            alignment: Alignment.center,
            child: saving
                ? AppButtonLoader(
                    color: ethiomarkGreen,
                    size: compact ? 22 : 24,
                  )
                : Text(
                    label,
                    style: TextStyle(
                      fontSize: compact
                          ? (desktop ? 26 : 22)
                          : (desktop ? 28 : 22),
                      fontWeight: FontWeight.w800,
                      color: ethiomarkGreen,
                      height: 1.1,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Always-visible scrollbar for settings content.
class _SettingsScrollPane extends StatefulWidget {
  const _SettingsScrollPane({required this.child, this.controller});

  final Widget child;
  final ScrollController? controller;

  @override
  State<_SettingsScrollPane> createState() => _SettingsScrollPaneState();
}

class _SettingsScrollPaneState extends State<_SettingsScrollPane> {
  ScrollController? _ownedController;

  ScrollController get _controller =>
      widget.controller ?? _ownedController!;

  /// High-contrast scrollbar so the column is obvious on the settings gradient.
  static const _thumb = Color(0xFFFFC107);
  static const _track = Color(0xFF1A1A1A);
  static const _trackBorder = Color(0xFFFFE082);

  @override
  void initState() {
    super.initState();
    if (widget.controller == null) {
      _ownedController = ScrollController();
    }
  }

  @override
  void dispose() {
    _ownedController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RawScrollbar(
      controller: _controller,
      thumbVisibility: true,
      trackVisibility: true,
      interactive: true,
      thickness: 14,
      radius: const Radius.circular(7),
      thumbColor: _thumb,
      trackColor: _track,
      trackBorderColor: _trackBorder,
      trackRadius: const Radius.circular(7),
      minThumbLength: 48,
      padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 3),
      child: SingleChildScrollView(
        controller: _controller,
        primary: false,
        padding: const EdgeInsets.only(right: 6),
        child: widget.child,
      ),
    );
  }
}

/// Fixed modal footer so Save stays visible while content scrolls.
class _SettingsModalFooter extends StatelessWidget {
  const _SettingsModalFooter({
    required this.desktop,
    required this.saving,
    required this.label,
    required this.onPressed,
  });

  final bool desktop;
  final bool saving;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF4F4F4),
      elevation: 6,
      shadowColor: Colors.black38,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            desktop ? 10 : 8,
            desktop ? 4 : 3,
            desktop ? 10 : 8,
            desktop ? 6 : 4,
          ),
          child: _EthiomarkSaveButton(
            desktop: desktop,
            saving: saving,
            label: label,
            onPressed: onPressed,
            compact: true,
          ),
        ),
      ),
    );
  }
}

Future<Map<String, dynamic>?> openPlayControls(
  BuildContext context, {
  required String cashierId,
  required GameRepository gameRepository,
  required Map<String, dynamic> settings,
  required int goodBingoSound,
  required int cashierProfit,
  required BingoClaimMode bingoClaimMode,
  bool houseCutLocked = false,
  CashierSession? session,
  SetupRepository? setupRepository,
  CartelaImporter? cartelaImporter,
  Future<void> Function()? onBalanceChanged,
  void Function(CashierSession session)? onIdentityUpdated,
}) {
  final locale = context.read<LocaleController>();
  final panel = PlayControlsSheet(
    cashierId: cashierId,
    gameRepository: gameRepository,
    settings: settings,
    goodBingoSound: goodBingoSound,
    cashierProfit: cashierProfit,
    bingoClaimMode: bingoClaimMode,
    initialLanguage: locale.language,
    initialCurrency: AppCurrency.fromSettings(settings),
    houseCutLocked: houseCutLocked,
    embedded: context.isDesktop,
    session: session,
    setupRepository: setupRepository,
    cartelaImporter: cartelaImporter,
    onBalanceChanged: onBalanceChanged,
    onIdentityUpdated: onIdentityUpdated,
  );

  if (context.isDesktop) {
    return ModalGuard.run(
      ModalKeys.playControls,
      () => showDialog<Map<String, dynamic>>(
        context: context,
        barrierDismissible: false,
        builder: (ctx) {
          final insets = _PlayDesktopDialogInsets(ctx);
          return Dialog(
            alignment: Alignment.topRight,
            backgroundColor: Colors.transparent,
            insetPadding: insets.padding,
            clipBehavior: Clip.antiAlias,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(_settingsDialogRadius),
            ),
            child: SizedBox(
              width: 520,
              height: insets.availableHeight,
              child: panel,
            ),
          );
        },
      ),
    );
  }

  return ModalGuard.run(
    ModalKeys.playControls,
    () => showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      backgroundColor: BingoColors.surface,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        if (panel.hasSetupPanel) {
          return SizedBox(
            height: MediaQuery.sizeOf(ctx).height * 0.88,
            child: panel,
          );
        }
        return panel;
      },
    ),
  );
}

Future<void> openPlaySetupPanel(
  BuildContext context, {
  required CashierSession session,
  required GameRepository gameRepository,
  required SetupRepository setupRepository,
  required CartelaImporter cartelaImporter,
  required Future<void> Function() onBalanceChanged,
  void Function(CashierSession session)? onIdentityUpdated,
}) {
  final s = context.read<LocaleController>().strings;
  final shell = _PlaySetupPanelShell(
    title: s.playSetupTab,
    closeLabel: s.close,
    saveLabel: s.saveSettings,
    savingMessage: s.savingSettings,
    session: session,
    gameRepository: gameRepository,
    setupRepository: setupRepository,
    cartelaImporter: cartelaImporter,
    onBalanceChanged: onBalanceChanged,
    onIdentityUpdated: onIdentityUpdated,
  );

  if (context.isDesktop) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final insets = _PlayDesktopDialogInsets(ctx);
        return Dialog(
          alignment: Alignment.topRight,
          backgroundColor: BingoColors.surface,
          insetPadding: insets.padding,
          clipBehavior: Clip.antiAlias,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_settingsDialogRadius),
          ),
          child: SizedBox(
            width: 520,
            height: insets.availableHeight,
            child: shell,
          ),
        );
      },
    );
  }

  return showModalBottomSheet<void>(
    context: context,
    backgroundColor: BingoColors.surface,
    isScrollControlled: true,
    isDismissible: false,
    enableDrag: false,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
    ),
    builder: (ctx) => SizedBox(
      height: MediaQuery.sizeOf(ctx).height * 0.88,
      child: shell,
    ),
  );
}

class _PlaySetupPanelShell extends StatefulWidget {
  const _PlaySetupPanelShell({
    required this.title,
    required this.closeLabel,
    required this.saveLabel,
    required this.savingMessage,
    required this.session,
    required this.gameRepository,
    required this.setupRepository,
    required this.cartelaImporter,
    required this.onBalanceChanged,
    this.onIdentityUpdated,
  });

  final String title;
  final String closeLabel;
  final String saveLabel;
  final String savingMessage;
  final CashierSession session;
  final GameRepository gameRepository;
  final SetupRepository setupRepository;
  final CartelaImporter cartelaImporter;
  final Future<void> Function() onBalanceChanged;
  final void Function(CashierSession session)? onIdentityUpdated;

  @override
  State<_PlaySetupPanelShell> createState() => _PlaySetupPanelShellState();
}

class _PlaySetupPanelShellState extends State<_PlaySetupPanelShell> {
  final _panelKey = GlobalKey<PlaySetupPanelState>();
  bool _saving = false;

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await _panelKey.currentState?.savePendingChanges() ?? true;
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final desktop = context.isDesktop;
    final panel = PlaySetupPanel(
      key: _panelKey,
      session: widget.session,
      gameRepository: widget.gameRepository,
      setupRepository: widget.setupRepository,
      cartelaImporter: widget.cartelaImporter,
      onBalanceChanged: widget.onBalanceChanged,
      onIdentityUpdated: widget.onIdentityUpdated,
      saving: _saving,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _PlaySettingsHeader(
          title: widget.title,
          closeLabel: widget.closeLabel,
          saving: _saving,
          onClose: () => Navigator.pop(context),
          showDragHandle: !desktop,
          desktop: desktop,
        ),
        Expanded(
          child: AppLoadingOverlay(
            loading: _saving,
            message: widget.savingMessage,
            child: _SettingsScrollPane(child: panel),
          ),
        ),
        Padding(
          padding: EdgeInsets.fromLTRB(
            desktop ? 12 : 8,
            4,
            desktop ? 12 : 8,
            desktop ? 8 : 6,
          ),
          child: SizedBox(
            height: desktop ? 34 : 32,
            child: FilledButton(
              onPressed: _saving ? null : _save,
              style: FilledButton.styleFrom(
                backgroundColor: BingoColors.primary,
                padding: EdgeInsets.zero,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_settingsButtonRadius),
                ),
              ),
              child: _saving
                  ? const AppButtonLoader(color: Colors.white, size: 18)
                  : Text(
                      widget.saveLabel,
                      style: TextStyle(
                        fontSize: desktop ? 14 : 13,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Desktop play-dialog inset math aligned with [StartRoundModal] top gap.
class _PlayDesktopDialogInsets {
  _PlayDesktopDialogInsets(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final height = MediaQuery.sizeOf(context).height;
    final uiScale = math
        .min(width / 1100.0, height / 700.0)
        .clamp(1.0, 1.85);
    double scaled(double v) => v * uiScale;

    insetBottom = scaled(20.0);
    insetH = scaled(36.0);
    insetTop = (height * 0.025).clamp(scaled(12.0), scaled(32.0));
    insetRight = kDesktopPlayToolbarReservedWidth + 12;
    availableHeight = height - insetTop - insetBottom;
  }

  late final double insetTop;
  late final double insetH;
  late final double insetRight;
  late final double insetBottom;
  late final double availableHeight;

  EdgeInsets get padding =>
      EdgeInsets.fromLTRB(insetH, insetTop, insetRight, insetBottom);
}
