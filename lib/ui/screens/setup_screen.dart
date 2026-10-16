import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/app_config.dart';
import '../../core/config/app_version.dart';
import '../../core/config/login_prefs.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/trial/trial_storage_permission.dart';

import '../../data/repositories/auth_repository.dart';

import '../theme/bingo_colors.dart';

import '../theme/auth_theme.dart';

import '../widgets/app_loading.dart';
import '../widgets/ethiomark_auth_shell.dart';
import '../widgets/language_selector.dart';
import '../widgets/login_info_panel.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({
    super.key,

    required this.setupRepository,

    required this.onComplete,
  });

  final SetupRepository setupRepository;

  final VoidCallback onComplete;

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _partnerIdController =
      TextEditingController(text: '${AppConfig.defaultPartnerId}');

  final _cashierController = TextEditingController();

  final _passwordController = TextEditingController();

  bool _loading = false;

  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      TrialStoragePermission.ensureGranted();
    });
  }

  @override
  void dispose() {
    _partnerIdController.dispose();

    _cashierController.dispose();

    _passwordController.dispose();

    super.dispose();
  }

  Future<void> _open(Uri uri) async {
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  Future<void> _submit() async {
    final s = context.read<LocaleController>().strings;

    if (_cashierController.text.trim().isEmpty ||
        _passwordController.text.isEmpty) {
      setState(() => _error = s.cashierPasswordRequired);

      return;
    }

    final partnerId = int.tryParse(_partnerIdController.text.trim());

    if (partnerId == null || partnerId < 1) {
      setState(() => _error = s.partnerIdPositive);

      return;
    }

    final storageGranted = await TrialStoragePermission.ensureGranted();
    if (!storageGranted) {
      setState(() => _error = s.storagePermissionRequired);
      return;
    }

    setState(() {
      _loading = true;

      _error = null;
    });

    try {
      final cashierId = _cashierController.text.trim();

      final password = _passwordController.text;

      await widget.setupRepository.createInitialCashier(
        cashierId: cashierId,

        password: password,

        initialPackage: '0',

        partnerId: partnerId,
      );

      await LoginPrefs.save(cashierId, password);

      if (!mounted) return;

      widget.onComplete();
    } catch (e) {
      setState(() => _error = s.registrationFailed('$e'));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().strings;

    return AppLoadingOverlay(
      loading: _loading,
      message: s.creatingAccount,
      child: EthiomarkAuthShell(
        brandTitle: s.appVersion(AppVersion.version),
        desktopSidePanel: const AuthInfoPanel(compact: true),
        showMobileNotices: true,
        child: AuthFormScope(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,

            children: [
              Text(
                s.setupDescription,
                style: const TextStyle(
                  color: AuthTheme.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                s.newCashierContact,
                style: const TextStyle(
                  color: AuthTheme.textSecondary,
                  fontSize: 13,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              InkWell(
                onTap: () => _open(Uri.parse('mailto:meka2967@gmail.com')),
                child: const Text(
                  'meka2967@gmail.com',
                  style: TextStyle(
                    color: AuthTheme.brandGold,
                    decoration: TextDecoration.underline,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 4),

              const AuthLanguageField(),

              _authField(
                s.partnerId,
                _partnerIdController,
                keyboard: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
              ),

              _authField(
                s.cashierId,
                _cashierController,
                textInputAction: TextInputAction.next,
              ),

              _authField(
                s.password,
                _passwordController,
                obscure: true,
                onSubmitted: _submit,
              ),

              if (_error != null) ...[
                const SizedBox(height: 4),

                Text(
                  _error!,
                  style: const TextStyle(color: BingoColors.lastCalled),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 4),

              EthiomarkLoginButton(
                label: s.createAccount,
                onPressed: _submit,
                loading: _loading,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _authField(
    String label,

    TextEditingController controller, {

    bool obscure = false,

    TextInputType? keyboard,

    List<TextInputFormatter>? inputFormatters,

    TextInputAction? textInputAction,

    VoidCallback? onSubmitted,
  }) {
    return AuthFieldSurface(
      child: TextField(
        controller: controller,
        obscureText: obscure,
        readOnly: _loading,
        keyboardType: keyboard,
        inputFormatters: inputFormatters,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted != null ? (_) => onSubmitted() : null,
        style: const TextStyle(color: authFieldTextColor, fontSize: 16),
        decoration: authFieldDecoration(label),
      ),
    );
  }
}
