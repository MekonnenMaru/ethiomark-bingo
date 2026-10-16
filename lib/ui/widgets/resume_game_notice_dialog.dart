import 'package:flutter/material.dart';

import '../../core/l10n/app_strings.dart';
import '../theme/bingo_colors.dart';

/// Light-hearted reminder when an in-progress round is restored after reopen.
class ResumeGameNoticeDialog extends StatelessWidget {
  const ResumeGameNoticeDialog({
    super.key,
    required this.strings,
    required this.roundNumber,
    required this.calledCount,
  });

  final AppStrings strings;
  final int roundNumber;
  final int calledCount;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: BingoColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 18),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    BingoColors.bingoButtonStart,
                    BingoColors.bingoButtonEnd,
                  ],
                ),
              ),
              child: Column(
                children: [
                  const Icon(
                    Icons.casino_rounded,
                    size: 52,
                    color: Colors.black87,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    strings.resumeGameTitle,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Colors.black87,
                      height: 1.15,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Text(
                strings.resumeGameJoke(roundNumber),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: BingoColors.textSecondary,
                  height: 1.4,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: BingoColors.bgDark.withValues(alpha: 0.45),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: BingoColors.gold.withValues(alpha: 0.45)),
                ),
                child: Text(
                  strings.resumeGameStats(calledCount),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: BingoColors.gold,
                    height: 1.3,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
              child: SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton(
                  onPressed: () => Navigator.pop(context),
                  style: FilledButton.styleFrom(
                    backgroundColor: BingoColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    elevation: 3,
                  ),
                  child: Text(
                    strings.resumeGameContinue,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
