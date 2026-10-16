import 'package:flutter/material.dart';

import '../../core/bingo/bingo_claim_mode.dart';
import '../../core/ui/modal_guard.dart';
import '../../core/l10n/app_strings.dart';
import '../theme/bingo_colors.dart';
import 'all_in_one_pattern_help_dialog.dart';

Future<void> showCheckCardHelpDialog(
  BuildContext context,
  AppStrings strings,
) {
  return ModalGuard.run(
    ModalKeys.checkCardHelp,
    () => showDialog<void>(
      context: context,
      useRootNavigator: true,
      barrierColor: Colors.black54,
      builder: (context) => _CheckCardHelpDialog(strings: strings),
    ),
  );
}

class _CheckCardHelpDialog extends StatelessWidget {
  const _CheckCardHelpDialog({required this.strings});

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
        child: DefaultTabController(
          length: 3,
          child: ColoredBox(
            color: Colors.white,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _HelpHeader(
                  title: strings.checkCardHelpTitle,
                  onClose: () => Navigator.of(context).pop(),
                ),
                TabBar(
                  labelColor: BingoColors.bgDark,
                  unselectedLabelColor: const Color(0xFF757575),
                  indicatorColor: BingoColors.accentRed,
                  indicatorWeight: 3,
                  labelStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                  unselectedLabelStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                  ),
                  tabs: [
                    Tab(text: strings.checkCardHelpTabScreen),
                    Tab(text: strings.checkCardHelpTabPatterns),
                    Tab(text: strings.checkCardHelpTabSettings),
                  ],
                ),
                Flexible(
                  child: TabBarView(
                    children: [
                      _ScreenHelpTab(strings: strings),
                      SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
                        child: PatternHelpContent(strings: strings),
                      ),
                      _SettingsHelpTab(strings: strings),
                    ],
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
      ),
    );
  }
}

class _ScreenHelpTab extends StatelessWidget {
  const _ScreenHelpTab({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _HelpSection(
            title: strings.checkCardHelpColorsTitle,
            body: strings.checkCardHelpColorsBody,
          ),
          const SizedBox(height: 18),
          _HelpSection(
            title: strings.checkCardHelpButtonsTitle,
            body: strings.checkCardHelpButtonsBody,
          ),
        ],
      ),
    );
  }
}

class _SettingsHelpTab extends StatelessWidget {
  const _SettingsHelpTab({required this.strings});

  final AppStrings strings;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            strings.checkCardHelpSettingsIntro,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              height: 1.35,
              color: BingoColors.accentTeal,
            ),
          ),
          const SizedBox(height: 16),
          _HelpSection(
            title: strings.checkingWinningCard,
            body: strings.checkingWinningCardHelp,
          ),
          const SizedBox(height: 18),
          _HelpSection(
            title: strings.bingoClaimTime,
            body:
                '${strings.bingoClaimModeHelp(BingoClaimMode.noRestriction)}\n\n'
                '${strings.bingoClaimModeHelp(BingoClaimMode.allowLaterPatterns)}\n\n'
                '${strings.bingoClaimModeHelp(BingoClaimMode.disqualifyOnMiss)}',
          ),
          const SizedBox(height: 18),
          _HelpSection(
            title: strings.callerVoice,
            body: strings.callerVoiceHelp,
          ),
          const SizedBox(height: 18),
          _HelpSection(
            title: strings.timeBetweenNumbers,
            body: strings.timeBetweenNumbersHelp,
          ),
        ],
      ),
    );
  }
}

class _HelpSection extends StatelessWidget {
  const _HelpSection({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7FA),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w800,
                color: BingoColors.bgDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              body,
              style: TextStyle(
                fontSize: 13,
                height: 1.45,
                color: Colors.black.withValues(alpha: 0.78),
              ),
            ),
          ],
        ),
      ),
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
