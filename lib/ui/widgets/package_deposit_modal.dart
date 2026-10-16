import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/l10n/locale_controller.dart';
import '../../core/network/user_facing_error.dart';
import '../../data/repositories/game_repository.dart';
import '../../services/deposit_service.dart';
import 'app_loading.dart';
import '../theme/bingo_colors.dart';

class PackageDepositModal extends StatefulWidget {
  const PackageDepositModal({
    super.key,
    required this.cashierId,
    required this.depositService,
    required this.gameRepository,
    required this.onApplied,
  });

  final String cashierId;
  final DepositService depositService;
  final GameRepository gameRepository;
  final VoidCallback onApplied;

  @override
  State<PackageDepositModal> createState() => _PackageDepositModalState();
}

class _PackageDepositModalState extends State<PackageDepositModal> {
  bool _loading = true;
  Map<String, dynamic>? _result;
  String? _banner;
  Color? _bannerColor;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    final s = context.read<LocaleController>().strings;
    setState(() {
      _loading = true;
      _banner = null;
    });

    try {
      final res = await widget.gameRepository.syncPackageDeposit(
        widget.cashierId,
        widget.depositService,
      );
      if (!mounted) return;

      final status = res['status'] as String? ?? 'error';
      if (status == 'success' || status == 'duplicate') {
        widget.onApplied();
      }

      final isNetworkIssue = status == 'offline' ||
          looksLikeNetworkError(res['message']) ||
          looksLikeNetworkError(res['error']);

      setState(() {
        _result = res;
        _loading = false;
        _banner = isNetworkIssue
            ? s.noInternetConnection
            : sanitizeUserMessage(res['message'] as String?, s);
        _bannerColor = switch (status) {
          'success' => Colors.green.shade700,
          'empty' || 'duplicate' => Colors.blue.shade700,
          'offline' => Colors.orange.shade800,
          _ => Colors.red.shade700,
        };
      });
    } catch (e) {
      if (!mounted) return;
      final message = userFacingNetworkMessage(e, s);
      setState(() {
        _loading = false;
        _result = {
          'status': 'error',
          'message': message,
        };
        _banner = message;
        _bannerColor = Colors.red.shade700;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().strings;
    final width = MediaQuery.sizeOf(context).width;
    final dialogWidth = width > 400 ? 320.0 : width - 32;
    final status = _result?['status'] as String?;
    final showTechnicalBlock = status == 'success' ||
        status == 'duplicate' ||
        status == 'empty';

    return AlertDialog(
      backgroundColor: BingoColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      titlePadding: const EdgeInsets.fromLTRB(12, 8, 4, 0),
      contentPadding: const EdgeInsets.fromLTRB(12, 6, 12, 4),
      actionsPadding: const EdgeInsets.fromLTRB(8, 0, 8, 4),
      title: Row(
        children: [
          Expanded(
            child: Text(
              s.packageDeposit,
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
      content: SizedBox(
        width: dialogWidth,
        child: _loading
            ? AppLoadingIndicator(
                message: s.fetchingPackage,
                color: BingoColors.primary,
                size: 28,
              )
            : Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_result?['status'] != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Chip(
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        label: Text(
                          '${_result!['status']}'.toUpperCase(),
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        backgroundColor: _bannerColor?.withValues(alpha: 0.15),
                      ),
                    ),
                  if (_banner != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      _banner!,
                      style: TextStyle(
                        color: _bannerColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                  if (showTechnicalBlock) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black87,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: SelectableText(
                        _result?['code_block']?.toString() ??
                            _result?['message']?.toString() ??
                            s.noResponse,
                        style: const TextStyle(
                          color: Colors.greenAccent,
                          fontFamily: 'monospace',
                          fontSize: 9,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          ),
          onPressed: _loading ? null : _fetch,
          child: Text(s.reFetch, style: const TextStyle(fontSize: 12)),
        ),
        TextButton(
          style: TextButton.styleFrom(
            visualDensity: VisualDensity.compact,
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          ),
          onPressed: () => Navigator.pop(context),
          child: Text(s.close, style: const TextStyle(fontSize: 12)),
        ),
      ],
    );
  }
}
