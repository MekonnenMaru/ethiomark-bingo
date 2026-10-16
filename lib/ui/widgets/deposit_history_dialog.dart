import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_currency.dart';
import '../../core/format/app_number_format.dart';
import '../../core/l10n/locale_controller.dart';
import '../../data/models/cashier_profile.dart';
import '../../data/repositories/game_repository.dart';
import '../theme/bingo_colors.dart';
import 'app_loading.dart';

Future<void> showDepositHistoryDialog(
  BuildContext context, {
  required String cashierId,
  required GameRepository gameRepository,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => DepositHistoryDialog(
      cashierId: cashierId,
      gameRepository: gameRepository,
    ),
  );
}

class DepositHistoryDialog extends StatefulWidget {
  const DepositHistoryDialog({
    super.key,
    required this.cashierId,
    required this.gameRepository,
  });

  final String cashierId;
  final GameRepository gameRepository;

  @override
  State<DepositHistoryDialog> createState() => _DepositHistoryDialogState();
}

class _DepositHistoryDialogState extends State<DepositHistoryDialog> {
  static const _recentLimit = 20;

  List<DepositLogRow> _logs = [];
  bool _loading = true;
  String _currencyCode = AppCurrency.defaultCode;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final results = await Future.wait([
      widget.gameRepository.listDepositLogs(
        cashierId: widget.cashierId,
        limit: _recentLimit,
      ),
      widget.gameRepository.getCashierProfile(widget.cashierId),
    ]);
    if (!mounted) return;
    setState(() {
      _logs = results[0] as List<DepositLogRow>;
      _currencyCode = AppCurrency.fromSettings(
        (results[1] as CashierProfile).settings,
      );
      _loading = false;
    });
  }

  String _shortTime(String ts) => ts.length >= 16 ? ts.substring(0, 16) : ts;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().strings;

    return Dialog(
      backgroundColor: BingoColors.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: SizedBox(
        width: 640,
        height: 480,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      s.depositHistoryTitle,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: _loading
                  ? AppLoadingView(message: s.loadingReport)
                  : _logs.isEmpty
                      ? Center(
                          child: Text(
                            s.noDepositHistory,
                            style: const TextStyle(
                              color: BingoColors.textSecondary,
                            ),
                          ),
                        )
                      : Column(
                          children: [
                            Container(
                              color: const Color(0xFF0F2E50),
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      s.action,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Text(
                                      s.amount,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      s.time,
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: ListView.separated(
                                itemCount: _logs.length,
                                separatorBuilder: (_, _) => const Divider(
                                  height: 1,
                                  color: Color(0xFF105350),
                                ),
                                itemBuilder: (_, i) {
                                  final log = _logs[i];
                                  final ok =
                                      log.status.toLowerCase() == 'success';
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 10,
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            s.depositLogActionLabel(log.action),
                                            style: TextStyle(
                                              fontWeight: FontWeight.w700,
                                              color: ok
                                                  ? (log.amount < 0
                                                      ? BingoColors.lastCalled
                                                      : BingoColors.primary)
                                                  : BingoColors.lastCalled,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          child: Text(
                                            '${AppNumberFormat.format(log.amount)} ${s.currencyLabel(_currencyCode)}',
                                            style: TextStyle(
                                              fontWeight: FontWeight.w600,
                                              color: log.amount < 0
                                                  ? BingoColors.lastCalled
                                                  : null,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            _shortTime(log.timestamp),
                                            style: const TextStyle(
                                              color: BingoColors.textSecondary,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
            ),
          ],
        ),
      ),
    );
  }
}
