import 'package:flutter/material.dart';

import '../theme/bingo_colors.dart';

Future<void> showWalletExceededAlert(
  BuildContext context, {
  required String message,
  required String reportLabel,
  required String closeLabel,
  VoidCallback? onOpenReport,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: BingoColors.surface,
      title: Text(
        message,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w700,
          height: 1.4,
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(
            closeLabel,
            style: const TextStyle(color: BingoColors.textSecondary),
          ),
        ),
        if (onOpenReport != null)
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              onOpenReport();
            },
            style: FilledButton.styleFrom(
              backgroundColor: BingoColors.gold,
              foregroundColor: Colors.black,
            ),
            child: Text(
              reportLabel,
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
          ),
      ],
    ),
  );
}

bool isWalletExceededResult(Map<String, dynamic> result) =>
    result['code'] == 'wallet_exceeded';
