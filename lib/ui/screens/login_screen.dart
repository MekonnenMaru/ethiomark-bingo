import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_version.dart';
import '../../core/device/device_binding.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/network/user_facing_error.dart';

import '../../core/config/login_prefs.dart';

import '../../core/trial/trial_storage_permission.dart';

import '../../data/models/cashier_session.dart';

import '../../data/repositories/auth_repository.dart';

import '../theme/bingo_colors.dart';

import '../theme/auth_theme.dart';

import '../widgets/app_loading.dart';
import '../widgets/cartela_loading_banner.dart';
import '../widgets/ethiomark_auth_shell.dart';
import '../widgets/language_selector.dart';
import '../widgets/login_info_panel.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,

    required this.authRepository,

    required this.onLoggedIn,
  });

  final AuthRepository authRepository;

  final void Function(CashierSession session) onLoggedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _cashierController = TextEditingController();

  final _passwordController = TextEditingController();

  bool _loading = false;

  bool _restoringLogin = true;

  String? _error;

  @override
  void initState() {
    super.initState();

    _bootstrap();
  }

  Future<void> _bootstrap() async {
    await TrialStoragePermission.ensureGranted();

    final saved = await LoginPrefs.load();

    if (!mounted) return;

    if (saved.cashierId != null && saved.cashierId!.isNotEmpty) {
      _cashierController.text = saved.cashierId!;
    }

    if (saved.password != null && saved.password!.isNotEmpty) {
      _passwordController.text = saved.password!;
    }

    setState(() => _restoringLogin = false);
  }

  @override
  void dispose() {
    _cashierController.dispose();

    _passwordController.dispose();

    super.dispose();
  }

  Future<void> _submit() async {
    final s = context.read<LocaleController>().strings;

    setState(() {
      _loading = true;

      _error = null;
    });

    try {
      await TrialStoragePermission.ensureGranted();

      final session = await widget.authRepository.login(
        _cashierController.text,

        _passwordController.text,
      );

      if (!mounted) return;

      if (session == null) {
        setState(() => _error = s.invalidCredentials);
      } else {
        await LoginPrefs.save(
          _cashierController.text,
          _passwordController.text,
        );

        widget.onLoggedIn(session);
      }
    } on DeviceBindingException {
      if (!mounted) return;
      setState(() => _error = s.databaseDeviceMismatch);
    } on LoginAuthException catch (e) {
      if (!mounted) return;
      setState(() {
        if (e.locked) {
          _error = s.cashierAccountLocked;
        } else if (e.inactive) {
          _error = s.cashierAccountInactive;
        } else {
          _error = s.loginAttemptsRemaining(
            e.attemptsRemaining,
            AuthRepository.maxLoginAttempts,
          );
        }
      });
    } on StateError catch (e) {
      if (!mounted) return;
      setState(() => _error = e.message);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = looksLikeNetworkError(e)
            ? userFacingNetworkMessage(e, s)
            : s.loginFailed(sanitizeUserMessage('$e', s));
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().strings;

    return AppLoadingOverlay(
      loading: _loading,
      message: s.signingIn,
      child: EthiomarkAuthShell(
        brandTitle: s.appVersion(AppVersion.version),
        desktopSidePanel: const AuthInfoPanel(),
        showMobileNotices: true,
        footer: const CartelaLoadingBanner(),
        child: _restoringLogin
            ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: AppLoadingIndicator(
                  color: AuthTheme.brandGold,
                ),
              )
            : AuthFormScope(
                child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,

                children: [
                  const AuthLanguageField(),

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
                    const SizedBox(height: 12),

                    Text(
                      _error!,
                      style: const TextStyle(color: BingoColors.lastCalled),
                      textAlign: TextAlign.center,
                    ),
                  ],

                  const SizedBox(height: 16),

                  EthiomarkLoginButton(
                    label: s.loginButton,
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

    TextInputAction? textInputAction,

    VoidCallback? onSubmitted,
  }) {
    return AuthFieldSurface(
      child: TextField(
        controller: controller,
        obscureText: obscure,
        readOnly: _loading,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted != null ? (_) => onSubmitted() : null,
        style: const TextStyle(color: authFieldTextColor, fontSize: 16),
        decoration: authFieldDecoration(label),
      ),
    );
  }
}
