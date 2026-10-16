import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_config.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/l10n/locale_controller.dart';
import '../../data/models/cashier_session.dart';
import '../../data/repositories/auth_repository.dart';
import '../../data/repositories/cartela_importer.dart';
import '../../data/repositories/game_repository.dart';
import '../theme/bingo_colors.dart';
import '../widgets/app_loading.dart';
import '../widgets/app_toast.dart';
import '../widgets/ethiomark_auth_shell.dart';

class PlaySetupPanel extends StatefulWidget {
  const PlaySetupPanel({
    super.key,
    required this.session,
    required this.gameRepository,
    required this.setupRepository,
    required this.cartelaImporter,
    required this.onBalanceChanged,
    this.onIdentityUpdated,
    this.embedded = false,
    this.saving = false,
  });

  final CashierSession session;
  final GameRepository gameRepository;
  final SetupRepository setupRepository;
  final CartelaImporter cartelaImporter;
  final Future<void> Function() onBalanceChanged;
  final void Function(CashierSession session)? onIdentityUpdated;
  final bool embedded;
  final bool saving;

  @override
  State<PlaySetupPanel> createState() => PlaySetupPanelState();
}

class PlaySetupPanelState extends State<PlaySetupPanel> {
  final _domainController = TextEditingController();
  final _partnerIdController = TextEditingController();

  String _initialDomain = '';

  bool _loading = true;
  bool _importingCartelas = false;

  @override
  void initState() {
    super.initState();
    _partnerIdController.text = '${widget.session.partnerId}';
    _load();
  }

  @override
  void dispose() {
    _domainController.dispose();
    _partnerIdController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final domain = await AppConfig.getRemoteDomain();
    if (!mounted) return;
    setState(() {
      _initialDomain = domain;
      _domainController.text = domain;
      _loading = false;
    });
  }

  /// Saves partner ID and remote domain when changed. Returns false on validation error.
  Future<bool> savePendingChanges() async {
    final s = context.read<LocaleController>().strings;
    final partnerText = _partnerIdController.text.trim();
    final partnerId = int.tryParse(partnerText);

    if (partnerText.isNotEmpty && (partnerId == null || partnerId < 1)) {
      showAppToast(context, s.partnerIdPositive, type: AppToastType.warning);
      return false;
    }

    try {
      if (partnerId != null && partnerId != widget.session.partnerId) {
        await widget.setupRepository.updateCashierIdentity(
          oldCashierId: widget.session.cashierId,
          newCashierId: widget.session.cashierId,
          partnerId: partnerId,
        );
        final profile = await widget.gameRepository.getCashierProfile(
          widget.session.cashierId,
        );
        final updated = CashierSession(
          cashierId: profile.cashierId,
          partnerId: profile.partnerId,
          category: profile.category,
          packageBalance: profile.packageBalance,
          isActive: profile.isActive,
        );
        if (!mounted) return false;
        widget.onIdentityUpdated?.call(updated);
        await widget.onBalanceChanged();
        if (!mounted) return false;
      }

      final domainInput = _domainController.text.trim();
      if (domainInput != _initialDomain) {
        await AppConfig.setRemoteDomain(domainInput);
        final domain = await AppConfig.getRemoteDomain();
        if (!mounted) return false;
        setState(() {
          _initialDomain = domain;
          _domainController.text = domain;
        });
      }

      return true;
    } catch (e) {
      if (mounted) {
        showAppToast(context, '$e', type: AppToastType.error);
      }
      return false;
    }
  }

  Future<void> _importCartelaFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['enc'],
      withData: true,
    );
    if (result == null || result.files.isEmpty || !mounted) return;
    final bytes = result.files.single.bytes;
    if (bytes == null) {
      final s = context.read<LocaleController>().strings;
      showAppToast(context, s.couldNotReadFile, type: AppToastType.error);
      return;
    }
    setState(() => _importingCartelas = true);
    try {
      final count = await widget.cartelaImporter.importFromEncryptedText(
        utf8.decode(bytes),
      );
      if (!mounted) return;
      setState(() => _importingCartelas = false);
      await _load();
      if (!mounted) return;
      final s = context.read<LocaleController>().strings;
      showAppToast(
        context,
        s.importedCartelas(count),
        type: AppToastType.success,
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _importingCartelas = false);
      final s = context.read<LocaleController>().strings;
      showAppToast(context, s.importFailed('$e'), type: AppToastType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().strings;
    if (_loading) {
      return AppLoadingView(message: s.loadingProfile);
    }
    return AppLoadingOverlay(
      loading: _importingCartelas,
      message: _importingCartelas ? s.importingCartelas : null,
      child: Padding(
        padding: widget.embedded
            ? const EdgeInsets.fromLTRB(0, 0, 0, 4)
            : const EdgeInsets.fromLTRB(14, 8, 14, 12),
        child: EthiomarkSectionCard(
          compact: true,
          title: s.packageSyncIds,
          child: _buildSyncSection(s),
        ),
      ),
    );
  }

  Widget _buildSyncSection(AppStrings s) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _partnerIdController,
          decoration: InputDecoration(
            labelText: s.partnerId,
            isDense: true,
          ),
          keyboardType: TextInputType.number,
          readOnly: widget.saving,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _domainController,
          decoration: InputDecoration(
            labelText: s.remoteDomain,
            hintText: 'ethiomark.com',
            isDense: true,
          ),
          readOnly: widget.saving,
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: _importingCartelas || widget.saving ? null : _importCartelaFile,
          style: OutlinedButton.styleFrom(
            foregroundColor: BingoColors.gold,
            side: const BorderSide(color: BingoColors.gold),
          ),
          icon: _importingCartelas
              ? const AppButtonLoader(color: BingoColors.gold, size: 16)
              : const Icon(Icons.upload_file),
          label: Text(s.loadEncryptedCartela),
        ),
      ],
    );
  }
}
