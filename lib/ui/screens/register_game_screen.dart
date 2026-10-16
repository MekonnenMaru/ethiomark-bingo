import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/bingo/bingo_patterns.dart';
import '../../core/config/app_currency.dart';
import '../../core/config/register_prefs.dart';
import '../../core/desktop/desktop_overlay_actions.dart';
import '../../core/performance/managed_loader.dart';
import '../../core/performance/resource_budget.dart';
import '../../core/trial/trial_prefs.dart';
import '../../core/trial/trial_service.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/l10n/locale_controller.dart';
import '../../data/models/cashier_profile.dart';
import '../../data/models/cashier_session.dart';
import '../../data/models/game_round.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/cartela_importer.dart';
import '../../data/repositories/game_repository.dart';
import '../layout/responsive_layout.dart';
import '../theme/bingo_colors.dart';
import '../widgets/app_loading.dart';
import '../widgets/app_toast.dart';
import '../widgets/font_size_controls.dart';
import '../widgets/trial_progress_banner.dart';
import '../widgets/staged_screen_content.dart';
import '../widgets/wallet_exceeded_alert.dart';

class RegisterGameScreen extends StatefulWidget {
  const RegisterGameScreen({
    super.key,
    required this.session,
    required this.gameRepository,
    required this.onRegistered,
    this.setupRepository,
    this.cartelaImporter,
    this.onBalanceChanged,
    this.onIdentityUpdated,
    this.onOpenReport,
  });

  final CashierSession session;
  final GameRepository gameRepository;
  final VoidCallback onRegistered;
  final SetupRepository? setupRepository;
  final CartelaImporter? cartelaImporter;
  final Future<void> Function()? onBalanceChanged;
  final void Function(CashierSession session)? onIdentityUpdated;
  final VoidCallback? onOpenReport;

  @override
  State<RegisterGameScreen> createState() => _RegisterGameScreenState();
}

class _RegisterGameScreenState extends State<RegisterGameScreen>
    with SingleTickerProviderStateMixin {
  static const _defaultFirstCardsCount = 10;
  static const _firstCardsStep = 5;
  static const _firstCardsMin = 5;
  static const _allCardsValue = -1;

  final _selected = <int>{};

  int _round = 1;
  int _totalCartelas = 200;
  int _price = 10;
  int _pattern = BingoPatterns.lineOne;
  int _firstCardsPick = _defaultFirstCardsCount;
  bool _loading = true;
  bool _saving = false;
  String? _error;
  String _packageBalance = '0';
  String _currencyCode = AppCurrency.defaultCode;
  int _trialRoundsUsed = 0;
  double _fontScale = RegisterPrefs.defaultFontScale;
  double _sidebarWidth = RegisterPrefs.defaultSidebarWidth;
  final _keyboardFocus = FocusNode();
  final _typedDigits = StringBuffer();
  final _firstCardsInputController = TextEditingController();
  final _numberSearchController = TextEditingController();
  String _typingPreview = '';
  late final AnimationController _hintBlinkController;
  late final Animation<double> _hintBlinkAnimation;

  static const _prices = [
    10,
    20,
    30,
    40,
    50,
    60,
    70,
    80,
    100,
    150,
    200,
    250,
    300,
    400,
    500,
    1000,
  ];

  @override
  void initState() {
    super.initState();
    _firstCardsInputController.text = '$_defaultFirstCardsCount';
    _numberSearchController.addListener(_onNumberSearchChanged);
    _hintBlinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    if (!ResourceBudget.reduceAnimations) {
      _hintBlinkController.repeat(reverse: true);
    }
    _hintBlinkAnimation = Tween<double>(begin: 0.35, end: 1.0).animate(
      CurvedAnimation(
        parent: _hintBlinkController,
        curve: Curves.easeInOut,
      ),
    );
    _load();
    _loadFontScale();
    _loadSidebarWidth();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (MediaQuery.sizeOf(context).width >= AppBreakpoints.desktop) {
        _keyboardFocus.requestFocus();
      }
    });
  }

  Future<void> _loadFontScale() async {
    final scale = await RegisterPrefs.loadFontScale();
    if (!mounted) return;
    setState(() => _fontScale = scale);
  }

  Future<void> _loadSidebarWidth() async {
    final width = await RegisterPrefs.loadSidebarWidth();
    if (!mounted) return;
    setState(() => _sidebarWidth = width);
  }

  Future<void> _changeFontScale(double delta) async {
    final next = (_fontScale + delta).clamp(
      RegisterPrefs.minFontScale,
      RegisterPrefs.maxFontScale,
    );
    setState(() => _fontScale = next);
    await RegisterPrefs.saveFontScale(next);
  }

  bool _registerBarSyncScheduled = false;
  DesktopOverlayActions? _desktopOverlay;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.isDesktop) {
      _desktopOverlay = context.read<DesktopOverlayActions>();
    }
  }

  void _scheduleRegisterBarSync() {
    if (!context.isDesktop || _registerBarSyncScheduled) return;
    _registerBarSyncScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _registerBarSyncScheduled = false;
      if (!mounted || !context.isDesktop) return;
      _desktopOverlay?.setRegisterBar(
        (ctx) => _buildDesktopMenuBarContent(
          ctx.watch<LocaleController>().strings,
        ),
      );
    });
  }

  @override
  void dispose() {
    _desktopOverlay?.clearRegisterBar();
    _hintBlinkController.dispose();
    _keyboardFocus.dispose();
    _firstCardsInputController.dispose();
    _numberSearchController.removeListener(_onNumberSearchChanged);
    _numberSearchController.dispose();
    super.dispose();
  }

  void _onNumberSearchChanged() {
    if (!mounted) return;
    setState(() {});
  }

  static const _cardScaleAmplifier = 2.0;

  List<int> _mobileFilteredNumbers() {
    final all = List.generate(_totalCartelas, (i) => i + 1);
    final query = _numberSearchController.text.trim();
    if (query.isEmpty) return all;
    return all.where((n) => n.toString().startsWith(query)).toList();
  }

  /// Cards grow/shrink faster than titles and other UI when zooming.
  double get _cardScale {
    final delta = _fontScale - RegisterPrefs.defaultFontScale;
    return (RegisterPrefs.defaultFontScale + delta * _cardScaleAmplifier)
        .clamp(0.55, 2.0);
  }

  /// Fewer columns on mobile → larger tap targets and numbers.
  int _mobileGridColumns(double gridWidth) {
    const horizontalPad = 8.0;
    const gap = 4.0;
    final minCell = 48.0 * _cardScale;
    final cols = ((gridWidth - horizontalPad) / (minCell + gap)).floor();
    return cols.clamp(5, 7);
  }

  bool get _trialActive => TrialService.isActiveTrial(
        packageBalance: _packageBalance,
        roundsUsed: _trialRoundsUsed,
      );

  bool get _trialExhausted => TrialService.isTrialExhausted(
        packageBalance: _packageBalance,
        roundsUsed: _trialRoundsUsed,
      );

  bool get _showTrialBanner => _trialActive || _trialExhausted;

  List<int> get _firstCardCountOptions {
    final options = <int>[];
    for (var n = _firstCardsMin; n <= _totalCartelas; n += _firstCardsStep) {
      options.add(n);
    }
    return options;
  }

  void _syncFirstCardsPick() {
    if (_firstCardsPick == _allCardsValue) return;

    final options = _firstCardCountOptions;
    if (options.isEmpty) {
      _firstCardsPick = _allCardsValue;
      return;
    }

    if (!options.contains(_firstCardsPick)) {
      _firstCardsPick = options.contains(_defaultFirstCardsCount)
          ? _defaultFirstCardsCount
          : options.first;
    }

    if (_firstCardsPick != _allCardsValue) {
      _firstCardsInputController.text = '$_firstCardsPick';
    }
  }

  void _selectFirstCards() {
    final count = _firstCardsPick == _allCardsValue
        ? _totalCartelas
        : _firstCardsPick.clamp(1, _totalCartelas);
    setState(() {
      _selected
        ..clear()
        ..addAll(List.generate(count, (i) => i + 1));
    });
  }

  String _firstCardsDropdownLabel(AppStrings s, int value) {
    if (value == _allCardsValue) return s.allCards;
    return '$value';
  }

  Future<void> _load() async {
    try {
      late final int round;
      late final int count;
      late final GameRound? draft;
      late final GameRound? lastRegistered;
      late final String packageBalance;
      late final int trialRoundsUsed;
      late final String currencyCode;

      if (ResourceBudget.sequentialScreenLoads) {
        final results = await ManagedLoader.runSequential([
          () => widget.gameRepository.resolveRoundNumber(widget.session.cashierId),
          () => widget.gameRepository.getCartelaCount(widget.session.category),
          () => widget.gameRepository.getIncompleteGame(widget.session.cashierId),
          () => widget.gameRepository.getLastRegisteredGame(widget.session.cashierId),
          () => widget.gameRepository.readPackageBalance(widget.session.cashierId),
          () => TrialPrefs.loadRoundsUsed(widget.session.cashierId),
          () => widget.gameRepository.getCashierProfile(widget.session.cashierId),
        ]);
        round = results[0] as int;
        count = results[1] as int;
        draft = results[2] as GameRound?;
        lastRegistered = results[3] as GameRound?;
        packageBalance = results[4] as String;
        trialRoundsUsed = results[5] as int;
        currencyCode = AppCurrency.fromSettings(
          (results[6] as CashierProfile).settings,
        );
      } else {
        final results = await Future.wait([
          widget.gameRepository.resolveRoundNumber(widget.session.cashierId),
          widget.gameRepository.getCartelaCount(widget.session.category),
          widget.gameRepository.getIncompleteGame(widget.session.cashierId),
          widget.gameRepository.getLastRegisteredGame(widget.session.cashierId),
          widget.gameRepository.readPackageBalance(widget.session.cashierId),
          TrialPrefs.loadRoundsUsed(widget.session.cashierId),
          widget.gameRepository.getCashierProfile(widget.session.cashierId),
        ]);
        round = results[0] as int;
        count = results[1] as int;
        draft = results[2] as GameRound?;
        lastRegistered = results[3] as GameRound?;
        packageBalance = results[4] as String;
        trialRoundsUsed = results[5] as int;
        currencyCode = AppCurrency.fromSettings(
          (results[6] as CashierProfile).settings,
        );
      }
      final trialActive = TrialService.isActiveTrial(
        packageBalance: packageBalance,
        roundsUsed: trialRoundsUsed,
      );

      if (!mounted) return;
      setState(() {
        _round = round;
        _totalCartelas = count > 0 ? count : 200;
        _packageBalance = packageBalance;
        _currencyCode = currencyCode;
        _trialRoundsUsed = trialRoundsUsed;
        _selected.clear();

        if (draft != null) {
          _selected.addAll(draft.cartelaNumbers);
          if (draft.price > 0) _price = draft.price;
          if (draft.pattern > 0) _pattern = draft.pattern;
        } else if (lastRegistered != null &&
            lastRegistered.roundNumber < round) {
          _selected.addAll(lastRegistered.cartelaNumbers);
          if (lastRegistered.price > 0) _price = lastRegistered.price;
          if (lastRegistered.pattern > 0) _pattern = lastRegistered.pattern;
        }

        if (trialActive) {
          _price = TrialService.trialStakeBirr;
          if (_selected.length > 1) {
            final first = _selected.toList()..sort();
            _selected
              ..clear()
              ..add(first.first);
          }
        }

        _loading = false;
        _error = null;
      });
      _syncFirstCardsPick();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load registration: $e';
      });
    }
  }

  void _clearSelection() => setState(_selected.clear);

  Future<void> _start() async {
    setState(() {
      _saving = true;
      _error = null;
    });

    final result = await widget.gameRepository.registerNewGameRound(
      cashierId: widget.session.cashierId,
      roundNumber: _round,
      selectedCards: _selected.toList()..sort(),
      price: _price,
      pattern: _pattern,
    );

    if (!mounted) return;

    setState(() => _saving = false);

    if (result['status'] == 'success') {
      showAppToast(context, '${result['message']}', type: AppToastType.success);
      widget.onRegistered();
    } else if (isWalletExceededResult(result) ||
        TrialService.isTrialExhaustedResult(result)) {
      final s = context.read<LocaleController>().strings;
      final balance =
          result['package'] as String? ?? widget.session.packageBalance;
      final message = TrialService.isTrialExhaustedResult(result)
          ? s.freeTrialExhaustedBody
          : s.transactionExceedsWallet(balance, _currencyCode);
      setState(() => _error = message);
      await showWalletExceededAlert(
        context,
        message: message,
        reportLabel: s.goToProfileAction,
        closeLabel: s.close,
        onOpenReport: widget.onOpenReport,
      );
    } else if (TrialService.isTrialRulesResult(result)) {
      final s = context.read<LocaleController>().strings;
      setState(() => _error = s.freeTrialRulesViolation(_currencyCode));
    } else {
      setState(() => _error = result['message'] as String?);
    }
  }

  void _toggle(int n) {
    if (n < 1 || n > _totalCartelas) return;
    setState(() {
      if (_trialActive) {
        if (_selected.contains(n)) {
          _selected.remove(n);
        } else {
          _selected
            ..clear()
            ..add(n);
        }
        return;
      }
      if (_selected.contains(n)) {
        _selected.remove(n);
      } else {
        _selected.add(n);
      }
    });
  }

  Future<void> _commitTypedNumber() async {
    final raw = _typedDigits.toString();
    _typedDigits.clear();
    _typingPreview = '';
    final n = int.tryParse(raw);
    if (n == null || n < 1 || n > _totalCartelas) {
      if (mounted) setState(() {});
      return;
    }

    if (_selected.contains(n)) {
      final unselect = await _confirmUnselectSelectedNumber(n);
      if (!mounted) return;
      if (unselect == true) {
        setState(() => _selected.remove(n));
      } else {
        setState(() {});
      }
      return;
    }

    _toggle(n);
    if (mounted) setState(() {});
  }

  Future<bool?> _confirmUnselectSelectedNumber(int n) async {
    final s = context.read<LocaleController>().strings;
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 340),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      '$n',
                      style: TextStyle(
                        color: BingoColors.lastCalled,
                        fontSize: 22,
                        fontWeight: FontWeight.w900,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        s.registeredNumberLabel,
                        style: const TextStyle(
                          color: BingoColors.columnNText,
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  s.numberAlreadyRegisteredUnselectQuestion,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: BingoColors.columnNText,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: FilledButton(
                        onPressed: () => Navigator.pop(dialogContext, true),
                        style: FilledButton.styleFrom(
                          backgroundColor: BingoColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          s.unselectYesLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: FilledButton(
                        autofocus: true,
                        onPressed: () => Navigator.pop(dialogContext, false),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFFE57373),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          s.unselectNoLabel,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        );
      },
    );
  }

  KeyEventResult _onKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;

    if (event.logicalKey == LogicalKeyboardKey.enter ||
        event.logicalKey == LogicalKeyboardKey.space) {
      unawaited(_commitTypedNumber());
      return KeyEventResult.handled;
    }

    if (event.logicalKey == LogicalKeyboardKey.backspace) {
      if (_typedDigits.isNotEmpty) {
        final text = _typedDigits.toString();
        _typedDigits.clear();
        _typedDigits.write(text.substring(0, text.length - 1));
        setState(() => _typingPreview = _typedDigits.toString());
      }
      return KeyEventResult.handled;
    }

    final char = event.character;
    if (char != null && RegExp(r'[0-9]').hasMatch(char)) {
      _typedDigits.write(char);
      setState(() => _typingPreview = _typedDigits.toString());
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().strings;
    if (_loading) {
      return AppLoadingView(message: s.loadingCards);
    }

    if (context.isDesktop) {
      _scheduleRegisterBarSync();
    }

    return AppLoadingOverlay(
      loading: _saving,
      message: s.registeringRound,
      child: context.isDesktop
          ? _buildDesktopLayout(context)
          : _buildMobileLayout(context),
    );
  }

  Widget _buildDesktopLayout(BuildContext context) {
    return Focus(
      focusNode: _keyboardFocus,
      onKeyEvent: _onKeyEvent,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const handleWidth = _RegisterSplitHandle.width;
            // Keep only a slim left strip so the divider can travel most of the way.
            const minCardPanelWidth = 260.0;
            final availableForSidebar =
                constraints.maxWidth - minCardPanelWidth - handleWidth;
            final maxSidebar = availableForSidebar.clamp(
              RegisterPrefs.minSidebarWidth,
              RegisterPrefs.maxSidebarWidth,
            );
            final sidebarWidth = _sidebarWidth.clamp(
              RegisterPrefs.minSidebarWidth,
              maxSidebar,
            );

            return StagedScreenRow(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              steps: [
                Expanded(child: _buildDesktopGridPanel(context)),
                _RegisterSplitHandle(
                  onDragDx: (dx) {
                    setState(() {
                      _sidebarWidth = (_sidebarWidth - dx).clamp(
                        RegisterPrefs.minSidebarWidth,
                        maxSidebar,
                      );
                    });
                  },
                  onDragEnd: () {
                    unawaited(RegisterPrefs.saveSidebarWidth(_sidebarWidth));
                  },
                ),
                SizedBox(
                  width: sidebarWidth,
                  child: _buildDesktopSidebar(),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildInlineTrialBanner({double? maxWidth, bool fullWidth = false}) {
    if (!_showTrialBanner) return const SizedBox.shrink();

    final banner = TrialProgressBanner(
      roundsUsed: _trialRoundsUsed,
      currencyCode: _currencyCode,
      minimal: true,
      exhausted: _trialExhausted,
      onOpenReport: widget.onOpenReport,
    );

    if (fullWidth) {
      return SizedBox(width: double.infinity, child: banner);
    }

    return ConstrainedBox(
      constraints: BoxConstraints(maxWidth: maxWidth ?? 260),
      child: banner,
    );
  }

  Widget _buildDesktopGridPanel(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_showTrialBanner) ...[
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _buildInlineTrialBanner(fullWidth: true),
          ),
        ],
        Expanded(
          child: GestureDetector(
            onTap: () => _keyboardFocus.requestFocus(),
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: 0.06),
                    Colors.black.withValues(alpha: 0.18),
                  ],
                ),
                border: Border.all(
                  color: BingoColors.accentTeal.withValues(alpha: 0.55),
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: BingoColors.accentTeal.withValues(alpha: 0.18),
                    blurRadius: 18,
                    spreadRadius: 1,
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: LayoutBuilder(
                  builder: (context, constraints) =>
                      _buildAdaptiveGrid(constraints),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Compact controls for the shell menu row (next to the hamburger).
  Widget _buildDesktopMenuBarContent(AppStrings s) {
    const gap = SizedBox(width: 16);
    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Text(
                s.roundShort(_round),
                style: TextStyle(
                  fontSize: (16 * _fontScale).clamp(14.0, 20.0),
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  height: 1.0,
                ),
              ),
              gap,
              Flexible(
                child: _buildBlinkingKeyboardHint(
                  fontSize: (11 * _fontScale).clamp(10.0, 13.0),
                  maxLines: 1,
                  textAlign: TextAlign.left,
                ),
              ),
              if (!_trialActive) ...[
                gap,
                _buildSelectFirstCardsControl(s, compact: true),
              ],
              if (_typingPreview.isNotEmpty) ...[
                gap,
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F2E50),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: BingoColors.accentTeal),
                  ),
                  child: Text(
                    s.typingLabel(_typingPreview),
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: (13 * _fontScale).clamp(12.0, 16.0),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(width: 12),
        FontSizeControls(
          scale: _fontScale,
          compact: true,
          dense: true,
          barHeight: 32,
          onDecrease: () => _changeFontScale(-RegisterPrefs.fontScaleStep),
          onIncrease: () => _changeFontScale(RegisterPrefs.fontScaleStep),
        ),
      ],
    );
  }

  Widget _buildAdaptiveGrid(BoxConstraints constraints) {
    const spacing = 8.0;
    const pad = 14.0;
    final cellBase = 58.0 * _cardScale;
    final cols = ((constraints.maxWidth - pad * 2 + spacing) / (cellBase + spacing))
        .floor()
        .clamp(6, 16);
    return GridView.builder(
      padding: const EdgeInsets.all(pad),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: cols,
        mainAxisSpacing: spacing,
        crossAxisSpacing: spacing,
        childAspectRatio: 1,
      ),
      itemCount: _totalCartelas,
      itemBuilder: (_, i) =>
          _desktopNumberBox(i + 1, _selected.contains(i + 1)),
    );
  }

  Widget _buildDesktopSidebar() {
    final s = context.watch<LocaleController>().strings;
    final sorted = _selected.toList()..sort();

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF1A3A4A), Color(0xFF0D2430)],
        ),
        border: Border.all(color: BingoColors.accentTeal.withValues(alpha: 0.45)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 18, 16, 10),
            child: Column(
              children: [
                Text(
                  sorted.isEmpty ? s.registerCards : s.selectedCardsTitle,
                  style: TextStyle(
                    fontSize: (sorted.isEmpty ? 22 : 26) * _fontScale,
                    fontWeight: FontWeight.w800,
                    color: sorted.isEmpty ? Colors.white : BingoColors.gold,
                    height: 1.15,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          Expanded(
            child: sorted.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.touch_app_outlined,
                            size: 42,
                            color: Colors.white.withValues(alpha: 0.35),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            s.emptySelectionHint,
                            style: TextStyle(
                              color: BingoColors.textSecondary,
                              fontSize: 15 * _fontScale,
                              height: 1.45,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  )
                : SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      alignment: WrapAlignment.center,
                      children: sorted.map((n) => _selectedChip(n)).toList(),
                    ),
                  ),
          ),
          Container(
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.22),
              border: Border(
                top: BorderSide(
                  color: BingoColors.accentTeal.withValues(alpha: 0.35),
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 44,
                        child: _priceDropdown(
                          s,
                          compact: false,
                          filled: true,
                          large: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 44,
                        child: _patternDropdown(
                          s,
                          compact: false,
                          filled: true,
                          large: true,
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Expanded(
                      flex: 1,
                      child: SizedBox(
                        height: 44,
                        child: OutlinedButton(
                          onPressed: _selected.isEmpty ? null : _clearSelection,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: const Color(0xFFBB191A),
                            disabledBackgroundColor:
                                const Color(0xFFBB191A).withValues(alpha: 0.35),
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: Text(
                            s.clear,
                            style: TextStyle(
                              fontSize: 18 * _fontScale,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: 44,
                        child: FilledButton(
                          onPressed: _saving ||
                                  _selected.isEmpty ||
                                  _trialExhausted
                              ? null
                              : _start,
                          style: FilledButton.styleFrom(
                            backgroundColor: BingoColors.accentTeal,
                            disabledBackgroundColor:
                                BingoColors.accentTeal.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                          ),
                          child: _saving
                              ? const AppButtonLoader(
                                  color: Colors.white,
                                  size: 22,
                                )
                              : Text(
                                  s.play,
                                  style: TextStyle(
                                    fontSize: 22 * _fontScale,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(
                    _error!,
                    style: const TextStyle(color: BingoColors.lastCalled),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    final s = context.watch<LocaleController>().strings;
    return DecoratedBox(
      decoration: BoxDecoration(gradient: BingoColors.registerMobileGradient),
      child: SafeArea(
        top: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(2, 2, 6, 0),
              child: _buildMobileHeaderSection(context, s),
            ),
            Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return _buildNumberGrid(
                    numbers: _mobileFilteredNumbers(),
                    columns: _mobileGridColumns(constraints.maxWidth),
                    boxSize: 0,
                    scrollable: true,
                  );
                },
              ),
            ),
            _buildMobileBottomControls(s),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  _error!,
                  style: const TextStyle(
                    color: BingoColors.lastCalled,
                    fontSize: 12,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSelectFirstCardsControl(AppStrings s, {required bool compact}) {
    if (_trialActive) return const SizedBox.shrink();

    final fieldHeight = compact ? 30.0 : 32.0;
    final dropdownWidth = compact ? 58.0 : 72.0;
    final iconSize = compact ? 18.0 : 20.0;
    final fontSize = compact ? 12 * _fontScale : 13 * _fontScale;
    final iconColor = BingoColors.gold;
    final tooltip =
        '${s.selectFirstCardsPrefix} ${s.selectFirstCardsSuffix}';
    final dropdownValues = [
      ..._firstCardCountOptions,
      _allCardsValue,
    ];
    final selectedValue = dropdownValues.contains(_firstCardsPick)
        ? _firstCardsPick
        : dropdownValues.first;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Tooltip(
          message: tooltip,
          child: Icon(
            Icons.filter_1_outlined,
            size: iconSize,
            color: iconColor,
          ),
        ),
        const SizedBox(width: 4),
        SizedBox(
          width: dropdownWidth,
          height: fieldHeight,
          child: DropdownButtonHideUnderline(
            child: DropdownButton<int>(
              value: selectedValue,
              isDense: true,
              isExpanded: true,
              dropdownColor: BingoColors.surface,
              icon: Icon(
                Icons.expand_more,
                color: BingoColors.gold,
                size: iconSize,
              ),
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.w800,
              ),
              items: dropdownValues
                  .map(
                    (value) => DropdownMenuItem(
                      value: value,
                      child: Text(
                        _firstCardsDropdownLabel(s, value),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (value) {
                if (value == null) return;
                setState(() {
                  _firstCardsPick = value;
                  if (value != _allCardsValue) {
                    _firstCardsInputController.text = '$value';
                  }
                });
              },
            ),
          ),
        ),
        const SizedBox(width: 4),
        Tooltip(
          message: s.selectFirstCardsApply,
          child: IconButton.filled(
            onPressed: _selectFirstCards,
            icon: Icon(Icons.done_rounded, size: iconSize),
            style: IconButton.styleFrom(
              backgroundColor: BingoColors.gold,
              foregroundColor: Colors.black,
              minimumSize: Size(fieldHeight, fieldHeight),
              maximumSize: Size(fieldHeight, fieldHeight),
              padding: EdgeInsets.zero,
              visualDensity: VisualDensity.compact,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(6),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBlinkingKeyboardHint({
    required double fontSize,
    bool lightText = false,
    int maxLines = 2,
    TextAlign textAlign = TextAlign.left,
  }) {
    final s = context.watch<LocaleController>().strings;
    Text hint(Color color) => Text(
          s.keyboardHint,
          maxLines: maxLines,
          overflow: TextOverflow.ellipsis,
          textAlign: textAlign,
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: color,
            height: 1.15,
          ),
        );

    if (ResourceBudget.reduceAnimations) {
      return hint(
        lightText
            ? BingoColors.registerMobileTextMuted
            : BingoColors.lastCalled,
      );
    }

    return AnimatedBuilder(
      animation: _hintBlinkAnimation,
      builder: (context, child) {
        final blinkColor = Color.lerp(
          BingoColors.lastCalled.withValues(alpha: 0.35),
          BingoColors.lastCalled,
          _hintBlinkAnimation.value,
        );
        return hint(
          lightText
              ? Color.lerp(
                  BingoColors.registerMobileTextMuted,
                  BingoColors.lastCalled,
                  _hintBlinkAnimation.value,
                )!
              : blinkColor!,
        );
      },
    );
  }

  Widget _buildMobileRoundChip(AppStrings s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF0F2E50),
            Color(0xFF165A72),
            Color(0xFF0F2E50),
          ],
        ),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: BingoColors.gold.withValues(alpha: 0.65),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: BingoColors.accentTeal.withValues(alpha: 0.15),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        s.roundShort(_round),
        style: TextStyle(
          fontSize: 13 * _fontScale.clamp(0.9, 1.1),
          fontWeight: FontWeight.w900,
          color: Colors.white,
          height: 1.1,
          shadows: const [
            Shadow(
              color: Color(0x664DD0E1),
              blurRadius: 4,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileNumberSearchField(AppStrings s) {
    final hasQuery = _numberSearchController.text.isNotEmpty;

    return SizedBox(
      height: 36,
      child: TextField(
        controller: _numberSearchController,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: TextStyle(
          color: Colors.white,
          fontSize: 12 * _fontScale,
          fontWeight: FontWeight.w600,
        ),
        decoration: InputDecoration(
          hintText: s.searchNumber,
          hintStyle: TextStyle(
            color: BingoColors.registerMobileTextMuted,
            fontSize: 12 * _fontScale,
            fontWeight: FontWeight.w500,
          ),
          filled: true,
          fillColor: const Color(0xFF0F2E50),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          prefixIcon: Icon(
            Icons.search,
            size: 18,
            color: BingoColors.registerMobileTextMuted,
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 34, minHeight: 34),
          suffixIcon: hasQuery
              ? IconButton(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.all(4),
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: Icon(
                    Icons.close_rounded,
                    size: 16,
                    color: BingoColors.registerMobileTextMuted,
                  ),
                  onPressed: () {
                    _numberSearchController.clear();
                  },
                )
              : null,
          suffixIconConstraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: BingoColors.accentTeal.withValues(alpha: 0.55),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(
              color: BingoColors.accentTeal.withValues(alpha: 0.55),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: BingoColors.accentTeal),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectedCountBadge() {
    final count = _selected.length;
    if (count == 0) return const SizedBox.shrink();

    final label = '$count';
    final digits = label.length;
    const badgeHeight = 26.0;
    final fontSize = digits == 1 ? 14.0 : (digits == 2 ? 13.0 : 12.0);
    final horizontalPad = digits == 1 ? 0.0 : 6.0;

    return Container(
      constraints: BoxConstraints(
        minWidth: badgeHeight,
        minHeight: badgeHeight,
      ),
      height: badgeHeight,
      padding: EdgeInsets.symmetric(horizontal: horizontalPad),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFBB191A),
        borderRadius: BorderRadius.circular(badgeHeight / 2),
        border: Border.all(color: Colors.white, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: Colors.white,
          fontSize: fontSize,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    );
  }

  Widget _buildMobileHeaderSection(BuildContext context, AppStrings s) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.all(4),
                constraints:
                    const BoxConstraints(minWidth: 40, minHeight: 40),
                icon: const Icon(Icons.menu, size: 22),
                color: BingoColors.gold,
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
              const SizedBox(width: 2),
              _buildMobileRoundChip(s),
              const SizedBox(width: 6),
              Expanded(child: _buildMobileNumberSearchField(s)),
              const SizedBox(width: 4),
              Tooltip(
                message: s.boardZoom,
                child: FontSizeControls(
                  scale: _fontScale,
                  compact: true,
                  dense: true,
                  onDecrease: () =>
                      _changeFontScale(-RegisterPrefs.fontScaleStep),
                  onIncrease: () =>
                      _changeFontScale(RegisterPrefs.fontScaleStep),
                ),
              ),
            ],
          ),
          if (_showTrialBanner) ...[
            const SizedBox(height: 4),
            _buildInlineTrialBanner(fullWidth: true),
          ],
        ],
      ),
    );
  }

  double _dropdownMenuMaxHeight(BuildContext context) {
    return MediaQuery.sizeOf(context).height * 0.7;
  }

  TextStyle _priceMenuItemStyle({bool mobile = false}) {
    return TextStyle(
      fontSize: (mobile ? 10.5 : 11.5) * _fontScale,
      fontWeight: FontWeight.w600,
      height: 1.0,
    );
  }

  List<DropdownMenuItem<int>> _priceDropdownItems(
    AppStrings s, {
    required bool compact,
    TextStyle? itemStyle,
  }) {
    final style = itemStyle ??
        TextStyle(
          fontSize: 12 * _fontScale,
          fontWeight: FontWeight.w600,
          height: 1.0,
        );
    return _prices
        .map(
          (p) => DropdownMenuItem(
            value: p,
            child: _patternMenuLabel(
              compact ? s.priceCompact(p, _currencyCode) : s.priceOption(p, _currencyCode),
              style,
            ),
          ),
        )
        .toList();
  }


  TextStyle _patternMenuItemStyle({bool mobile = false}) {
    return TextStyle(
      fontSize: (mobile ? 10.5 : 11.5) * _fontScale,
      fontWeight: FontWeight.w600,
      height: 1.0,
    );
  }

  Widget _patternMenuLabel(String text, TextStyle style) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        text,
        style: style,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  List<DropdownMenuItem<int>> _patternDropdownItems(
    AppStrings s, {
    TextStyle? itemStyle,
  }) {
    final style = itemStyle ??
        TextStyle(
          fontSize: 12 * _fontScale,
          fontWeight: FontWeight.w600,
          height: 1.1,
          color: Colors.white,
        );
    final items = <DropdownMenuItem<int>>[];
    for (final p in BingoPatterns.lineSelectionGroup) {
      items.add(
        DropdownMenuItem(
          value: p,
          child: _patternMenuLabel(s.patternName(p), style),
        ),
      );
    }
    items.add(
      const DropdownMenuItem(
        enabled: false,
        value: -1,
        child: Padding(
          padding: EdgeInsets.symmetric(vertical: 4),
          child: Divider(height: 1, thickness: 1),
        ),
      ),
    );
    for (final p in BingoPatterns.staticShapeGroup) {
      items.add(
        DropdownMenuItem(
          value: p,
          child: _patternMenuLabel(s.patternName(p), style),
        ),
      );
    }
    return items;
  }

  Widget _buildNumberGrid({
    required List<int> numbers,
    required int columns,
    required double boxSize,
    bool scrollable = false,
  }) {
    final grid = GridView.builder(
      padding: EdgeInsets.symmetric(
        horizontal: boxSize > 0 ? 12 : 4,
        vertical: boxSize > 0 ? 12 : 2,
      ),
      physics: scrollable ? null : const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        childAspectRatio: 1,
        mainAxisSpacing: boxSize > 0 ? 8 : 4,
        crossAxisSpacing: boxSize > 0 ? 8 : 4,
      ),
      itemCount: numbers.length,
      itemBuilder: (_, i) {
        final n = numbers[i];
        final selected = _selected.contains(n);
        if (boxSize > 0) {
          return _desktopNumberBox(n, selected, size: boxSize);
        }
        return _mobileNumberBox(n, selected);
      },
    );

    if (scrollable) return grid;
    return Center(child: grid);
  }

  Widget _desktopNumberBox(int n, bool selected, {double? size}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxSize = size ?? constraints.maxWidth;
        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _toggle(n),
            borderRadius: BorderRadius.circular(boxSize / 2),
            hoverColor: BingoColors.accentTeal.withValues(alpha: 0.2),
            child: Container(
              width: boxSize,
              height: boxSize,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: selected
                    ? const RadialGradient(
                        colors: [Color(0xFF000000), Color(0xFF899B04)],
                      )
                    : const RadialGradient(
                        colors: [
                          Color(0xFFFFFFFF),
                          Color(0xFFF7F7F7),
                          Color(0xFFDADADA),
                          Color(0xFF0C578E),
                        ],
                        stops: [0.0, 0.62, 0.82, 1.0],
                      ),
                border: Border.all(
                  color: selected ? const Color(0xFF899B04) : Colors.black54,
                  width: selected ? 2.5 : 1.4,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: selected ? 0.4 : 0.22),
                    blurRadius: selected ? 6 : 3,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              alignment: Alignment.center,
              child: Text(
                '$n',
                style: TextStyle(
                  fontSize: boxSize * 0.46,
                  fontWeight: FontWeight.w900,
                  color: selected ? Colors.white : Colors.black,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _mobileNumberBox(int n, bool selected) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cell = constraints.maxWidth;
        final fontSize = (cell * 0.48).clamp(14.0, 28.0);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _toggle(n),
            borderRadius: BorderRadius.circular(6),
            child: Container(
              margin: const EdgeInsets.all(1),
              decoration: BoxDecoration(
                color: selected
                    ? BingoColors.primary
                    : BingoColors.registerMobileCellBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: selected
                      ? BingoColors.primaryDark
                      : BingoColors.registerMobileCellBorder,
                  width: selected ? 1.5 : 1,
                ),
              ),
              alignment: Alignment.center,
              child: Text(
                '$n',
                style: TextStyle(
                  fontSize: fontSize,
                  color: selected ? Colors.white : BingoColors.registerMobileText,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _selectedChip(int n) {
    final size = 58.0 * _cardScale;
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: const RadialGradient(
            colors: [Colors.black, Color(0xFF5A6503)],
          ),
          border: Border.all(color: Colors.black, width: 2),
        ),
        child: Center(
          child: Text(
            '$n',
            style: TextStyle(
              fontSize: size * 0.38,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
        ),
      ),
    );
  }

  Widget _priceDropdown(
    AppStrings s, {
    required bool compact,
    bool filled = false,
    bool large = false,
  }) {
    return DropdownButtonFormField<int>(
      value: _price,
      isDense: true,
      isExpanded: true,
      menuMaxHeight: _dropdownMenuMaxHeight(context),
      style: TextStyle(
        fontSize: (large ? 15 : 12) * _fontScale,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        height: 1.0,
      ),
      decoration: InputDecoration(
        labelText: compact || large ? null : s.priceLabel(_currencyCode),
        floatingLabelBehavior: FloatingLabelBehavior.never,
        isCollapsed: large,
        labelStyle: TextStyle(
          color: Colors.white.withValues(alpha: 0.8),
          fontSize: (large ? 11 : 10) * _fontScale,
          height: 1,
        ),
        filled: filled,
        fillColor: filled ? const Color(0xFF0F2E50) : null,
        isDense: true,
        contentPadding: compact
            ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
            : EdgeInsets.symmetric(
                horizontal: 8,
                vertical: large ? 6 : 4,
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: BingoColors.accentTeal.withValues(alpha: 0.6),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(6),
          borderSide: BorderSide(
            color: BingoColors.accentTeal.withValues(alpha: 0.6),
          ),
        ),
      ),
      dropdownColor: BingoColors.surface,
      items: _priceDropdownItems(
        s,
        compact: compact,
        itemStyle: _priceMenuItemStyle(),
      ),
      onChanged: _trialActive ? null : (v) => setState(() => _price = v ?? 10),
    );
  }

  Widget _patternSelectedLabel(
    AppStrings s,
    int pattern, {
    required bool large,
  }) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        s.patternName(pattern),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: (large ? 15 : 12) * _fontScale,
          fontWeight: FontWeight.w700,
          color: Colors.white,
          height: 1.0,
        ),
      ),
    );
  }

  Widget _patternDropdown(
    AppStrings s, {
    required bool compact,
    bool filled = false,
    bool large = false,
  }) {
    return DropdownButtonFormField<int>(
      value: _pattern,
      isDense: true,
      isExpanded: true,
      menuMaxHeight: _dropdownMenuMaxHeight(context),
      style: TextStyle(
        fontSize: (large ? 15 : 12) * _fontScale,
        fontWeight: FontWeight.w700,
        color: Colors.white,
        height: 1.0,
      ),
      selectedItemBuilder: (context) {
        final widgets = <Widget>[];
        for (final p in BingoPatterns.lineSelectionGroup) {
          widgets.add(_patternSelectedLabel(s, p, large: large));
        }
        widgets.add(const SizedBox.shrink());
        for (final p in BingoPatterns.staticShapeGroup) {
          widgets.add(_patternSelectedLabel(s, p, large: large));
        }
        return widgets;
      },
      decoration: InputDecoration(
        isCollapsed: true,
        filled: false,
        isDense: true,
        contentPadding: compact
            ? const EdgeInsets.symmetric(horizontal: 4, vertical: 2)
            : EdgeInsets.symmetric(
                horizontal: 8,
                vertical: large ? 6 : 4,
              ),
        border: InputBorder.none,
        enabledBorder: InputBorder.none,
        focusedBorder: InputBorder.none,
      ),
      dropdownColor: BingoColors.surface,
      items: _patternDropdownItems(s, itemStyle: _patternMenuItemStyle()),
      onChanged: (v) => setState(() => _pattern = v ?? BingoPatterns.lineOne),
    );
  }

  Widget _scrollablePickerSheet(BuildContext ctx, List<Widget> children) {
    final maxHeight = MediaQuery.sizeOf(ctx).height * 0.55;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          children: children,
        ),
      ),
    );
  }

  Future<void> _showMobilePricePicker(AppStrings s) async {
    if (_trialActive) return;
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: BingoColors.surface,
      builder: (ctx) => _scrollablePickerSheet(
        ctx,
        _prices.map((p) {
          final selected = _price == p;
          return ListTile(
            dense: true,
            title: Text(
              s.priceOption(p, _currencyCode),
              style: TextStyle(
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? BingoColors.gold : BingoColors.textPrimary,
              ),
            ),
            onTap: () => Navigator.pop(ctx, p),
          );
        }).toList(),
      ),
    );
    if (picked != null) setState(() => _price = picked);
  }

  Future<void> _showMobilePatternPicker(AppStrings s) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: BingoColors.surface,
      builder: (ctx) => _scrollablePickerSheet(
        ctx,
        [
          ...BingoPatterns.lineSelectionGroup.map((p) {
            final selected = _pattern == p;
            return ListTile(
              dense: true,
              title: Text(
                s.patternCompact(p),
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              onTap: () => Navigator.pop(ctx, p),
            );
          }),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(height: 1),
          ),
          ...BingoPatterns.staticShapeGroup.map((p) {
            final selected = _pattern == p;
            return ListTile(
              dense: true,
              title: Text(
                s.patternCompact(p),
                style: TextStyle(
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              onTap: () => Navigator.pop(ctx, p),
            );
          }),
        ],
      ),
    );
    if (picked != null) setState(() => _pattern = picked);
  }

  Widget _mobileRegisterPickerField({
    required String value,
    required VoidCallback? onTap,
    bool highlightGold = false,
  }) {
    return Material(
      color: const Color(0xFF0F2E50),
      borderRadius: BorderRadius.circular(6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(6),
        child: Container(
          height: 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(5),
            border: Border.all(
              color: BingoColors.accentTeal.withValues(alpha: 0.6),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 3),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10 * _fontScale,
                    fontWeight:
                        highlightGold ? FontWeight.w800 : FontWeight.w700,
                    color: highlightGold ? BingoColors.gold : Colors.white,
                    height: 1,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_drop_down,
                color: BingoColors.gold.withValues(alpha: 0.9),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMobileBottomControls(AppStrings s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.22),
        border: Border(
          top: BorderSide(
            color: BingoColors.accentTeal.withValues(alpha: 0.35),
          ),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      s.amount,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.8),
                        fontSize: 8 * _fontScale,
                        fontWeight: FontWeight.w600,
                        height: 1,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _mobileRegisterPickerField(
                      value: s.priceCompact(_price, _currencyCode),
                      onTap: _trialActive
                          ? null
                          : () => _showMobilePricePicker(s),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: 2,
                child: _mobileRegisterPickerField(
                  value: s.patternCompact(_pattern),
                  onTap: () => _showMobilePatternPicker(s),
                  highlightGold: _pattern == BingoPatterns.lineOne,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: SizedBox(
                  height: 40,
                  child: OutlinedButton(
                    onPressed: _selected.isEmpty ? null : _clearSelection,
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: const Color(0xFFBB191A),
                      disabledBackgroundColor:
                          const Color(0xFFBB191A).withValues(alpha: 0.35),
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(6),
                      ),
                      padding: EdgeInsets.zero,
                    ),
                    child: Text(
                      s.clear,
                      style: TextStyle(
                        fontSize: 13 * _fontScale,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: SizedBox(
                  height: 40,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned.fill(
                        child: FilledButton(
                          onPressed: _saving ||
                                  _selected.isEmpty ||
                                  _trialExhausted
                              ? null
                              : _start,
                          style: FilledButton.styleFrom(
                            backgroundColor: BingoColors.accentTeal,
                            disabledBackgroundColor:
                                BingoColors.accentTeal.withValues(alpha: 0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(6),
                            ),
                            padding: EdgeInsets.zero,
                          ),
                          child: _saving
                              ? const AppButtonLoader(
                                  color: Colors.white,
                                  size: 20,
                                )
                              : Text(
                                  s.play,
                                  style: TextStyle(
                                    fontSize: 15 * _fontScale,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                        ),
                      ),
                      if (_selected.isNotEmpty)
                        Positioned(
                          top: -6,
                          right: -2,
                          child: _buildSelectedCountBadge(),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Draggable vertical splitter between the card grid and the right sidebar.
class _RegisterSplitHandle extends StatefulWidget {
  const _RegisterSplitHandle({
    required this.onDragDx,
    required this.onDragEnd,
  });

  /// Wide hit target so the divider is easy to grab.
  static const double width = 22;

  final ValueChanged<double> onDragDx;
  final VoidCallback onDragEnd;

  @override
  State<_RegisterSplitHandle> createState() => _RegisterSplitHandleState();
}

class _RegisterSplitHandleState extends State<_RegisterSplitHandle> {
  bool _hovering = false;
  bool _dragging = false;

  @override
  Widget build(BuildContext context) {
    final active = _hovering || _dragging;
    final lineColor = active
        ? BingoColors.gold
        : BingoColors.accentTeal.withValues(alpha: 0.75);

    return MouseRegion(
      cursor: SystemMouseCursors.resizeColumn,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onHorizontalDragStart: (_) => setState(() => _dragging = true),
        onHorizontalDragUpdate: (details) => widget.onDragDx(details.delta.dx),
        onHorizontalDragEnd: (_) {
          setState(() => _dragging = false);
          widget.onDragEnd();
        },
        onHorizontalDragCancel: () {
          setState(() => _dragging = false);
          widget.onDragEnd();
        },
        child: SizedBox(
          width: _RegisterSplitHandle.width,
          child: Center(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              width: active ? 6 : 4,
              margin: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: lineColor,
                borderRadius: BorderRadius.circular(3),
                boxShadow: active
                    ? [
                        BoxShadow(
                          color: BingoColors.gold.withValues(alpha: 0.45),
                          blurRadius: 6,
                        ),
                      ]
                    : null,
              ),
              child: Align(
                alignment: Alignment.center,
                child: Container(
                  width: 6,
                  height: 44,
                  decoration: BoxDecoration(
                    color: lineColor,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
