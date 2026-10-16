import 'package:flutter/material.dart';

import '../theme/bingo_colors.dart';

enum AppToastType { info, success, warning, error }

void showAppToast(
  BuildContext context,
  String message, {
  AppToastType type = AppToastType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final overlay = Overlay.maybeOf(context);
  if (overlay == null) return;

  final media = MediaQuery.of(context);
  final top = media.viewPadding.top + 12;
  final maxWidth = media.size.width > 600 ? 360.0 : media.size.width - 24;
  final background = switch (type) {
    AppToastType.success => BingoColors.primary,
    AppToastType.warning => BingoColors.gold,
    AppToastType.error => BingoColors.lastCalled,
    AppToastType.info => BingoColors.surfaceLight,
  };
  final foreground = type == AppToastType.warning ? Colors.black : Colors.white;

  late final OverlayEntry entry;
  entry = OverlayEntry(
    builder: (ctx) => Positioned(
      top: top,
      left: 12,
      right: 12,
      child: Align(
        alignment: Alignment.topRight,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxWidth: maxWidth),
          child: Material(
            color: Colors.transparent,
            child: Dismissible(
              key: ValueKey(message),
              direction: DismissDirection.up,
              onDismissed: (_) => entry.remove(),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: background,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.35),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Text(
                  message,
                  style: TextStyle(
                    color: foreground,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    ),
  );

  overlay.insert(entry);
  Future.delayed(duration, () {
    if (entry.mounted) entry.remove();
  });
}
