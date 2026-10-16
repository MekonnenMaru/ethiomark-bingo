import 'package:flutter/material.dart';

import '../theme/bingo_colors.dart';

class GradientBackground extends StatelessWidget {
  const GradientBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: BingoColors.pageBackground),
      child: child,
    );
  }
}

class AppCard extends StatelessWidget {
  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            gradient: BingoColors.cardGradient,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: BingoColors.border),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

class TopStatBar extends StatelessWidget {
  const TopStatBar({
    super.key,
    required this.cashierId,
    required this.packageBalance,
    this.onSettings,
    this.onLogout,
  });

  final String cashierId;
  final String packageBalance;
  final VoidCallback? onSettings;
  final VoidCallback? onLogout;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 8),
      decoration: BoxDecoration(
        color: BingoColors.surface.withValues(alpha: 0.85),
        border: const Border(bottom: BorderSide(color: BingoColors.border)),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Package',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: BingoColors.textSecondary,
                    ),
                  ),
                  Text(
                    '$packageBalance birr',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: BingoColors.gold,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cashier',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: BingoColors.textSecondary,
                    ),
                  ),
                  Text(
                    cashierId,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
            if (onSettings != null)
              IconButton(
                icon: const Icon(Icons.settings_outlined),
                onPressed: onSettings,
              ),
            if (onLogout != null)
              IconButton(icon: const Icon(Icons.logout), onPressed: onLogout),
          ],
        ),
      ),
    );
  }
}
