import 'package:flutter/material.dart';

import '../../core/ui/modal_guard.dart';
import '../../core/l10n/app_strings.dart';
import '../theme/bingo_colors.dart';
import 'pattern_help_animator.dart';

Future<void> showAllInOnePatternHelpDialog(
  BuildContext context,
  AppStrings s,
) {
  return ModalGuard.run(
    ModalKeys.patternHelp,
    () => showDialog<void>(
      context: context,
      barrierColor: Colors.black54,
      builder: (context) => _PatternHelpDialog(strings: s),
    ),
  );
}

class _PatternHelpDialog extends StatelessWidget {
  const _PatternHelpDialog({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    final screen = MediaQuery.sizeOf(context);
    final maxHeight = screen.height * 0.88;
    final wide = screen.width >= 560;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: wide ? 620 : 420,
          maxHeight: maxHeight,
        ),
        child: ColoredBox(
          color: Colors.white,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _HelpHeader(
                title: strings.patternHelpTitle,
                onClose: () => Navigator.of(context).pop(),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                  child: PatternHelpContent(strings: strings, isActive: true),
                ),
              ),
              const Divider(height: 1),
              ColoredBox(
                color: Colors.white,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 4, 12, 10),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: FilledButton.styleFrom(
                        backgroundColor: BingoColors.accentRed,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 22,
                          vertical: 10,
                        ),
                      ),
                      child: Text(strings.close),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Scrollable win-pattern guide — reused in register game, check-card, and help.
class PatternHelpContent extends StatelessWidget {
  const PatternHelpContent({
    super.key,
    required this.strings,
    this.isActive = true,
  });

  final AppStrings strings;
  final bool isActive;

  @override
  Widget build(BuildContext context) {
    return PatternHelpLiveSection(
      strings: strings,
      isActive: isActive,
    );
  }
}

class _HelpHeader extends StatelessWidget {
  const _HelpHeader({required this.title, required this.onClose});

  final String title;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Colors.black.withValues(alpha: 0.1)),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: BingoColors.bgDark,
                height: 1.2,
              ),
            ),
          ),
          IconButton(
            onPressed: onClose,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.close, size: 20),
            color: BingoColors.bgDark,
            tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
          ),
        ],
      ),
    );
  }
}
