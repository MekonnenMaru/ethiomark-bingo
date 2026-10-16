import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/bingo/bingo_claim_mode.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/l10n/locale_controller.dart';
import '../layout/responsive_layout.dart';
import '../theme/bingo_colors.dart';
import '../widgets/all_in_one_pattern_help_dialog.dart';
import '../widgets/app_card.dart';
import '../widgets/app_logo.dart';
import '../widgets/app_toast.dart';
import '../widgets/staged_screen_content.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({
    super.key,
    this.refreshToken = 0,
    this.isActive = true,
  });

  final int refreshToken;
  final bool isActive;

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;
  final ScrollController _helpsScrollController = ScrollController();
  final ScrollController _aboutScrollController = ScrollController();

  static const _helpContentMaxWidth = 720.0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
  }

  void _onTabChanged() {
    if (_tabController.indexIsChanging) return;
    setState(() {});
  }

  bool get _helpsTabActive =>
      widget.isActive && _tabController.index == 0;

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    _helpsScrollController.dispose();
    _aboutScrollController.dispose();
    super.dispose();
  }

  Future<void> _open(BuildContext context, Uri uri) async {
    final s = context.read<LocaleController>().strings;
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && context.mounted) {
        showAppToast(context, s.couldNotOpenLink, type: AppToastType.error);
      }
    } catch (_) {
      if (context.mounted) {
        showAppToast(context, s.couldNotOpenLink, type: AppToastType.error);
      }
    }
  }

  Widget _buildScrollableTab({
    required ScrollController controller,
    required bool desktop,
    required List<Widget> children,
  }) {
    if (desktop) {
      return Scrollbar(
        controller: controller,
        thumbVisibility: widget.isActive,
        child: SingleChildScrollView(
          controller: controller,
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: _helpContentMaxWidth),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: StagedScreenContent(steps: children),
              ),
            ),
          ),
        ),
      );
    }

    return ListView(
      controller: controller,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 20),
      children: [
        StagedScreenContent(
          mainAxisSize: MainAxisSize.min,
          steps: children,
        ),
      ],
    );
  }

  List<Widget> _buildHelpsTab(AppStrings s, bool desktop) {
    return [
      _HelpSectionCard(
        icon: Icons.casino_outlined,
        iconColor: BingoColors.accentTeal,
        title: s.patternHelpTitle,
        subtitle: s.patternHelpTooltip,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: PatternHelpContent(
              strings: s,
              isActive: _helpsTabActive,
            ),
          ),
        ),
      ),
      const SizedBox(height: 12),
      Text(
        s.helpGuidesTitle,
        style: TextStyle(
          fontSize: desktop ? 16 : 14,
          fontWeight: FontWeight.w800,
          color: BingoColors.textPrimary,
        ),
      ),
      const SizedBox(height: 8),
      _HelpSectionCard(
        icon: Icons.grid_on_rounded,
        iconColor: BingoColors.gold,
        title: s.checkCardHelpTitle,
        subtitle: s.checkCardHelpTooltip,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _HelpTextBlock(
              title: s.checkCardHelpColorsTitle,
              body: s.checkCardHelpColorsBody,
            ),
            const SizedBox(height: 10),
            _HelpTextBlock(
              title: s.checkCardHelpButtonsTitle,
              body: s.checkCardHelpButtonsBody,
            ),
            const SizedBox(height: 10),
            _HelpTextBlock(
              title: s.checkingWinningCard,
              body: s.checkingWinningCardHelp,
            ),
            const SizedBox(height: 10),
            _HelpTextBlock(
              title: s.bingoClaimTime,
              body:
                  '${s.bingoClaimModeHelp(BingoClaimMode.noRestriction)}\n\n'
                  '${s.bingoClaimModeHelp(BingoClaimMode.allowLaterPatterns)}\n\n'
                  '${s.bingoClaimModeHelp(BingoClaimMode.disqualifyOnMiss)}',
            ),
            const SizedBox(height: 10),
            _HelpTextBlock(
              title: s.callerVoice,
              body: s.callerVoiceHelp,
            ),
            const SizedBox(height: 10),
            _HelpTextBlock(
              title: s.timeBetweenNumbers,
              body: s.timeBetweenNumbersHelp,
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _HelpSectionCard(
        icon: Icons.keyboard_outlined,
        iconColor: BingoColors.primary,
        title: s.registerCards,
        subtitle: s.keyboardHint,
        child: _HelpTextBlock(
          title: s.keyboardHint,
          body: s.emptySelectionHint,
        ),
      ),
    ];
  }

  List<Widget> _buildAboutTab(AppStrings s, bool desktop) {
    return [
      _HeroHeader(
        desktop: desktop,
        tagline: s.aboutTagline,
        appName: s.appName,
      ),
      const SizedBox(height: 12),
      _HelpSectionCard(
        icon: Icons.support_agent_rounded,
        iconColor: BingoColors.accentRed,
        title: s.contact,
        subtitle: s.contactSubtitle,
        child: Column(
          children: [
            _HelpLinkTile(
              icon: Icons.email_rounded,
              accent: BingoColors.columnNText,
              title: 'meka2967@gmail.com',
              subtitle: s.tapToEmail,
              onTap: () =>
                  _open(context, Uri.parse('mailto:meka2967@gmail.com')),
            ),
            const SizedBox(height: 8),
            _HelpLinkTile(
              icon: Icons.send_rounded,
              accent: const Color(0xFF29B6F6),
              title: s.telegramBingoBot,
              subtitle: 't.me/Maraki_bingo_bot',
              onTap: () =>
                  _open(context, Uri.parse('https://t.me/Maraki_bingo_bot')),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _HelpSectionCard(
        icon: Icons.cloud_rounded,
        iconColor: BingoColors.columnB,
        title: s.online,
        subtitle: s.onlineSubtitle,
        child: Column(
          children: [
            _HelpLinkTile(
              icon: Icons.language_rounded,
              accent: BingoColors.primary,
              title: s.appName,
              subtitle: 'ethiomark.com',
              onTap: () => _open(context, Uri.parse('https://ethiomark.com')),
            ),
            const SizedBox(height: 8),
            _HelpLinkTile(
              icon: Icons.stars_rounded,
              accent: BingoColors.gold,
              title: s.onlineCasino,
              subtitle: 'feresbet.com',
              onTap: () => _open(context, Uri.parse('https://feresbet.com')),
            ),
          ],
        ),
      ),
      const SizedBox(height: 12),
      _HelpSectionCard(
        icon: Icons.offline_bolt_rounded,
        iconColor: BingoColors.primary,
        title: s.offlineSystem,
        subtitle: s.offlineSystemSubtitle,
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            _ProductChip(
              label: s.bingo,
              icon: Icons.grid_on_rounded,
              color: BingoColors.gold,
            ),
            _ProductChip(
              label: s.keno,
              icon: Icons.casino_rounded,
              color: const Color(0xFF64B5F6),
            ),
            _ProductChip(
              label: s.spin,
              icon: Icons.sync_rounded,
              color: BingoColors.primary,
            ),
          ],
        ),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().strings;
    final desktop = context.isDesktop;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: BingoColors.bgDark,
          child: TabBar(
            controller: _tabController,
            labelColor: BingoColors.gold,
            unselectedLabelColor:
                BingoColors.textSecondary.withValues(alpha: 0.85),
            indicatorColor: BingoColors.gold,
            indicatorWeight: 3,
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            tabs: [
              Tab(text: s.helpTabHelps),
              Tab(text: s.helpTabAbout),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildScrollableTab(
                controller: _helpsScrollController,
                desktop: desktop,
                children: _buildHelpsTab(s, desktop),
              ),
              _buildScrollableTab(
                controller: _aboutScrollController,
                desktop: desktop,
                children: _buildAboutTab(s, desktop),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HeroHeader extends StatelessWidget {
  const _HeroHeader({
    required this.desktop,
    required this.tagline,
    required this.appName,
  });

  final bool desktop;
  final String tagline;
  final String appName;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        desktop ? 0 : 0,
        desktop ? 0 : 0,
        desktop ? 0 : 0,
        desktop ? 0 : 4,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -20,
            top: -10,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    BingoColors.primary.withValues(alpha: 0.25),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          AppCard(
            padding: EdgeInsets.all(desktop ? 20 : 16),
            child: Row(
              children: [
                AppLogo(size: desktop ? 72 : 60, circular: true, padding: 4),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        appName,
                        style: TextStyle(
                          fontSize: desktop ? 22 : 18,
                          fontWeight: FontWeight.w900,
                          color: BingoColors.gold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        tagline,
                        style: TextStyle(
                          fontSize: desktop ? 14 : 12,
                          color: BingoColors.textSecondary.withValues(alpha: 0.95),
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HelpSectionCard extends StatelessWidget {
  const _HelpSectionCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: BingoColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: BingoColors.textSecondary.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _HelpTextBlock extends StatelessWidget {
  const _HelpTextBlock({required this.title, required this.body});

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 13,
            color: BingoColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          body,
          style: TextStyle(
            fontSize: 12,
            height: 1.45,
            color: BingoColors.textSecondary.withValues(alpha: 0.95),
          ),
        ),
      ],
    );
  }
}

class _HelpLinkTile extends StatelessWidget {
  const _HelpLinkTile({
    required this.icon,
    required this.accent,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final Color accent;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: accent.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(icon, color: accent, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 14,
                        color: BingoColors.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: BingoColors.textSecondary.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.open_in_new,
                size: 16,
                color: BingoColors.textSecondary.withValues(alpha: 0.55),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductChip extends StatelessWidget {
  const _ProductChip({
    required this.label,
    required this.icon,
    required this.color,
  });

  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}