import 'dart:async';

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_currency.dart';
import '../../core/config/caller_voices.dart';
import '../../core/config/play_prefs.dart';
import '../../core/desktop/desktop_overlay_actions.dart';
import '../../core/config/cashier_defaults.dart';
import '../../core/bingo/bet_calculator.dart';
import '../../core/bingo/bingo_claim_mode.dart';
import '../../core/bingo/income_calculator.dart';
import '../../core/bingo/player_bonus.dart';
import '../../core/l10n/app_language.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/ui/modal_guard.dart';

import '../../data/models/cashier_profile.dart';

import '../../data/models/cashier_session.dart';

import '../../data/models/game_round.dart';

import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/cartela_importer.dart';
import '../../data/repositories/game_repository.dart';

import '../../core/performance/managed_loader.dart';
import '../../core/performance/resource_budget.dart';
import '../../services/sound_service.dart';

import '../layout/responsive_layout.dart';

import '../theme/bingo_colors.dart';

import '../widgets/app_loading.dart';
import '../widgets/blocked_action_tooltip.dart';
import '../widgets/bingo_ball.dart';

import '../widgets/bingo_board.dart';

import '../widgets/derash_box.dart';
import '../widgets/desktop_play_toolbar_controls.dart';
import '../widgets/play_pattern_box.dart';

import '../widgets/font_size_controls.dart';

import '../widgets/check_card_modal.dart';

import '../widgets/app_toast.dart';

import '../widgets/labeled_speed_slider.dart';

import '../widgets/play_controls_sheet.dart';
import '../widgets/player_bonus_claim_dialog.dart';
import '../widgets/staged_screen_content.dart';

import '../widgets/recent_calls_panel.dart';

import '../widgets/resume_game_notice_dialog.dart';
import '../widgets/start_round_modal.dart';

/// Shared height for play mobile top bar (menu, derash, zoom).
const _playMobileTopBarHeight = 44.0;

class PlayBingoScreen extends StatefulWidget {
  const PlayBingoScreen({
    super.key,

    required this.session,

    required this.gameRepository,

    required this.onFinished,

    required this.onBalanceChanged,

    required this.onEditRegistration,
    this.setupRepository,
    this.cartelaImporter,
    this.onIdentityUpdated,
    this.onOpenReport,
    this.onLogout,
    this.isActive = true,
  });

  final CashierSession session;

  final GameRepository gameRepository;

  final SetupRepository? setupRepository;

  final CartelaImporter? cartelaImporter;

  final VoidCallback onFinished;

  final Future<void> Function() onBalanceChanged;

  final void Function(CashierSession session)? onIdentityUpdated;

  final VoidCallback onEditRegistration;
  final VoidCallback? onOpenReport;
  final Future<void> Function()? onLogout;
  final bool isActive;

  @override
  State<PlayBingoScreen> createState() => _PlayBingoScreenState();
}

class _PlayBingoScreenState extends State<PlayBingoScreen> {
  GameRound? _game;

  bool _loading = true;

  bool _started = false;

  bool _drawing = false;

  bool _shuffling = false;

  Timer? _drawTimer;

  Timer? _shuffleTimer;

  Timer? _shuffleAutoStopTimer;

  /// Shuffle visual tick — slower than before to reduce UI load on weak PCs.
  static Duration get _shuffleTick => ResourceBudget.reduceAnimations
      ? const Duration(milliseconds: 320)
      : const Duration(milliseconds: 150);

  /// Used only if shuffle sound length cannot be read.
  static const _shuffleDurationFallback = Duration(seconds: 8);

  int? _shufflePreview;

  final _drawn = <int>[];
  final _drawnSet = <int>{};

  final _checkController = TextEditingController();

  String? _message;

  int _voiceIndex = CashierDefaults.callerVoice;

  int _goodBingoSound = CashierDefaults.goodBingoSound;

  int _drawInterval = 3;

  /// Matches ethiomark cashier slider: `min="1" max="15"` → `setInterval(..., value * 1000)`.
  static const _minDrawSpeed = 1;
  static const _maxDrawSpeed = 15;
  static const _defaultDrawSpeed = CashierDefaults.speedRange;

  static int _normalizeDrawSpeed(int? value) {
    if (value == null || value < _minDrawSpeed) return _defaultDrawSpeed;
    return value.clamp(_minDrawSpeed, _maxDrawSpeed);
  }

  int _cashierProfit = 0;

  double? _lockedRoundIncome;

  String _checkMode = CashierDefaults.checkMode;

  BingoClaimMode _bingoClaimMode = BingoClaimMode.noRestriction;

  String _currencyCode = AppCurrency.defaultCode;

  Map<String, dynamic> _settings = {};

  List<CommissionTier> _profitTiers = [];
  bool _usePartnerCommissionTiers = false;
  int _startGetMoneyFrom = 0;
  bool _allowIncomeRounding = false;
  bool _lockRoundUpLastDigit = false;

  bool _startedSound = true;

  bool _stoppedSound = true;
  bool _showCardCount = true;

  /// Player lucky-card bonus: offered after first Good Bingo until Claim.
  bool _bonusReady = false;
  bool _bonusLocked = false;
  List<int> _claimedLuckyCards = const [];
  int _claimedBonusAmount = 0;
  /// When true, win-pattern preview shows beside Derash on the play page.
  bool _showPatternOnPlay = true;
  bool _playToolbarUpdateScheduled = false;

  final _playFocusNode = FocusNode();

  double _boardZoom = PlayPrefs.defaultBoardZoom;

  late final bool Function(KeyEvent) _keyboardHandler;

  @override
  void initState() {
    super.initState();

    _keyboardHandler = _handleKeyboard;
    HardwareKeyboard.instance.addHandler(_keyboardHandler);

    _load();

    _loadBoardZoom();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _playFocusNode.requestFocus();
        _schedulePlayToolbarUpdate();
      }
    });
  }

  @override
  void didUpdateWidget(covariant PlayBingoScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isActive != widget.isActive) {
      _schedulePlayToolbarUpdate();
      if (widget.isActive && !_loading && _game != null) {
        _schedulePlayEntryExperience();
      }
    }
  }

  /// Start / resume modals on play entry.
  void _schedulePlayEntryExperience({bool showResumeNotice = false}) {
    if (!mounted || _loading || !widget.isActive) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      unawaited(_runPlayEntryExperience(showResumeNotice: showResumeNotice));
    });
  }

  Future<void> _runPlayEntryExperience({bool showResumeNotice = false}) async {
    if (!mounted || _loading || _game == null || !widget.isActive) return;
    if (!context.isDesktop) return;

    if (!_started) {
      if (!ModalGuard.isOpen(ModalKeys.startRound)) {
        await _showStartModal();
      }
      if (!mounted || !widget.isActive) return;
    }

    if (showResumeNotice && _started) {
      if (!ModalGuard.isOpen(ModalKeys.resumeGameNotice)) {
        await _showResumeGameNotice(
          roundNumber: _game!.roundNumber,
          calledCount: _drawn.length,
        );
      }
      if (!mounted || !widget.isActive) return;
    }
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_keyboardHandler);

    _playFocusNode.dispose();

    _drawTimer?.cancel();

    _shuffleTimer?.cancel();

    _shuffleAutoStopTimer?.cancel();

    _checkController.dispose();

    // Play toolbar is cleared by GameFlowScreen / MainShell when leaving play.
    // Do not call clearPlayToolbar() here — notifyListeners during dispose crashes.

    super.dispose();
  }

  Future<void> _loadBoardZoom() async {
    final zoom = await PlayPrefs.loadBoardZoom();
    if (!mounted) return;
    setState(() => _boardZoom = zoom);
  }

  Future<void> _load() async {
    final profile = await widget.gameRepository.getCashierProfile(
      widget.session.cashierId,
    );

    if (ResourceBudget.sequentialScreenLoads) await ManagedLoader.breathe();

    final game = await widget.gameRepository.getActivePlayGame(
      widget.session.cashierId,
    );

    var started = false;

    if (game != null) {
      if (game.result.isNotEmpty) {
        _drawn
          ..clear()
          ..addAll(game.result);
        _drawnSet
          ..clear()
          ..addAll(game.result);

        started = true;
      } else {
        _drawn.clear();
        _drawnSet.clear();
        if (ResourceBudget.sequentialScreenLoads) await ManagedLoader.breathe();
        started = await widget.gameRepository.hasTransactionForRound(
          widget.session.cashierId,

          game.roundNumber,
        );
      }
    } else {
      _drawn.clear();
      _drawnSet.clear();
    }

    if (!mounted) return;

    double? lockedIncome;
    if (game != null && started) {
      if (ResourceBudget.sequentialScreenLoads) await ManagedLoader.breathe();
      lockedIncome = await widget.gameRepository.getRoundLockedIncome(
        widget.session.cashierId,
        game.roundNumber,
      );
    }

    if (!mounted) return;

    final system = profile.settings['system'] as Map<String, dynamic>? ?? {};

    final toggles = profile.settings['toggles'] as Map<String, dynamic>? ?? {};

    final langCode = system['language'] as String?;
    if (langCode != null) {
      await context.read<LocaleController>().setLanguage(
        AppLanguage.fromCode(langCode),
      );
    }

    if (!mounted) return;

    setState(() {
      _game = game;

      _settings = Map<String, dynamic>.from(profile.settings);

      _voiceIndex = profile.sound;

      _drawInterval = _normalizeDrawSpeed(profile.speedRange);

      _cashierProfit = profile.cashierProfit;

      _goodBingoSound =
          int.tryParse('${system['good_bingo_sound']}') ??
          CashierDefaults.goodBingoSound;

      _checkMode = '${system['check_result'] ?? CashierDefaults.checkMode}';

      _bingoClaimMode = BingoClaimMode.fromSettings(system);

      _currencyCode = AppCurrency.fromSettings(profile.settings);

      _profitTiers = profile.profitTiers;
      _usePartnerCommissionTiers = profile.usePartnerCommissionTiers;
      _startGetMoneyFrom = profile.startGetMoneyFrom;
      _allowIncomeRounding = profile.allowIncomeRounding;

      _lockRoundUpLastDigit = profile.lockRoundUpLastDigit;

      _startedSound = toggles['started'] != false;

      _stoppedSound = toggles['stopped'] != false;

      _showCardCount = toggles['show_card_count'] != false;

      // Prefer new key; fall back to legacy modal toggle (treat as show on page).
      if (toggles.containsKey('show_pattern_on_play')) {
        _showPatternOnPlay = toggles['show_pattern_on_play'] == true;
      } else if (toggles.containsKey('show_pattern_on_start')) {
        _showPatternOnPlay = toggles['show_pattern_on_start'] == true;
      } else {
        _showPatternOnPlay = true;
      }

      _started = started;

      _lockedRoundIncome = lockedIncome;

      _bonusReady = false;
      _bonusLocked = false;
      _claimedLuckyCards = const [];
      _claimedBonusAmount = 0;

      _loading = false;
    });

    unawaited(SoundService.instance.preloadVoiceNumbers(_voiceIndex));

    if (game != null && started) {
      unawaited(_restorePlayerBonusState(game));
    }

    _schedulePlayToolbarUpdate();

    if (game != null && mounted && widget.isActive) {
      _schedulePlayEntryExperience(showResumeNotice: started);
    }
  }

  Future<void> _showResumeGameNotice({
    required int roundNumber,
    required int calledCount,
  }) async {
    if (!mounted || _game == null || !_started) return;

    final s = context.read<LocaleController>().strings;

    await ModalGuard.run<void>(
      ModalKeys.resumeGameNotice,
      () => showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogCtx) => ResumeGameNoticeDialog(
          strings: s,
          roundNumber: roundNumber,
          calledCount: calledCount,
        ),
      ),
    );
  }

  Future<void> _openPlayControls() async {
    if (_settingsBlockedReason(context.read<LocaleController>().strings) !=
        null) {
      return;
    }

    final applied = await openPlayControls(
      context,

      cashierId: widget.session.cashierId,

      gameRepository: widget.gameRepository,

      settings: _settings,

      goodBingoSound: _goodBingoSound,

      cashierProfit: _cashierProfit,

      bingoClaimMode: _bingoClaimMode,

      houseCutLocked: _started,

      session: widget.session,

      setupRepository: widget.setupRepository,

      cartelaImporter: widget.cartelaImporter,

      onBalanceChanged: widget.onBalanceChanged,

      onIdentityUpdated: widget.onIdentityUpdated,
    );

    if (applied == null || !mounted) return;

    _applyPlayPreferences(applied);
  }

  void _applyPlayPreferences(Map<String, dynamic> applied) {
    final wasDrawing = _drawing;

    setState(() {
      if (applied['voice'] != null) {
        _voiceIndex = applied['voice'] as int;
      }

      if (applied['speed'] != null) {
        _drawInterval = _normalizeDrawSpeed(applied['speed'] as int);
      }

      if (applied['checkMode'] != null) {
        _checkMode = applied['checkMode'] as String;
      }

      if (applied['goodSound'] != null) {
        _goodBingoSound = applied['goodSound'] as int;
      }

      if (applied['startedSound'] != null) {
        _startedSound = applied['startedSound'] as bool;
      }

      if (applied['stoppedSound'] != null) {
        _stoppedSound = applied['stoppedSound'] as bool;
      }

      if (applied['showCardCount'] != null) {
        _showCardCount = applied['showCardCount'] as bool;
      }

      if (applied['showPatternOnStart'] != null) {
        _showPatternOnPlay = applied['showPatternOnStart'] as bool;
      }

      if (applied['allowIncomeRounding'] != null) {
        _allowIncomeRounding = applied['allowIncomeRounding'] as bool;
      }

      final system = Map<String, dynamic>.from(
        _settings['system'] as Map<String, dynamic>? ?? {},
      );

      if (applied['checkMode'] != null) {
        system['check_result'] = _checkMode;
      }

      if (applied['goodSound'] != null) {
        system['good_bingo_sound'] = _goodBingoSound;
      }

      if (applied['currency'] != null) {
        system['currency'] = AppCurrency.normalize(applied['currency']);
        _currencyCode = AppCurrency.normalize(applied['currency']);
      }

      if (applied['language'] != null) {
        system['language'] = applied['language'];
      }

      _settings['system'] = system;

      if (applied['showCardCount'] != null ||
          applied['showPatternOnStart'] != null) {
        final toggles = Map<String, dynamic>.from(
          _settings['toggles'] as Map<String, dynamic>? ?? {},
        );
        if (applied['showCardCount'] != null) {
          toggles['show_card_count'] = _showCardCount;
        }
        if (applied['showPatternOnStart'] != null) {
          toggles['show_pattern_on_play'] = _showPatternOnPlay;
          toggles.remove('show_pattern_on_start');
        }
        _settings['toggles'] = toggles;
      }

      if (applied['allowIncomeRounding'] != null) {
        final systemRounding = Map<String, dynamic>.from(
          _settings['system'] as Map<String, dynamic>? ?? {},
        );
        systemRounding['income_rounding'] =
            _allowIncomeRounding ? 'on' : 'off';
        _settings['system'] = systemRounding;
      }
    });

    if (wasDrawing) _restartDrawTimer();
    _schedulePlayToolbarUpdate();
  }

  Future<void> _persistDrawInterval(int speed) async {
    final normalized = _normalizeDrawSpeed(speed);
    try {
      await widget.gameRepository.updatePlayPreferences(
        cashierId: widget.session.cashierId,
        currentSettings: _settings,
        speedRange: normalized,
      );
    } catch (_) {
      if (!mounted) return;
      showAppToast(
        context,
        context.read<LocaleController>().strings.couldNotSaveDrawSpeed,
        type: AppToastType.error,
      );
    }
  }

  Future<void> _persistCheckMode(String mode) async {
    if (mode == _checkMode) return;
    try {
      await widget.gameRepository.updatePlayPreferences(
        cashierId: widget.session.cashierId,
        currentSettings: _settings,
        checkMode: mode,
      );
      if (!mounted) return;
      setState(() {
        _checkMode = mode;
        final system = Map<String, dynamic>.from(
          _settings['system'] as Map<String, dynamic>? ?? {},
        );
        system['check_result'] = mode;
        _settings['system'] = system;
      });
    } catch (_) {
      if (!mounted) return;
      showAppToast(
        context,
        context.read<LocaleController>().strings.couldNotSaveDrawSpeed,
        type: AppToastType.error,
      );
    }
  }

  Future<void> _persistVoiceIndex(int voice) async {
    if (voice == _voiceIndex) return;
    try {
      await widget.gameRepository.updatePlayPreferences(
        cashierId: widget.session.cashierId,
        currentSettings: _settings,
        sound: voice,
      );
      if (!mounted) return;
      setState(() => _voiceIndex = voice);
      unawaited(SoundService.instance.preloadVoiceNumbers(voice));
    } catch (_) {
      if (!mounted) return;
      showAppToast(
        context,
        context.read<LocaleController>().strings.couldNotSaveDrawSpeed,
        type: AppToastType.error,
      );
    }
  }

  Duration get _drawGapDuration =>
      Duration(milliseconds: _normalizeDrawSpeed(_drawInterval) * 1000);

  /// Generation token so a stopped/restarted draw ignores late async callbacks.
  int _drawScheduleGen = 0;

  /// Speed = silence gap after each call sound ends before the next call starts.
  void _restartDrawTimer() {
    _drawTimer?.cancel();
    _drawTimer = null;
    if (!_drawing || _game == null) return;
    _drawScheduleGen++;
    _armNextDraw(_drawGapDuration);
  }

  void _armNextDraw(Duration delay) {
    _drawTimer?.cancel();
    if (!_drawing || _game == null) return;
    final wait = delay.isNegative ? Duration.zero : delay;
    final gen = _drawScheduleGen;
    _drawTimer = Timer(wait, () {
      if (!mounted || !_drawing || gen != _drawScheduleGen) return;
      unawaited(_drawNextAndSchedule(gen));
    });
  }

  Future<void> _drawNextAndSchedule(int gen) async {
    if (!mounted || !_drawing || gen != _drawScheduleGen) return;
    final soundDuration = await _drawNext();
    if (soundDuration == null) return;
    if (!mounted || !_drawing || gen != _drawScheduleGen) return;
    // Gap is after the voice finishes: sound length + N seconds silence.
    _armNextDraw(soundDuration + _drawGapDuration);
  }

  Future<void> _showStartModal() async {
    final game = _game;

    if (game == null || _started || !mounted) return;

    final ok = await showStartRoundModal(
      context: context,

      session: widget.session,

      game: game,

      gameRepository: widget.gameRepository,

      onEditCards: widget.onEditRegistration,

      onOpenReport: widget.onOpenReport,

      onLogout: widget.onLogout,

      onBalanceChanged: widget.onBalanceChanged,
    );

    if (!mounted) return;

    if (ok) {
      final locked = await widget.gameRepository.getRoundLockedIncome(
        widget.session.cashierId,
        game.roundNumber,
      );
      if (!mounted) return;
      setState(() {
        _started = true;
        _lockedRoundIncome = locked;
      });
    }
  }

  double _derashFor(GameRound game) {
    if (game.cardCount <= 0) return 0;
    if (_started && _lockedRoundIncome != null) {
      final bet = BetCalculator.totalBet(
        cardCount: game.cardCount,
        pricePerCard: game.price,
      );
      return IncomeCalculator.roundToMoney(bet - _lockedRoundIncome!);
    }
    return IncomeCalculator.calculateDerash(
      sew: game.cardCount,
      santim: game.price,
      cashierProfit: _cashierProfit,
      tiers: _profitTiers,
      usePartnerCommissionTiers: _usePartnerCommissionTiers,
      startGetMoneyFrom: _startGetMoneyFrom,
      allowIncomeRounding: _allowIncomeRounding,
      lockRoundUpLastDigit: _lockRoundUpLastDigit,
    );
  }

  Future<void> _toggleDraw() async {
    if (!mounted || _game == null || _shuffling) return;

    if (_drawing) {
      _drawScheduleGen++;
      _drawTimer?.cancel();
      _drawTimer = null;

      if (_stoppedSound) {
        unawaited(SoundService.instance.playDrawStop());
      }

      try {
        await widget.gameRepository.updateGameResult(
          widget.session.cashierId,
          _game!.roundNumber,
          _drawn,
        );
      } catch (_) {}

      if (!mounted) return;
      setState(() => _drawing = false);

      return;
    }

    if (!_started) {
      await _showStartModal();

      if (!_started || !mounted) return;
    }

    if (_startedSound) {
      unawaited(SoundService.instance.playDrawStart());
    }

    // Cache all number voices for this caller before/while drawing starts.
    unawaited(SoundService.instance.preloadVoiceNumbers(_voiceIndex));

    if (!mounted) return;
    setState(() => _drawing = true);
    _drawScheduleGen++;
    // First number after the gap (start sound can finish during this wait).
    _armNextDraw(_drawGapDuration);
  }

  /// Draws one number and plays its voice.
  /// Returns voice duration, or null when drawing should stop.
  Future<Duration?> _drawNext() async {
    if (!mounted) return null;

    final game = _game;

    if (game == null) return null;

    final pool = <int>[
      for (var n = 1; n <= 75; n++)
        if (!_drawnSet.contains(n)) n,
    ];

    if (pool.isEmpty) {
      unawaited(_toggleDraw());

      return null;
    }

    int? drawn;

    for (final n in game.firstDraw) {
      if (!_drawnSet.contains(n)) {
        drawn = n;

        break;
      }
    }

    drawn ??= (pool..shuffle(Random())).first;

    setState(() {
      _drawn.add(drawn!);
      _drawnSet.add(drawn);
    });

    final soundDuration = await SoundService.instance.playNumber(
      drawn,
      voiceIndex: _voiceIndex,
    );

    unawaited(
      widget.gameRepository.updateGameResult(
        widget.session.cashierId,
        game.roundNumber,
        _drawn,
      ),
    );
    return soundDuration;
  }

  void _toggleShuffle() {
    if (_game == null) return;

    if (_shuffling) {
      _stopShuffle(saveOrder: true);
      return;
    }

    if (_shuffleStartBlockedReason(context.read<LocaleController>().strings) !=
        null) {
      return;
    }

    unawaited(_beginShuffle());
  }

  Future<void> _beginShuffle() async {
    _shuffleTimer?.cancel();
    _shuffleAutoStopTimer?.cancel();

    if (!mounted) return;
    setState(() {
      _shuffling = true;
      _shufflePreview = Random().nextInt(75) + 1;
    });

    _shuffleTimer = Timer.periodic(_shuffleTick, (_) {
      if (!mounted) return;
      setState(() => _shufflePreview = Random().nextInt(75) + 1);
    });

    Duration duration;
    try {
      duration = await SoundService.instance.playShuffle();
    } catch (_) {
      duration = _shuffleDurationFallback;
    }
    if (!mounted || !_shuffling) return;

    final autoStop = duration.inMilliseconds > 0
        ? duration
        : _shuffleDurationFallback;

    _shuffleAutoStopTimer = Timer(autoStop, () {
      if (mounted && _shuffling) _stopShuffle(saveOrder: true);
    });
  }

  Future<void> _stopShuffle({required bool saveOrder}) async {
    _shuffleTimer?.cancel();

    _shuffleAutoStopTimer?.cancel();

    await SoundService.instance.stopShuffle();

    final game = _game;

    if (game != null && saveOrder) {
      final order = List<int>.generate(75, (i) => i + 1)..shuffle(Random());

      await widget.gameRepository.updateFirstDraw(
        widget.session.cashierId,

        game.roundNumber,

        order,
      );

      if (mounted) {
        setState(() {
          _game = GameRound(
            id: game.id,

            roundNumber: game.roundNumber,

            cartelaNumbers: game.cartelaNumbers,

            price: game.price,

            pattern: game.pattern,

            result: game.result,

            isCompleted: game.isCompleted,

            lockedCartelas: game.lockedCartelas,

            firstDraw: order,
          );
        });
      }
    }

    if (mounted) {
      setState(() {
        _shuffling = false;

        _shufflePreview = null;
      });
    }
  }

  Future<void> _checkCard() async {
    if (_checkBlockedReason(context.read<LocaleController>().strings) != null) {
      return;
    }

    final n = int.tryParse(_checkController.text.trim());

    if (n == null || _game == null) return;

    final result = await widget.gameRepository.checkCard(
      cashierId: widget.session.cashierId,

      roundNumber: _game!.roundNumber,

      cardNumber: n,

      drawnOverride: _drawn,

      claimMode: _bingoClaimMode,
    );

    if (result == null) {
      await SoundService.instance.playNotRegistered();

      if (mounted) {
        showAppToast(
          context,
          context.read<LocaleController>().strings.cardNotRegistered,
          type: AppToastType.error,
        );
      }

      return;
    }

    var checkResult = result;
    final auto = _checkMode == 'auto';

    if (auto) {
      if (checkResult.isLateClaim) {
        await SoundService.instance.playLateBingo();
        if (checkResult.locksOnLateClaim) {
          await widget.gameRepository.lockCartela(
            cashierId: widget.session.cashierId,
            roundNumber: _game!.roundNumber,
            cardNumber: n,
          );
          checkResult = checkResult.copyWith(isLocked: true);
          await SoundService.instance.playLockedCard();
        }
      } else if (checkResult.isLocked) {
        await SoundService.instance.playLockedCard();
      } else if (!checkResult.isWinner) {
        await SoundService.instance.playNotGood();
      }
    }

    if (!mounted) return;

    await showCheckCardModal(
      context: context,

      roundNumber: _game!.roundNumber,

      cardNumber: n,

      result: checkResult,

      drawn: _drawn,

      autoMode: auto,

      onGoodBingo: () async {
        await widget.gameRepository.saveCheckedNumber(
          cashierId: widget.session.cashierId,
          roundNumber: _game!.roundNumber,
          cardNumber: n,
        );

        await SoundService.instance.playGoodBingo(variant: _goodBingoSound);
        await _maybeOfferPlayerBonus();
        return _bonusReady && !_bonusLocked;
      },

      onLock: () async {
        await widget.gameRepository.lockCartela(
          cashierId: widget.session.cashierId,

          roundNumber: _game!.roundNumber,

          cardNumber: n,
        );

        await SoundService.instance.playLockedCard();
      },

      onNotBingo: () => SoundService.instance.playNotGood(),

      onTooLate: () async {
        await SoundService.instance.playLateBingo();
        if (checkResult.locksOnLateClaim && !checkResult.isLocked) {
          await widget.gameRepository.lockCartela(
            cashierId: widget.session.cashierId,
            roundNumber: _game!.roundNumber,
            cardNumber: n,
          );
          await SoundService.instance.playLockedCard();
        }
      },

      showBonusClaim: _bonusReady && !_bonusLocked,
      onClaimBonus: _claimPlayerBonusFromCheck,
      showBonusView: _canViewClaimedBonusCards,
      onViewBonusCards: _showClaimedBonusCards,
    );
  }

  bool get _canViewClaimedBonusCards =>
      _bonusLocked && _claimedLuckyCards.isNotEmpty;

  Future<void> _showClaimedBonusCards() async {
    if (!_canViewClaimedBonusCards || !mounted) return;
    final s = context.read<LocaleController>().strings;
    await showPlayerBonusClaimDialog(
      context: context,
      title: s.bonusLuckyTitle,
      amountLabel: s.prizeBonusLabel(_claimedBonusAmount),
      luckyCards: List<int>.from(_claimedLuckyCards),
      closeLabel: s.close,
      animate: false,
    );
  }

  Future<void> _restorePlayerBonusState(GameRound game) async {
    final existingBonus = await widget.gameRepository.getRoundBonusAmount(
      cashierId: widget.session.cashierId,
      roundNumber: game.roundNumber,
    );
    final saved = await PlayPrefs.loadBonusRoundState(
      cashierId: widget.session.cashierId,
      roundNumber: game.roundNumber,
    );
    final claim = await PlayPrefs.loadBonusClaimDetails(
      cashierId: widget.session.cashierId,
      roundNumber: game.roundNumber,
    );
    if (!mounted) return;

    if (existingBonus > 0 || saved == PlayerBonusRoundState.claimed) {
      setState(() {
        _bonusReady = false;
        _bonusLocked = true;
        _claimedLuckyCards = claim?.luckyCards ?? const [];
        _claimedBonusAmount =
            claim?.amount ?? existingBonus.round().clamp(0, 1000000);
      });
      return;
    }
    if (saved == PlayerBonusRoundState.skipped) {
      setState(() {
        _bonusReady = false;
        _bonusLocked = true;
        _claimedLuckyCards = const [];
        _claimedBonusAmount = 0;
      });
      return;
    }
    if (saved == PlayerBonusRoundState.ready) {
      setState(() {
        _bonusReady = true;
        _bonusLocked = false;
        _claimedLuckyCards = const [];
        _claimedBonusAmount = 0;
      });
    }
  }

  Future<void> _maybeOfferPlayerBonus() async {
    if (!mounted || _bonusReady || _bonusLocked || _game == null) return;

    final cfg = PlayerBonusSettings.fromSettings(_settings);
    if (!cfg.isEnabled) return;

    final game = _game!;
    final totalBet = BetCalculator.totalBet(
      cardCount: game.cardCount,
      pricePerCard: game.price,
    );
    if (totalBet < cfg.minBet) return;

    final awardsToday = await widget.gameRepository.countTodayBonusAwards(
      widget.session.cashierId,
    );
    if (!mounted) return;

    final allowed = cfg.scheduleAllowsOffer(
      roundNumber: game.roundNumber,
      awardsToday: awardsToday,
    );
    if (!allowed) return;

    await PlayPrefs.saveBonusRoundState(
      cashierId: widget.session.cashierId,
      roundNumber: game.roundNumber,
      state: PlayerBonusRoundState.ready,
    );
    if (!mounted) return;
    setState(() {
      _bonusReady = true;
      _bonusLocked = false;
    });
  }

  Future<void> _claimPlayerBonus() async {
    if (!_bonusReady || _bonusLocked || _game == null) return;
    final s = context.read<LocaleController>().strings;
    final game = _game!;
    final cfg = PlayerBonusSettings.fromSettings(_settings);

    final awardsToday = await widget.gameRepository.countTodayBonusAwards(
      widget.session.cashierId,
    );
    if (!mounted) return;
    if (!cfg.hasDailyQuotaRemaining(awardsToday)) {
      await PlayPrefs.saveBonusRoundState(
        cashierId: widget.session.cashierId,
        roundNumber: game.roundNumber,
        state: PlayerBonusRoundState.skipped,
      );
      if (!mounted) return;
      setState(() {
        _bonusReady = false;
        _bonusLocked = true;
        _claimedLuckyCards = const [];
        _claimedBonusAmount = 0;
      });
      showAppToast(
        context,
        s.bonusDailyLimitReached,
        type: AppToastType.warning,
      );
      return;
    }

    final result = await widget.gameRepository.claimPlayerBonus(
      cashierId: widget.session.cashierId,
      roundNumber: game.roundNumber,
      registeredCards: game.cartelaNumbers,
      settings: _settings,
    );
    if (!mounted) return;

    if (result.skipped) {
      await PlayPrefs.saveBonusRoundState(
        cashierId: widget.session.cashierId,
        roundNumber: game.roundNumber,
        state: PlayerBonusRoundState.skipped,
      );
      if (!mounted) return;
      setState(() {
        _bonusReady = false;
        _bonusLocked = true;
        _claimedLuckyCards = const [];
        _claimedBonusAmount = 0;
      });
      showAppToast(
        context,
        s.bonusSkippedNoPlayers,
        type: AppToastType.warning,
      );
      return;
    }

    await PlayPrefs.saveBonusClaimDetails(
      cashierId: widget.session.cashierId,
      roundNumber: game.roundNumber,
      luckyCards: result.luckyCards,
      amount: result.amount,
    );
    await PlayPrefs.saveBonusRoundState(
      cashierId: widget.session.cashierId,
      roundNumber: game.roundNumber,
      state: PlayerBonusRoundState.claimed,
    );
    if (!mounted) return;
    setState(() {
      _bonusReady = false;
      _bonusLocked = true;
      _claimedLuckyCards = List<int>.from(result.luckyCards);
      _claimedBonusAmount = result.amount;
    });

    // Spin overlay plays Anbesa-style ticks + win chime; keep hall celebration after.
    await showPlayerBonusClaimDialog(
      context: context,
      title: s.bonusLuckyTitle,
      amountLabel: s.prizeBonusLabel(result.amount),
      luckyCards: result.luckyCards,
      closeLabel: s.close,
      spinningKicker: s.bonusSpinningKicker,
      spinningTitle: s.bonusSpinningTitle,
      revealedTitle: s.bonusRevealedTitle,
      spinPool: game.cartelaNumbers,
      animate: true,
    );
    if (!mounted) return;
    unawaited(SoundService.instance.playGoodBingo(variant: _goodBingoSound));
    showAppToast(context, s.bonusClaimedToast, type: AppToastType.success);
  }

  /// Used by check-card modal: true when lucky cards were awarded.
  Future<bool> _claimPlayerBonusFromCheck() async {
    await _claimPlayerBonus();
    return _canViewClaimedBonusCards;
  }

  Future<void> _finish() async {
    if (_finishBlockedReason(context.read<LocaleController>().strings) !=
            null ||
        _game == null) {
      return;
    }

    try {
      final res = await widget.gameRepository.completeGame(
        cashierId: widget.session.cashierId,
        roundNumber: _game!.roundNumber,
      );

      if (!mounted) return;

      if (res['status'] == 'success') {
        widget.onFinished();
        return;
      }

      setState(() => _message = res['message'] as String?);
    } catch (e) {
      if (!mounted) return;
      final s = context.read<LocaleController>().strings;
      setState(() => _message = s.couldNotLoadGame('$e'));
    }
  }

  int? get _displayNumber {
    if (_shufflePreview != null) return _shufflePreview;

    if (_drawn.isNotEmpty) return _drawn.last;

    return null;
  }

  bool _canCheckCard(AppStrings s) => _checkBlockedReason(s) == null;

  bool _canShuffle(AppStrings s) =>
      _shuffling || _shuffleStartBlockedReason(s) == null;

  bool _canFinish(AppStrings s) => _finishBlockedReason(s) == null;

  bool _canBingo(AppStrings s) => _bingoBlockedReason(s) == null;

  bool _canOpenSettings(AppStrings s) => _settingsBlockedReason(s) == null;

  String? _bingoBlockedReason(AppStrings s) {
    if (_shuffling) return s.shufflingBlocked;

    return null;
  }

  String? _settingsBlockedReason(AppStrings s) {
    if (_shuffling) return s.shufflingBlocked;

    return null;
  }

  String? _checkBlockedReason(AppStrings s) {
    if (!_started) return s.startBeforeCheck;
    if (_drawing) return s.stopBeforeCheck;
    if (_shuffling) return s.shufflingBlocked;

    return null;
  }

  String? _shuffleStartBlockedReason(AppStrings s) {
    if (!_started) return s.startBeforeShuffle;
    if (_drawing) return s.stopBeforeShuffle;

    return null;
  }

  String? _finishBlockedReason(AppStrings s) {
    if (!_started) return s.startBeforeFinish;
    if (_drawing) return s.stopBeforeFinish;
    if (_shuffling) return s.shufflingBlocked;
    if (_drawn.isEmpty) return s.playBeforeFinish;

    return null;
  }

  Widget _blockedTooltip({
    required String? reason,
    required Widget child,
    bool showHint = true,
  }) {
    if (reason == null) return child;
    if (!showHint) {
      return Opacity(
        opacity: 0.45,
        child: AbsorbPointer(child: child),
      );
    }
    return BlockedActionTooltip(
      reason: reason,
      child: child,
    );
  }

  Widget _playButtonLabel({
    required String title,
    String? enabledHint,
    String? disabledHint,
    required bool enabled,
    required double titleSize,
    required Color titleColor,
    Color? hintColor,
    double hintSize = 9,
    FontWeight titleWeight = FontWeight.w900,
  }) {
    final hint = enabled ? enabledHint : disabledHint;
    final resolvedHintColor = hintColor ??
        (enabled
            ? titleColor
            : BingoColors.lastCalled);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: titleSize,
              fontWeight: titleWeight,
              color: titleColor,
              letterSpacing: titleSize >= 20 ? 1 : 0,
              height: 1,
            ),
          ),
          if (hint != null && hint.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              hint,
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: hintSize,
                fontWeight: FontWeight.w800,
                color: resolvedHintColor,
                height: 1.1,
                shadows: const [
                  Shadow(
                    color: Color(0x99000000),
                    blurRadius: 3,
                    offset: Offset(0, 1),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  String? _bingoSpaceHint(AppStrings s) {
    if (!_canBingo(s)) return null;

    return _drawing ? s.spaceToStop : s.spaceToStart;
  }

  bool _handleKeyboard(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (event.logicalKey != LogicalKeyboardKey.space) return false;
    if (!mounted || !widget.isActive || _loading || _game == null) return false;
    if (_isKeyboardBlockedByOverlay()) return false;
    if (_bingoBlockedReason(context.read<LocaleController>().strings) != null) {
      return false;
    }

    unawaited(_toggleDraw());

    return true;
  }

  /// Space must not start/stop draw under check-card or sheets.
  bool _isKeyboardBlockedByOverlay() {
    final route = ModalRoute.of(context);
    if (route != null && !route.isCurrent) return true;

    final ctx = FocusManager.instance.primaryFocus?.context;
    if (ctx == null) return false;

    return ctx.findAncestorWidgetOfExactType<Dialog>() != null ||
        ctx.findAncestorWidgetOfExactType<BottomSheet>() != null;
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().strings;

    if (_loading) {
      return AppLoadingView(message: s.loadingRound);
    }

    final game = _game;

    if (game == null) {
      return AppLoadingView(message: s.preparingGame);
    }

    final display = _displayNumber;

    final derash = _derashFor(game);

    final body = context.isDesktop
        ? _buildDesktopLayout(context, s, game, display, derash)
        : _buildMobileLayout(context, s, game, display, derash);

    return Focus(
      focusNode: _playFocusNode,
      autofocus: true,
      child: body,
    );
  }

  /// ethiomark `cashier/index.php` — ball + recent calls + derash top row, horizontal board, setting_box.

  Widget _buildDesktopLayout(
    BuildContext context,
    AppStrings s,
    GameRound game,
    int? display,
    double derash,
  ) {
    return StagedScreenContent(
      steps: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 6, 8, 0),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  flex: 2,
                  child: Center(
                    child: BingoBall(
                      number: display,
                      shuffling: _shuffling,
                      showBingoLetter: true,
                    ),
                  ),
                ),
                Expanded(
                  flex: 3,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: RecentCallsPanel(
                      roundNumber: game.roundNumber,
                      drawn: _drawn,
                      callSpeedSeconds: _drawInterval,
                    ),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: kDesktopPlayToolbarReservedWidth,
                    ),
                    child: game.cardCount > 0
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                flex: _showPatternOnPlay ? 3 : 1,
                                child: Align(
                                  alignment: Alignment.topCenter,
                                  child: FractionallySizedBox(
                                    widthFactor: _showPatternOnPlay ? 0.9 : 1,
                                    child: DerashBox(
                                      derashAmount: derash,
                                      cardCount: game.cardCount,
                                      callCount: _drawn.length,
                                      currencyCode: _currencyCode,
                                      compact: false,
                                      showCardCount: _showCardCount,
                                    ),
                                  ),
                                ),
                              ),
                              if (_showPatternOnPlay) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: PlayPatternBox(
                                    pattern: game.pattern,
                                  ),
                                ),
                              ],
                            ],
                          )
                        : const SizedBox.shrink(),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _buildBoardSection(context, s, display)),
                if (_message != null) ...[
                  const SizedBox(height: 8),
                  Text(_message!, textAlign: TextAlign.center),
                ],
              ],
            ),
          ),
        ),
        _buildDesktopControls(context, s),
      ],
    );
  }

  Widget _buildMobileLayout(
    BuildContext context,
    AppStrings s,
    GameRound game,
    int? display,
    double derash,
  ) {
    return StagedScreenContent(
      steps: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: SizedBox(
            height: _playMobileTopBarHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: _playMobileTopBarHeight,
                  height: _playMobileTopBarHeight,
                  child: IconButton(
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
                    icon: const Icon(Icons.menu, size: 22),
                    color: BingoColors.gold,
                    onPressed: () => Scaffold.of(context).openDrawer(),
                  ),
                ),
                if (game.cardCount > 0) ...[
                  const SizedBox(width: 2),
                  Expanded(
                    flex: _showPatternOnPlay ? 3 : 1,
                    child: DerashBox(
                      derashAmount: derash,
                      cardCount: game.cardCount,
                      callCount: _drawn.length,
                      currencyCode: _currencyCode,
                      mobileTopBar: true,
                      barHeight: _playMobileTopBarHeight,
                      showCardCount: _showCardCount,
                    ),
                  ),
                  if (_showPatternOnPlay) ...[
                    const SizedBox(width: 4),
                    Expanded(
                      flex: 2,
                      child: SizedBox(
                        height: _playMobileTopBarHeight,
                        child: PlayPatternBox(
                          pattern: game.pattern,
                          compact: true,
                        ),
                      ),
                    ),
                  ],
                ] else
                  const Spacer(),
                const SizedBox(width: 4),
                Tooltip(
                  message: s.boardZoom,
                  child: FontSizeControls(
                    scale: _boardZoom,
                    compact: true,
                    dense: true,
                    barHeight: _playMobileTopBarHeight,
                    minScale: PlayPrefs.minBoardZoom,
                    maxScale: PlayPrefs.maxBoardZoom,
                    onDecrease: () =>
                        _changeBoardZoom(-PlayPrefs.boardZoomStep),
                    onIncrease: () =>
                        _changeBoardZoom(PlayPrefs.boardZoomStep),
                  ),
                ),
              ],
            ),
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 2),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildBoardSection(context, s, display),
                if (_message != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _message!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
        SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildMobileControls(context, s),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _changeBoardZoom(double delta) async {
    final next = (_boardZoom + delta).clamp(
      PlayPrefs.minBoardZoom,
      PlayPrefs.maxBoardZoom,
    );
    if (next == _boardZoom) return;
    setState(() => _boardZoom = next);
    _schedulePlayToolbarUpdate();
    await PlayPrefs.saveBoardZoom(next.toDouble());
  }

  void _schedulePlayToolbarUpdate([AppStrings? strings]) {
    if (!mounted || !context.isDesktop) return;
    if (_playToolbarUpdateScheduled) return;
    _playToolbarUpdateScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _playToolbarUpdateScheduled = false;
      if (!mounted || !context.isDesktop) return;
      final s = strings ?? context.read<LocaleController>().strings;
      if (widget.isActive && !_loading && _game != null) {
        _syncDesktopPlayToolbar(s);
      } else {
        context.read<DesktopOverlayActions>().clearPlayToolbar();
      }
    });
  }

  void _syncDesktopPlayToolbar(AppStrings s) {
    context.read<DesktopOverlayActions>().setPlayToolbar(
          DesktopPlayToolbarState(
            boardZoom: _boardZoom,
            minBoardZoom: PlayPrefs.minBoardZoom,
            maxBoardZoom: PlayPrefs.maxBoardZoom,
            zoomTooltip: s.boardZoom,
            onZoomDecrease: () =>
                _changeBoardZoom(-PlayPrefs.boardZoomStep),
            onZoomIncrease: () => _changeBoardZoom(PlayPrefs.boardZoomStep),
            settingsLabel: s.settings,
            settingsEnabled: _canOpenSettings(s),
            onOpenSettings: _openPlayControls,
            showControlsLabel: s.showControls,
            hideControlsLabel: s.hideControls,
            settingsBlockedReason: _settingsBlockedReason(s),
          ),
        );
  }

  Widget _buildBoardSection(BuildContext context, AppStrings s, int? display) {
    final horizontal = context.isDesktop ? 80.0 : 28.0;
    return Align(
      alignment: Alignment.center,
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: horizontal),
        child: BingoBoard(
          calledNumbers: _drawnSet,
          lastCalled: display,
          shuffleHighlight: _shuffling,
          zoom: _boardZoom,
        ),
      ),
    );
  }

  /// ethiomark `.setting_box` — large Bingo / Shuffle / Finish buttons.

  /// Desktop bottom bar dropdown width: longest option label + icon slot (no side padding).
  double _desktopBottomDropdownWidth(
    BuildContext context,
    List<String> labels,
  ) {
    const style = TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
    );
    final textDirection = Directionality.of(context);
    double maxTextWidth = 0;
    for (final label in labels) {
      final painter = TextPainter(
        text: TextSpan(text: label, style: style),
        textDirection: textDirection,
        maxLines: 1,
      )..layout();
      if (painter.width > maxTextWidth) maxTextWidth = painter.width;
    }
    return maxTextWidth + 24;
  }

  Widget _buildDesktopControls(BuildContext context, AppStrings s) {
    final checkDropdownWidth = _desktopBottomDropdownWidth(
      context,
      [s.manual, s.automatic],
    );
    final soundDropdownWidth = _desktopBottomDropdownWidth(
      context,
      kCallerVoiceOptions.map((option) => option.label).toList(),
    );
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 4, 8, 4),

      decoration: BoxDecoration(
        color: BingoColors.bgDark,

        border: const Border(top: BorderSide(color: BingoColors.border)),
      ),

      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            height: 64,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(child: _bingoButton(s, desktop: true)),
                const SizedBox(width: 6),
                SizedBox(
                  width: 96,
                  child: _shuffleButton(s, desktop: true, compact: true),
                ),
                const SizedBox(width: 6),
                SizedBox(
                  width: 96,
                  child: _finishButton(s, desktop: true, compact: true),
                ),
                if (_canViewClaimedBonusCards) ...[
                  const SizedBox(width: 6),
                  SizedBox(
                    width: 118,
                    child: _viewBonusCardsButton(s, desktop: true),
                  ),
                ],
                const Spacer(),
                SizedBox(
                  height: 64,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                    SizedBox(
                      width: 152,
                      child: _buildCheckCardControl(s),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: checkDropdownWidth,
                      child: _desktopBottomLabeledField(
                        label: s.checkResult,
                        compactLabel: true,
                        child: _desktopBottomDropdown<String>(
                          context: context,
                          compact: true,
                          value: _checkMode == 'auto' ? 'auto' : 'manual',
                          items: [
                            DropdownMenuItem(
                              value: 'manual',
                              child: Text(s.manual),
                            ),
                            DropdownMenuItem(
                              value: 'auto',
                              child: Text(s.automatic),
                            ),
                          ],
                          selectedItemBuilder: (context) => [
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                s.manual,
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: BingoColors.textPrimary,
                                ),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                s.automatic,
                                maxLines: 1,
                                style: const TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  color: BingoColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                          onChanged: (v) {
                            if (v != null) _persistCheckMode(v);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: soundDropdownWidth,
                      child: _desktopBottomLabeledField(
                        label: s.sound,
                        compactLabel: true,
                        child: _desktopBottomDropdown<int>(
                          context: context,
                          compact: true,
                          value: normalizeCallerVoiceIndex(_voiceIndex),
                          items: kCallerVoiceOptions
                              .map(
                                (option) => DropdownMenuItem(
                                  value: option.soundIndex,
                                  child: Text(option.label),
                                ),
                              )
                              .toList(),
                          selectedItemBuilder: (context) {
                            return kCallerVoiceOptions
                                .map(
                                  (option) => Align(
                                    alignment: Alignment.centerLeft,
                                    child: Text(
                                      option.label,
                                      maxLines: 1,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: BingoColors.textPrimary,
                                      ),
                                    ),
                                  ),
                                )
                                .toList();
                          },
                          onChanged: (v) {
                            if (v != null) _persistVoiceIndex(v);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 212,
                      child: SizedBox(
                        height: 64,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Text(
                              '${s.speed} · ${_drawInterval}s',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: BingoColors.gold,
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                height: 1.1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Expanded(
                              child: Align(
                                alignment: Alignment.center,
                                child: LabeledSpeedSlider(
                                  value: _drawInterval.toDouble(),
                                  label: '${_drawInterval}s',
                                  min: _minDrawSpeed.toDouble(),
                                  max: _maxDrawSpeed.toDouble(),
                                  divisions: _maxDrawSpeed - _minDrawSpeed,
                                  thumbRadius: 18,
                                  trackHeight: 6,
                                  onChanged: (v) {
                                    final speed = v.round();
                                    setState(() => _drawInterval = speed);
                                    if (_drawing) _restartDrawTimer();
                                  },
                                  onChangeEnd: (v) =>
                                      _persistDrawInterval(v.round()),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        ],
      ),
    );
  }

  Widget _desktopBottomLabeledField({
    required String label,
    required Widget child,
    bool compactLabel = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: BingoColors.gold,
            fontSize: compactLabel ? 10 : 11,
            fontWeight: FontWeight.w700,
            height: 1.0,
          ),
        ),
        SizedBox(height: compactLabel ? 3 : 4),
        Expanded(child: child),
      ],
    );
  }

  double _playDropdownMenuMaxHeight(
    BuildContext context, {
    bool fromBottomBar = false,
  }) {
    final media = MediaQuery.of(context);
    final screenHeight = media.size.height;
    if (!fromBottomBar) {
      return screenHeight * 0.7;
    }
    final reservedBottom = 130.0 + media.padding.bottom;
    final reservedTop = media.padding.top + 48.0;
    return (screenHeight - reservedBottom - reservedTop).clamp(72.0, 200.0);
  }

  Widget _desktopBottomDropdown<T>({
    required BuildContext context,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?>? onChanged,
    bool compact = false,
    bool fromBottomBar = false,
    DropdownButtonBuilder? selectedItemBuilder,
  }) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: BingoColors.surface.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.28),
          width: 1.2,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          isDense: compact,
          menuMaxHeight: _playDropdownMenuMaxHeight(
            context,
            fromBottomBar: fromBottomBar,
          ),
          dropdownColor: BingoColors.surfaceLight,
          padding: compact ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 6),
          icon: Icon(
            Icons.expand_more,
            color: BingoColors.gold.withValues(alpha: 0.9),
            size: compact ? 16 : 18,
          ),
          style: TextStyle(
            fontSize: compact ? 11 : 12,
            fontWeight: FontWeight.w700,
            color: BingoColors.textPrimary,
          ),
          selectedItemBuilder: selectedItemBuilder,
          items: items,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _mobileBottomBarPicker({
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(5),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: BingoColors.surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.28),
              width: 1.2,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Expanded(
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: BingoColors.textPrimary,
                      ),
                    ),
                  ),
                ),
                Icon(
                  Icons.expand_more,
                  color: BingoColors.gold.withValues(alpha: 0.9),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _currentVoiceLabel() {
    final index = normalizeCallerVoiceIndex(_voiceIndex);
    for (final option in kCallerVoiceOptions) {
      if (option.soundIndex == index) return option.label;
    }
    return kCallerVoiceOptions.first.label;
  }

  Widget _scrollablePickerSheet(
    BuildContext ctx,
    List<Widget> children, {
    String? title,
  }) {
    final maxHeight = MediaQuery.sizeOf(ctx).height * 0.55;
    return SafeArea(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: maxHeight),
        child: ListView(
          shrinkWrap: true,
          padding: const EdgeInsets.symmetric(vertical: 4),
          children: [
            if (title != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Text(
                  title,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: BingoColors.gold,
                  ),
                ),
              ),
            ],
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _mobileCompactPickerSheet({
    required BuildContext ctx,
    required String title,
    required List<Widget> children,
  }) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: BingoColors.gold,
              ),
            ),
            const SizedBox(height: 12),
            ...children,
          ],
        ),
      ),
    );
  }

  Widget _mobilePickerOptionTile({
    required String title,
    required String subtitle,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: selected
                  ? BingoColors.primary.withValues(alpha: 0.18)
                  : BingoColors.surface.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: selected
                    ? BingoColors.gold
                    : Colors.white.withValues(alpha: 0.22),
                width: selected ? 1.5 : 1,
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: selected
                              ? BingoColors.gold
                              : BingoColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: BingoColors.textSecondary.withValues(
                            alpha: selected ? 0.95 : 0.85,
                          ),
                          height: 1.25,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  selected ? Icons.check_circle : Icons.circle_outlined,
                  color: selected
                      ? BingoColors.gold
                      : BingoColors.textSecondary.withValues(alpha: 0.7),
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _showMobileVoicePicker(BuildContext context) async {
    final picked = await showModalBottomSheet<int>(
      context: context,
      backgroundColor: BingoColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => _scrollablePickerSheet(
        ctx,
        kCallerVoiceOptions.map((option) {
          final selected =
              normalizeCallerVoiceIndex(_voiceIndex) == option.soundIndex;
          return ListTile(
            dense: true,
            title: Text(
              option.label,
              style: TextStyle(
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected
                    ? BingoColors.gold
                    : BingoColors.textPrimary,
              ),
            ),
            onTap: () => Navigator.pop(ctx, option.soundIndex),
          );
        }).toList(),
      ),
    );
    if (picked != null) await _persistVoiceIndex(picked);
  }

  Future<void> _showMobileCheckModePicker(BuildContext context, AppStrings s) async {
    final current = _checkMode == 'auto' ? 'auto' : 'manual';
    final picked = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: BingoColors.surfaceLight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
      ),
      builder: (ctx) => _mobileCompactPickerSheet(
        ctx: ctx,
        title: s.checkResult,
        children: [
          _mobilePickerOptionTile(
            title: s.manual,
            subtitle: s.manualHelp,
            selected: current == 'manual',
            onTap: () => Navigator.pop(ctx, 'manual'),
          ),
          _mobilePickerOptionTile(
            title: s.automatic,
            subtitle: s.automaticHelp,
            selected: current == 'auto',
            onTap: () => Navigator.pop(ctx, 'auto'),
          ),
        ],
      ),
    );
    if (picked != null) _persistCheckMode(picked);
  }

  static const double _mobileActionHeight = 40;

  Widget _buildCheckCardControl(
    AppStrings s, {
    double height = 64,
    bool mini = false,
  }) {
    final okWidth = mini ? 36.0 : 52.0;
    final fieldFontSize = mini ? 12.0 : 16.0;
    final hintFontSize = mini ? 10.0 : 14.0;
    final okFontSize = mini ? 11.0 : 13.0;

    return _blockedTooltip(
      reason: _checkBlockedReason(s),
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: _canCheckCard(s)
                ? Colors.white.withValues(alpha: 0.28)
                : BingoColors.lastCalled.withValues(alpha: 0.65),
            width: 1.2,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(5),
          child: SizedBox(
            height: height,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: BingoColors.surface.withValues(
                        alpha: _canCheckCard(s) ? 0.6 : 0.35,
                      ),
                    ),
                    child: TextField(
                      controller: _checkController,
                      enabled: _canCheckCard(s),
                      expands: true,
                      maxLines: null,
                      textAlignVertical: TextAlignVertical.center,
                      style: TextStyle(
                        fontSize: fieldFontSize,
                        fontWeight: FontWeight.w900,
                        height: 1,
                        color: _canCheckCard(s)
                            ? BingoColors.textPrimary
                            : BingoColors.textSecondary,
                      ),
                      keyboardType: TextInputType.number,
                      textAlign: TextAlign.center,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _checkCard(),
                      decoration: InputDecoration(
                        hintText: s.cardNumberHint,
                        hintStyle: TextStyle(
                          color: BingoColors.gold.withValues(
                            alpha: _canCheckCard(s) ? 0.9 : 0.45,
                          ),
                          fontWeight: FontWeight.w700,
                          fontSize: hintFontSize,
                          height: 1,
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: mini ? 4 : 8,
                        ),
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        disabledBorder: InputBorder.none,
                        filled: false,
                      ),
                    ),
                  ),
                ),
                const ColoredBox(
                  color: Color(0x33FFFFFF),
                  child: SizedBox(width: 1),
                ),
                SizedBox(
                  width: okWidth,
                  child: Material(
                    color: _canCheckCard(s)
                        ? BingoColors.primary
                        : BingoColors.primary.withValues(alpha: 0.35),
                    child: InkWell(
                      onTap: _checkCard,
                      child: Center(
                        child: Text(
                          s.ok,
                          style: TextStyle(
                            fontSize: okFontSize,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withValues(
                              alpha: _canCheckCard(s) ? 1 : 0.55,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMobileControls(BuildContext context, AppStrings s) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (_canViewClaimedBonusCards) ...[
          SizedBox(
            height: 34,
            child: _viewBonusCardsButton(s, desktop: false),
          ),
          const SizedBox(height: 2),
        ],
        SizedBox(
          height: 40,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: _mobileBottomLabeledField(
                  label: s.sound,
                  child: _mobileBottomBarPicker(
                    label: _currentVoiceLabel(),
                    onTap: () => _showMobileVoicePicker(context),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                flex: 2,
                child: _mobileBottomLabeledField(
                  label: s.speed,
                  child: Align(
                    alignment: Alignment.center,
                    child: LabeledSpeedSlider(
                      value: _drawInterval.toDouble(),
                      label: '${_drawInterval}s',
                      min: _minDrawSpeed.toDouble(),
                      max: _maxDrawSpeed.toDouble(),
                      divisions: _maxDrawSpeed - _minDrawSpeed,
                      thumbRadius: 11,
                      trackHeight: 3,
                      onChanged: (v) {
                        final speed = v.round();
                        setState(() => _drawInterval = speed);
                        if (_drawing) _restartDrawTimer();
                      },
                      onChangeEnd: (v) => _persistDrawInterval(v.round()),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                child: _mobileBottomLabeledField(
                  label: s.checkResult,
                  child: _mobileBottomBarPicker(
                    label: _checkMode == 'auto' ? s.automatic : s.manual,
                    onTap: () => _showMobileCheckModePicker(context, s),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              _blockedTooltip(
                reason: _settingsBlockedReason(s),
                child: OutlinedButton(
                  onPressed: _canOpenSettings(s) ? _openPlayControls : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _canOpenSettings(s)
                        ? BingoColors.gold
                        : BingoColors.gold.withValues(alpha: 0.45),
                    side: BorderSide(
                      color: _canOpenSettings(s)
                          ? BingoColors.gold
                          : BingoColors.lastCalled.withValues(alpha: 0.65),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    minimumSize: const Size(36, 32),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Icon(
                    Icons.settings_outlined,
                    size: 18,
                    color: _canOpenSettings(s)
                        ? BingoColors.gold
                        : BingoColors.gold.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 2),
        SizedBox(
          height: _mobileActionHeight,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                flex: 4,
                child: _bingoButton(
                  s,
                  desktop: true,
                  compact: true,
                  height: _mobileActionHeight,
                ),
              ),
              const SizedBox(width: 2),
              SizedBox(
                width: 58,
                child: _shuffleButton(
                  s,
                  desktop: true,
                  compact: true,
                  height: _mobileActionHeight,
                ),
              ),
              const SizedBox(width: 2),
              SizedBox(
                width: 58,
                child: _finishButton(
                  s,
                  desktop: true,
                  compact: true,
                  height: _mobileActionHeight,
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                flex: 4,
                child: _buildCheckCardControl(
                  s,
                  height: _mobileActionHeight,
                  mini: true,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _mobileBottomLabeledField({
    required String label,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: BingoColors.gold,
            fontSize: 8,
            fontWeight: FontWeight.w700,
            height: 1.0,
          ),
        ),
        const SizedBox(height: 1),
        Expanded(child: child),
      ],
    );
  }

  Widget _viewBonusCardsButton(AppStrings s, {required bool desktop}) {
    return Tooltip(
      message: s.bonusLuckyTitle,
      child: FilledButton(
        onPressed: _showClaimedBonusCards,
        style: FilledButton.styleFrom(
          backgroundColor: BingoColors.gold,
          foregroundColor: Colors.black,
          padding: EdgeInsets.symmetric(
            horizontal: desktop ? 8 : 10,
            vertical: desktop ? 8 : 4,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(desktop ? 10 : 8),
          ),
        ),
        child: Text(
          s.bonusViewCards,
          maxLines: 2,
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: desktop ? 12 : 11,
            fontWeight: FontWeight.w800,
            height: 1.1,
          ),
        ),
      ),
    );
  }

  Widget _bingoButton(
    AppStrings s, {
    bool desktop = false,
    bool compact = false,
    double height = 64,
  }) {
    final drawing = _drawing;
    final blocked = _bingoBlockedReason(s);
    final borderWidth = height <= 44 ? 2.0 : 4.0;
    final titleSize = compact ? (height <= 44 ? 13.0 : 17.0) : 24.0;
    final hintSize = compact ? (height <= 44 ? 7.0 : 9.0) : 10.0;
    final showHint = height > 44;

    Widget button;

    if (desktop) {
      button = Material(
        color: Colors.transparent,

        child: InkWell(
          onTap: _toggleDraw,

          borderRadius: BorderRadius.circular(8),

          child: Ink(
            height: height,

            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,

                end: Alignment.bottomCenter,

                colors: drawing
                    ? [
                        BingoColors.lastCalled,
                        BingoColors.lastCalled.withValues(alpha: 0.8),
                      ]
                    : _canBingo(s)
                        ? [
                            BingoColors.bingoButtonStart,
                            BingoColors.bingoButtonEnd,
                          ]
                        : [
                            BingoColors.bingoButtonStart.withValues(alpha: 0.55),
                            BingoColors.bingoButtonEnd.withValues(alpha: 0.55),
                          ],
              ),

              borderRadius: BorderRadius.circular(8),

              border: Border.all(
                color: _canBingo(s)
                    ? Colors.white
                    : BingoColors.lastCalled.withValues(alpha: 0.65),
                width: borderWidth,
              ),
            ),

            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _playButtonLabel(
                  title: drawing ? s.stop : s.bingo,
                  enabledHint: showHint ? _bingoSpaceHint(s) : null,
                  disabledHint: showHint ? blocked : null,
                  enabled: _canBingo(s),
                  titleSize: titleSize,
                  titleColor: drawing
                      ? Colors.white
                      : (_canBingo(s)
                          ? Colors.black
                          : Colors.black.withValues(alpha: 0.45)),
                  hintColor: drawing
                      ? Colors.white
                      : const Color(0xFF8B0000),
                  hintSize: hintSize,
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      button = FilledButton(
        onPressed: _toggleDraw,

        style: FilledButton.styleFrom(
          backgroundColor: drawing
              ? BingoColors.lastCalled
              : (_canBingo(s)
                  ? BingoColors.primary
                  : BingoColors.primary.withValues(alpha: 0.35)),

          padding: const EdgeInsets.symmetric(vertical: 6),
        ),

        child: _playButtonLabel(
          title: drawing ? s.stop : s.bingo,
          enabled: _canBingo(s),
          titleSize: 11,
          titleWeight: FontWeight.w800,
          titleColor: Colors.white.withValues(alpha: _canBingo(s) ? 1 : 0.55),
        ),
      );
    }

    return _blockedTooltip(reason: blocked, child: button, showHint: desktop);
  }

  Widget _shuffleButton(
    AppStrings s, {
    bool desktop = false,
    bool compact = false,
    double height = 64,
  }) {
    final blocked = _shuffling ? null : _shuffleStartBlockedReason(s);
    final stopping = _shuffling;
    final borderWidth = height <= 44 ? 2.0 : 4.0;
    final fontSize = compact ? (height <= 44 ? 11.0 : 17.0) : 22.0;

    Widget button;

    if (desktop) {
      button = Material(
        color: Colors.transparent,

        child: InkWell(
          onTap: _toggleShuffle,

          borderRadius: BorderRadius.circular(8),

          child: Ink(
            height: height,

            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,

                end: Alignment.bottomCenter,

                colors: stopping
                    ? const [
                        Color(0xFFFFCDD2),
                        Color(0xFFFFEBEE),
                        Color(0xFFE53935),
                        Color(0xFF8B0000),
                      ]
                    : _canShuffle(s)
                    ? const [
                        Color(0xFFF8FAFA),
                        Color(0xFFFFFFFF),
                        Color(0xFF7575FF),
                        Color(0xFF011921),
                      ]
                    : [
                        const Color(0xFFF8FAFA).withValues(alpha: 0.55),
                        const Color(0xFFFFFFFF).withValues(alpha: 0.55),
                        const Color(0xFF7575FF).withValues(alpha: 0.45),
                        const Color(0xFF011921).withValues(alpha: 0.45),
                      ],

                stops: const [0.0, 0.47, 0.77, 1.0],
              ),

              borderRadius: BorderRadius.circular(8),

              border: Border.all(
                color: stopping
                    ? BingoColors.lastCalled
                    : _canShuffle(s)
                    ? Colors.white
                    : BingoColors.lastCalled.withValues(alpha: 0.65),
                width: borderWidth,
              ),
            ),

            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  _shuffling ? s.stop : s.shuffle,
                  style: TextStyle(
                    fontSize: fontSize,
                    fontWeight: FontWeight.w900,
                    color: _canShuffle(s)
                        ? Colors.black
                        : Colors.black.withValues(alpha: 0.45),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      button = OutlinedButton(
        onPressed: _toggleShuffle,

        style: OutlinedButton.styleFrom(
          foregroundColor: stopping
              ? BingoColors.lastCalled
              : _canShuffle(s)
              ? BingoColors.gold
              : BingoColors.gold.withValues(alpha: 0.45),

          side: BorderSide(
            color: stopping
                ? BingoColors.lastCalled
                : _canShuffle(s)
                ? BingoColors.gold
                : BingoColors.lastCalled.withValues(alpha: 0.65),
            width: stopping ? 2 : 1,
          ),

          padding: const EdgeInsets.symmetric(vertical: 6),
        ),

        child: Text(
          _shuffling ? s.stop : s.shuffle,
          style: TextStyle(
            fontSize: 10,
            fontWeight: stopping ? FontWeight.w900 : FontWeight.w600,
          ),
        ),
      );
    }

    return _blockedTooltip(reason: blocked, child: button, showHint: desktop);
  }

  Widget _finishButton(
    AppStrings s, {
    bool desktop = false,
    bool compact = false,
    double height = 64,
  }) {
    final blocked = _finishBlockedReason(s);
    final borderWidth = height <= 44 ? 2.0 : 4.0;
    final titleSize = compact ? (height <= 44 ? 11.0 : 17.0) : 22.0;
    final hintSize = compact ? (height <= 44 ? 7.0 : 9.0) : 10.0;
    final showHint = height > 44;

    Widget button;

    if (desktop) {
      button = Material(
        color: Colors.transparent,

        child: InkWell(
          onTap: _finish,

          borderRadius: BorderRadius.circular(8),

          child: Ink(
            height: height,

            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,

                end: Alignment.bottomCenter,

                colors: _canFinish(s)
                    ? const [
                        BingoColors.bingoButtonStart,
                        BingoColors.bingoButtonEnd,
                      ]
                    : [
                        BingoColors.bingoButtonStart.withValues(alpha: 0.55),
                        BingoColors.bingoButtonEnd.withValues(alpha: 0.55),
                      ],
              ),

              borderRadius: BorderRadius.circular(8),

              border: Border.all(
                color: _canFinish(s)
                    ? BingoColors.lastCalled
                    : BingoColors.lastCalled.withValues(alpha: 0.65),
                width: borderWidth,
              ),
            ),

            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: _playButtonLabel(
                  title: s.finish,
                  disabledHint: showHint ? blocked : null,
                  enabled: _canFinish(s),
                  titleSize: titleSize,
                  titleColor: _canFinish(s)
                      ? Colors.black
                      : Colors.black.withValues(alpha: 0.45),
                  hintColor: BingoColors.lastCalled,
                  hintSize: hintSize,
                ),
              ),
            ),
          ),
        ),
      );
    } else {
      button = OutlinedButton(
        onPressed: _finish,

        style: OutlinedButton.styleFrom(
          foregroundColor: _canFinish(s)
              ? BingoColors.textSecondary
              : BingoColors.textSecondary.withValues(alpha: 0.45),

          side: BorderSide(
            color: _canFinish(s)
                ? BingoColors.border
                : BingoColors.lastCalled.withValues(alpha: 0.65),
          ),

          padding: const EdgeInsets.symmetric(vertical: 6),
        ),

        child: _playButtonLabel(
          title: s.finish,
          enabled: _canFinish(s),
          titleSize: 10,
          titleWeight: FontWeight.w600,
          titleColor: _canFinish(s)
              ? BingoColors.textSecondary
              : BingoColors.textSecondary.withValues(alpha: 0.45),
        ),
      );
    }

    return _blockedTooltip(reason: blocked, child: button, showHint: desktop);
  }
}
