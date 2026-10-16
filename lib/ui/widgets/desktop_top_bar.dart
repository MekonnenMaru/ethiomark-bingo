import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/config/app_version.dart';
import '../../core/desktop/desktop_overlay_actions.dart';
import '../../core/l10n/locale_controller.dart';
import '../theme/bingo_colors.dart';

/// Slim desktop header with menu, optional register controls, app name, and version.
class DesktopTopBar extends StatelessWidget {
  const DesktopTopBar({
    super.key,
    this.onMenuPressed,
  });

  final VoidCallback? onMenuPressed;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().strings;
    final overlay = context.watch<DesktopOverlayActions>();
    final registerBar = overlay.registerBarBuilder;

    // Leave room for the floating fullscreen toggle (top-right overlay).
    final rightPad = registerBar != null ? 52.0 : 4.0;

    return Container(
      height: 40,
      padding: EdgeInsets.fromLTRB(4, 0, rightPad, 0),
      decoration: BoxDecoration(
        color: BingoColors.bgDark.withValues(alpha: 0.92),
        border: Border(
          bottom: BorderSide(color: BingoColors.border.withValues(alpha: 0.6)),
        ),
      ),
      child: Row(
        children: [
          if (onMenuPressed != null) ...[
            IconButton(
              icon: const Icon(Icons.menu, size: 22),
              color: Colors.white,
              tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              onPressed: onMenuPressed,
            ),
            const SizedBox(width: 16),
          ],
          if (registerBar != null)
            Expanded(child: registerBar(context))
          else ...[
            Text(
              s.appName,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'v${AppVersion.version}',
              style: TextStyle(
                color: BingoColors.gold.withValues(alpha: 0.9),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
