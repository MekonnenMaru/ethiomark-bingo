import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/config/login_prefs.dart';
import '../../data/models/cashier_session.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/game_repository.dart';
import '../widgets/app_toast.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.session,
    required this.setupRepository,
    required this.gameRepository,
    required this.authRepository,
    this.onIdentityUpdated,
    this.onAccountDeleted,
  });

  final CashierSession session;
  final SetupRepository setupRepository;
  final GameRepository gameRepository;
  final AuthRepository authRepository;
  final void Function(CashierSession session)? onIdentityUpdated;
  final VoidCallback? onAccountDeleted;

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _domainController = TextEditingController();
  final _cashierIdController = TextEditingController();
  final _partnerIdController = TextEditingController();

  bool _loading = true;
  bool _savingIds = false;
  bool _deleting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final domain = await AppConfig.getRemoteDomain();
    if (!mounted) return;
    setState(() {
      _domainController.text = domain;
      _cashierIdController.text = widget.session.cashierId;
      _partnerIdController.text = '${widget.session.partnerId}';
      _loading = false;
    });
  }

  Future<void> _saveDomain() async {
    final s = context.read<LocaleController>().strings;
    await AppConfig.setRemoteDomain(_domainController.text);
    final domain = await AppConfig.getRemoteDomain();
    if (!mounted) return;
    setState(() => _domainController.text = domain);
    showAppToast(context, s.domainSaved, type: AppToastType.success);
  }

  Future<void> _saveIdentity() async {
    final s = context.read<LocaleController>().strings;
    final partnerId = int.tryParse(_partnerIdController.text.trim());
    if (partnerId == null || partnerId < 1) {
      setState(() => _error = s.partnerIdPositive);
      return;
    }

    setState(() {
      _savingIds = true;
      _error = null;
    });

    try {
      await widget.setupRepository.updateCashierIdentity(
        oldCashierId: widget.session.cashierId,
        newCashierId: _cashierIdController.text,
        partnerId: partnerId,
      );

      final profile = await widget.gameRepository.getCashierProfile(
        _cashierIdController.text.trim(),
      );
      final updated = CashierSession(
        cashierId: profile.cashierId,
        partnerId: profile.partnerId,
        category: profile.category,
        packageBalance: profile.packageBalance,
        isActive: profile.isActive,
      );

      if (!mounted) return;
      widget.onIdentityUpdated?.call(updated);
      showAppToast(
        context,
        s.cashierPartnerIdsSaved,
        type: AppToastType.success,
      );
      Navigator.pop(context);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _savingIds = false);
    }
  }

  Future<void> _confirmDelete() async {
    final s = context.read<LocaleController>().strings;
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(s.deleteCashierTitle),
        content: Text(s.deleteCashierBody),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(s.cancel),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(s.delete),
          ),
        ],
      ),
    );

    if (ok != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await widget.authRepository.logout(widget.session.cashierId);
      await widget.setupRepository.deleteCashierAccount(
        widget.session.cashierId,
      );
      await LoginPrefs.clear();
      if (!mounted) return;
      widget.onAccountDeleted?.call();
      Navigator.of(context).popUntil((route) => route.isFirst);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _deleting = false);
    }
  }

  @override
  void dispose() {
    _domainController.dispose();
    _cashierIdController.dispose();
    _partnerIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().strings;
    return Scaffold(
      appBar: AppBar(title: Text(s.settings)),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    s.account,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(s.accountHelp),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _cashierIdController,
                    decoration: InputDecoration(labelText: s.cashierId),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _partnerIdController,
                    decoration: InputDecoration(labelText: s.partnerId),
                    keyboardType: TextInputType.number,
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _savingIds ? null : _saveIdentity,
                    child: _savingIds
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(s.saveCashierPartnerIds),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                    ),
                    onPressed: _deleting ? null : _confirmDelete,
                    icon: _deleting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.delete_outline),
                    label: Text(s.deleteCashierAccount),
                  ),
                  const Divider(height: 40),
                  Text(
                    s.remoteAdminDomain,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(s.remoteAdminDomainHelp),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _domainController,
                    decoration: InputDecoration(
                      labelText: s.domain,
                      hintText: 'ethiomark.com',
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilledButton.tonal(
                    onPressed: _saveDomain,
                    child: Text(s.saveDomain),
                  ),
                ],
              ),
            ),
    );
  }
}
