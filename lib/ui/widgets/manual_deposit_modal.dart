import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/deposit/manual_deposit_codec.dart';
import '../../core/deposit/manual_deposit_lockout.dart';
import '../../core/device/device_id.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/l10n/locale_controller.dart';
import '../../data/repositories/game_repository.dart';
import '../theme/bingo_colors.dart';
import 'app_loading.dart';
import 'app_toast.dart';

Future<void> showManualDepositModal({
  required BuildContext context,
  required String cashierId,
  required String partnerId,
  required String packageBalance,
  required GameRepository gameRepository,
  required Future<void> Function() onApplied,
}) {
  return showDialog<void>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => ManualDepositModal(
      cashierId: cashierId,
      partnerId: partnerId,
      packageBalance: packageBalance,
      gameRepository: gameRepository,
      onApplied: onApplied,
    ),
  );
}

class ManualDepositModal extends StatefulWidget {
  const ManualDepositModal({
    super.key,
    required this.cashierId,
    required this.partnerId,
    required this.packageBalance,
    required this.gameRepository,
    required this.onApplied,
  });

  final String cashierId;
  final String partnerId;
  final String packageBalance;
  final GameRepository gameRepository;
  final Future<void> Function() onApplied;

  @override
  State<ManualDepositModal> createState() => _ManualDepositModalState();
}

class _ManualDepositModalState extends State<ManualDepositModal>
    with TickerProviderStateMixin {
  final _amountController = TextEditingController();
  final _responseController = TextEditingController();
  final _amountFocus = FocusNode();
  bool _loading = false;
  bool _initLoading = true;
  String? _machineId;
  int? _serialDecimal;
  int? _randomNumber;
  String? _message;
  _DepositFeedbackKind? _messageKind;
  ManualDepositLockoutState? _lockout;
  Timer? _lockoutTimer;
  late final AnimationController _responseGlowController;

  bool get _isLocked => _lockout?.isLocked ?? false;

  @override
  void initState() {
    super.initState();
    _responseGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _loadDevice();
    _refreshLockout();
  }

  Future<void> _refreshLockout() async {
    final lockout = await ManualDepositLockout.load();
    if (!mounted) return;
    setState(() => _lockout = lockout);
    _syncLockoutTimer(lockout);
  }

  void _syncLockoutTimer(ManualDepositLockoutState lockout) {
    _lockoutTimer?.cancel();
    _lockoutTimer = null;
    if (!lockout.isLocked) return;

    _lockoutTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      final next = await ManualDepositLockout.load();
      if (!mounted) return;
      setState(() => _lockout = next);
      if (!next.isLocked) {
        _lockoutTimer?.cancel();
        _lockoutTimer = null;
      }
    });
  }

  String? _lockoutMessage(AppStrings s) {
    final lockout = _lockout;
    if (lockout == null || !lockout.isLocked) return null;
    return s.manualDepositLocked(
      ManualDepositLockout.formatRemaining(lockout.remaining),
    );
  }

  Future<void> _loadDevice() async {
    final machineId = await DeviceId.getSerial();
    if (!mounted) return;
    setState(() {
      _machineId = machineId;
      _serialDecimal = ManualDepositCodec.serialDecimalFromMachineId(machineId);
      _randomNumber = ManualDepositCodec.generateRandomNumber();
      _initLoading = false;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _isLocked) return;
      _amountFocus.requestFocus();
    });
  }

  void _refreshRandom() {
    setState(() {
      _randomNumber = ManualDepositCodec.generateRandomNumber();
      _message = null;
    });
  }

  int? get _amount {
    final raw = _amountController.text.trim();
    if (raw.isEmpty) return null;
    return int.tryParse(raw);
  }

  String? _requestCopyText() {
    final serial = _serialDecimal;
    final random = _randomNumber;
    final amount = _amount;
    if (serial == null || random == null || amount == null) return null;
    return ManualDepositCodec.formatRequestForCopy(
      serialDecimal: serial,
      randomNumber: random,
      amount: amount,
      cashierId: widget.cashierId,
    );
  }

  Future<void> _copyText(String text) async {
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) return;
    final s = context.read<LocaleController>().strings;
    showAppToast(
      context,
      s.copied,
      type: AppToastType.success,
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _lockoutTimer?.cancel();
    _responseGlowController.dispose();
    _amountFocus.dispose();
    _amountController.dispose();
    _responseController.dispose();
    super.dispose();
  }

  String _resultMessage(AppStrings s, Map<String, dynamic> result) {
    final status = result['status'] as String? ?? 'error';
    final code = result['code'] as String?;

    if (code == 'manual_deposit_locked') {
      final remainingSeconds = result['remaining_seconds'] as int?;
      final remaining = remainingSeconds != null
          ? Duration(seconds: remainingSeconds)
          : (_lockout?.remaining ?? Duration.zero);
      return s.manualDepositLocked(
        ManualDepositLockout.formatRemaining(remaining),
      );
    }
    if (code == 'invalid_deposit_code') {
      final attemptsRemaining = result['attempts_remaining'] as int?;
      if (attemptsRemaining != null && attemptsRemaining > 0) {
        return s.manualDepositAttemptsRemaining(attemptsRemaining);
      }
      return s.invalidDepositCode;
    }

    return switch (code) {
      'invalid_deposit_amount' => s.invalidDepositAmount,
      'insufficient_wallet_balance' => s.insufficientWalletForWithdrawal(
          result['balance'] as String? ?? widget.packageBalance,
        ),
      'duplicate_deposit_code' => s.duplicateDepositCode,
      _ when status == 'success' => s.manualDepositSuccess(
          result['balance'] as String? ?? widget.packageBalance,
        ),
      _ => result['message'] as String? ?? s.invalidDepositCode,
    };
  }

  Future<void> _apply() async {
    final s = context.read<LocaleController>().strings;
    final machineId = _machineId;
    final random = _randomNumber;
    final amount = _amount;

    if (_isLocked) {
      setState(() {
        _messageKind = _DepositFeedbackKind.error;
        _message = _lockoutMessage(s);
      });
      return;
    }

    if (machineId == null || random == null) return;
    // Zero invalid; negative = withdrawal (deduct from wallet).
    if (amount == null || amount == 0) {
      setState(() {
        _messageKind = _DepositFeedbackKind.error;
        _message = s.invalidDepositAmount;
      });
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    try {
      final result = await widget.gameRepository.applyManualDeposit(
        cashierId: widget.cashierId,
        partnerId: widget.partnerId,
        machineId: machineId,
        randomNumber: random,
        amount: amount,
        responseCode: _responseController.text,
      );

      if (!mounted) return;

      final status = result['status'] as String? ?? 'error';
      if (status == 'success') {
        await widget.onApplied();
      }

      final lockout = await ManualDepositLockout.load();
      if (!mounted) return;

      setState(() {
        _loading = false;
        _lockout = lockout;
        if (status == 'success') {
          _randomNumber = ManualDepositCodec.generateRandomNumber();
          _responseController.clear();
        }
        _messageKind = switch (status) {
          'success' => _DepositFeedbackKind.success,
          'duplicate' => _DepositFeedbackKind.warning,
          _ => _DepositFeedbackKind.error,
        };
        _message = _resultMessage(s, result);
      });
      _syncLockoutTimer(lockout);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _messageKind = _DepositFeedbackKind.error;
        _message = '$e';
      });
    }
  }

  Widget _groupBox({
    required String title,
    required List<Widget> children,
    bool glowing = false,
  }) {
    const groupBg = Color(0xFF0A1E24);
    const glowColor = BingoColors.gold;

    Widget buildShell(double glowStrength) {
      final t = Curves.easeInOut.transform(glowStrength);
      final borderAlpha = glowing ? 0.45 + t * 0.55 : 0.6;
      final borderColor = glowing
          ? glowColor.withValues(alpha: borderAlpha)
          : BingoColors.border.withValues(alpha: borderAlpha);

      return Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 6),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(top: 8),
              padding: const EdgeInsets.fromLTRB(14, 18, 14, 14),
              decoration: BoxDecoration(
                color: groupBg,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: borderColor,
                  width: glowing ? 1.5 : 1,
                ),
                boxShadow: glowing
                    ? [
                        BoxShadow(
                          color: glowColor.withValues(alpha: 0.28 + t * 0.5),
                          blurRadius: 10 + t * 16,
                          spreadRadius: t * 3,
                        ),
                        BoxShadow(
                          color: BingoColors.accentTeal.withValues(
                            alpha: 0.18 + t * 0.35,
                          ),
                          blurRadius: 20 + t * 12,
                          spreadRadius: 1 + t * 2,
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: children,
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  color: BingoColors.surface,
                  child: Text(
                    title,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: glowing ? glowColor : BingoColors.gold,
                      letterSpacing: 0.3,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!glowing) return buildShell(0);

    return AnimatedBuilder(
      animation: _responseGlowController,
      builder: (context, _) => buildShell(_responseGlowController.value),
    );
  }

  InputDecoration _borderDecoration({
    required String label,
    Widget? suffixIcon,
  }) {
    const borderColor = Color(0x66FFFFFF);

    return InputDecoration(
      labelText: label,
      floatingLabelBehavior: FloatingLabelBehavior.always,
      isDense: true,
      contentPadding: const EdgeInsets.fromLTRB(12, 8, 8, 10),
      filled: false,
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: BingoColors.gold, width: 1.5),
      ),
    );
  }

  Widget? _compactSuffix({
    required AppStrings s,
    VoidCallback? onRefresh,
  }) {
    if (onRefresh == null) return null;
    return IconButton(
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
      tooltip: s.refreshRandom,
      icon: const Icon(Icons.refresh, size: 16, color: BingoColors.gold),
      onPressed: _loading ? null : onRefresh,
    );
  }

  Widget _compactValue({
    required AppStrings s,
    required String label,
    required String value,
    String? subtitle,
    VoidCallback? onRefresh,
  }) {
    return InputDecorator(
      decoration: _borderDecoration(
        label: label,
        suffixIcon: _compactSuffix(
          s: s,
          onRefresh: onRefresh,
        ),
      ),
      child: subtitle != null
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    color: BingoColors.textSecondary,
                  ),
                ),
              ],
            )
          : Align(
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
    );
  }

  InputDecoration _responseInputDecoration() {
    return InputDecoration(
      isDense: true,
      contentPadding: const EdgeInsets.fromLTRB(4, 4, 4, 8),
      filled: false,
      border: InputBorder.none,
      enabledBorder: InputBorder.none,
      focusedBorder: InputBorder.none,
      disabledBorder: InputBorder.none,
      errorBorder: InputBorder.none,
      focusedErrorBorder: InputBorder.none,
    );
  }

  InputDecoration _inputDecoration(String label) {
    return _borderDecoration(label: label);
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().strings;
    final width = MediaQuery.sizeOf(context).width;
    final dialogWidth = width > 520 ? 440.0 : width - 32;
    final lockoutMessage = _lockoutMessage(s);
    final inputsEnabled = !_loading && !_isLocked;

    return AlertDialog(
      backgroundColor: BingoColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      titlePadding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      actionsPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
      title: Row(
        children: [
          Expanded(
            child: Text(
              s.manualDeposit,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
            ),
          ),
          IconButton(
            tooltip: s.close,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, size: 18),
            onPressed: _loading ? null : () => Navigator.pop(context),
          ),
        ],
      ),
      content: SizedBox(
        width: dialogWidth,
        child: AppLoadingOverlay(
          loading: _loading || _initLoading,
          message: _initLoading ? s.loadingProfile : s.applyManualDeposit,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (lockoutMessage != null) ...[
                  _DepositFeedbackBanner(
                    kind: _DepositFeedbackKind.error,
                    message: lockoutMessage,
                    icon: Icons.lock_clock,
                  ),
                  const SizedBox(height: 10),
                ],
                _groupBox(
                  title: s.manualDepositRequestSection,
                  children: [
                    _compactValue(
                      s: s,
                      label: s.walletId,
                      value: widget.cashierId,
                    ),
                    const SizedBox(height: 12),
                    if (_serialDecimal != null && _randomNumber != null) ...[
                      _compactValue(
                        s: s,
                        label: s.depositRequestId,
                        value: '$_serialDecimal $_randomNumber',
                        onRefresh: _refreshRandom,
                      ),
                    ],
                    const SizedBox(height: 24),
                    TextField(
                      controller: _amountController,
                      focusNode: _amountFocus,
                      enabled: inputsEnabled,
                      keyboardType: const TextInputType.numberWithOptions(
                        signed: true,
                      ),
                      inputFormatters: [
                        TextInputFormatter.withFunction((oldValue, newValue) {
                          final t = newValue.text;
                          if (t.isEmpty || t == '-') return newValue;
                          if (RegExp(r'^-?\d+$').hasMatch(t)) return newValue;
                          return oldValue;
                        }),
                      ],
                      decoration: _inputDecoration(s.amountLabel).copyWith(
                        helperText: s.manualDepositAmountHint,
                        helperMaxLines: 2,
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: FilledButton.icon(
                        onPressed: _requestCopyText() == null || _loading
                            ? null
                            : () => _copyText(_requestCopyText()!),
                        icon: const Icon(Icons.copy, size: 18),
                        label: Text(
                          s.copyRequest,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: BingoColors.gold,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 12,
                          ),
                          minimumSize: const Size(0, 48),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                _groupBox(
                  title: s.manualDepositResponseSection,
                  glowing: true,
                  children: [
                    TextField(
                      controller: _responseController,
                      enabled: inputsEnabled,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      minLines: 2,
                      maxLines: 3,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                      textAlign: TextAlign.center,
                      decoration: _responseInputDecoration(),
                      onSubmitted: (_) => _apply(),
                    ),
                  ],
                ),
                if (_message != null && !_isLocked && _messageKind != null) ...[
                  const SizedBox(height: 10),
                  _DepositFeedbackBanner(
                    kind: _messageKind!,
                    message: _message!,
                  ),
                ],
                const SizedBox(height: 4),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: Text(s.close),
        ),
        FilledButton(
          onPressed: _loading || _initLoading || _isLocked ? null : _apply,
          style: FilledButton.styleFrom(
            backgroundColor: BingoColors.gold,
            foregroundColor: Colors.black,
          ),
          child: Text(
            s.applyManualDeposit,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
          ),
        ),
      ],
    );
  }
}

enum _DepositFeedbackKind { error, success, warning }

class _DepositFeedbackStyle {
  const _DepositFeedbackStyle({
    required this.background,
    required this.border,
    required this.text,
    required this.icon,
  });

  final Color background;
  final Color border;
  final Color text;
  final Color icon;

  static _DepositFeedbackStyle forKind(_DepositFeedbackKind kind) {
    return switch (kind) {
      _DepositFeedbackKind.error => const _DepositFeedbackStyle(
          background: Color(0xFFFFEBEE),
          border: Color(0xFFE53935),
          text: Color(0xFFB71C1C),
          icon: Color(0xFFC62828),
        ),
      _DepositFeedbackKind.success => const _DepositFeedbackStyle(
          background: Color(0xFFE8F5E9),
          border: Color(0xFF43A047),
          text: Color(0xFF1B5E20),
          icon: Color(0xFF2E7D32),
        ),
      _DepositFeedbackKind.warning => const _DepositFeedbackStyle(
          background: Color(0xFFFFF3E0),
          border: Color(0xFFFB8C00),
          text: Color(0xFFE65100),
          icon: Color(0xFFEF6C00),
        ),
    };
  }
}

class _DepositFeedbackBanner extends StatelessWidget {
  const _DepositFeedbackBanner({
    required this.kind,
    required this.message,
    this.icon,
  });

  final _DepositFeedbackKind kind;
  final String message;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final style = _DepositFeedbackStyle.forKind(kind);
    final leadingIcon = icon ?? switch (kind) {
      _DepositFeedbackKind.error => Icons.error_outline,
      _DepositFeedbackKind.success => Icons.check_circle_outline,
      _DepositFeedbackKind.warning => Icons.warning_amber_rounded,
    };

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: style.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: style.border, width: 1.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(leadingIcon, size: 18, color: style.icon),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: style.text,
                fontWeight: FontWeight.w700,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
