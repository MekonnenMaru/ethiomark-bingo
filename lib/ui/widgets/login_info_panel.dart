import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/auth/auth_info_controller.dart';
import '../../core/config/app_version.dart';
import '../../core/desktop/desktop_overlay_actions.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/network/user_facing_error.dart';
import '../layout/responsive_layout.dart';
import '../theme/auth_theme.dart';
import '../theme/bingo_colors.dart';

/// Mobile: collapsible notices below login/setup form.
class AuthMobileNoticeExpander extends StatefulWidget {
  const AuthMobileNoticeExpander({super.key});

  @override
  State<AuthMobileNoticeExpander> createState() =>
      _AuthMobileNoticeExpanderState();
}

class _AuthMobileNoticeExpanderState extends State<AuthMobileNoticeExpander> {
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AuthInfoController>().refreshIfOnline();
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().strings;
    final info = context.watch<AuthInfoController>();
    final count = info.feedNotices.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Material(
          color: AuthTheme.panelBg.withValues(alpha: 0.65),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: AuthTheme.panelBorder),
          ),
          child: InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              child: Row(
                children: [
                  Icon(
                    Icons.notifications_outlined,
                    color: AuthTheme.brandGold.withValues(alpha: 0.95),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _expanded
                          ? s.loginInfoShowLess
                          : s.loginInfoSeeNotices(count),
                      style: const TextStyle(
                        color: AuthTheme.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up_rounded
                        : Icons.keyboard_arrow_down_rounded,
                    color: AuthTheme.brandGold,
                    size: 26,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_expanded) ...[
          const SizedBox(height: 16),
          const AuthWelcomeBlock(compact: true),
          const SizedBox(height: 20),
          const AuthRemoteNoticeList(compact: true),
        ],
      ],
    );
  }
}

/// Remote notices with pagination (login & setup).
class AuthRemoteNoticeList extends StatefulWidget {
  const AuthRemoteNoticeList({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  State<AuthRemoteNoticeList> createState() => _AuthRemoteNoticeListState();
}

class _AuthRemoteNoticeListState extends State<AuthRemoteNoticeList> {
  int _page = 0;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().strings;
    final info = context.watch<AuthInfoController>();
    final notices = info.feedNotices;
    final totalPages = info.totalPages;
    final page = _page.clamp(0, math.max(0, totalPages - 1)).toInt();

    final pageNotices = info.pageSlice(page);
    final showPagination = notices.length > AuthInfoController.messagesPerPage;
    final showInlineRefresh = !context.isDesktop;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
            Row(
              children: [
                Icon(
                  Icons.notifications_active_outlined,
                  color: AuthTheme.brandGold.withValues(alpha: 0.9),
                  size: widget.compact ? 16 : 18,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    s.loginInfoRemoteTitle,
                    style: const TextStyle(
                      color: AuthTheme.brandGold,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                if (info.fromCache)
                  Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: Tooltip(
                      message: s.loginInfoCachedHint,
                      child: Icon(
                        Icons.cloud_off_outlined,
                        size: 16,
                        color: AuthTheme.textMuted,
                      ),
                    ),
                  ),
                if (showInlineRefresh)
                  _RefreshButton(
                    loading: info.loading,
                    tooltip: s.loginInfoRefresh,
                    onPressed: () => info.refreshIfOnline(),
                  ),
              ],
            ),
            if (notices.isNotEmpty) ...[
              SizedBox(height: widget.compact ? 12 : 16),
              for (var i = 0; i < pageNotices.length; i++) ...[
                if (i > 0) ...[
                  SizedBox(height: widget.compact ? 14 : 20),
                  Divider(
                    color: AuthTheme.panelBorder,
                    height: 1,
                  ),
                  SizedBox(height: widget.compact ? 14 : 20),
                ],
                _RemoteNoticeCard(
                  title: pageNotices[i].title,
                  body: pageNotices[i].body,
                  messageType: pageNotices[i].messageType,
                  compact: widget.compact,
                ),
              ],
              if (showPagination) ...[
                const SizedBox(height: 8),
                _PaginationBar(
                  page: page,
                  totalPages: totalPages,
                  pageLabel: s.loginInfoPageOf(page + 1, totalPages),
                  previousLabel: s.loginInfoPrevious,
                  nextLabel: s.loginInfoNext,
                  onPrevious: page > 0
                      ? () => setState(() => _page = page - 1)
                      : null,
                  onNext: page < totalPages - 1
                      ? () => setState(() => _page = page + 1)
                      : null,
                ),
              ],
            ] else if (!info.loading) ...[
              SizedBox(height: widget.compact ? 8 : 10),
              Text(
                info.lastNetworkError != null
                    ? networkErrorMessage(info.lastNetworkError!, s)
                    : s.loginInfoNoRemoteMessage,
                style: TextStyle(
                  color: info.lastNetworkError != null
                      ? BingoColors.lastCalled.withValues(alpha: 0.9)
                      : AuthTheme.textMuted,
                  fontSize: widget.compact ? 12 : 11,
                  height: 1.35,
                ),
              ),
            ],
            if (info.loading && notices.isEmpty) ...[
              const SizedBox(height: 12),
              const Center(
                child: SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: AuthTheme.brandGold,
                  ),
                ),
              ),
            ],
          ],
    );
  }
}

/// Back-compat wrapper.
class AuthRemoteNoticeStrip extends StatelessWidget {
  const AuthRemoteNoticeStrip({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    return AuthRemoteNoticeList(compact: compact);
  }
}

class _PaginationBar extends StatelessWidget {
  const _PaginationBar({
    required this.page,
    required this.totalPages,
    required this.pageLabel,
    required this.previousLabel,
    required this.nextLabel,
    required this.onPrevious,
    required this.onNext,
  });

  final int page;
  final int totalPages;
  final String pageLabel;
  final String previousLabel;
  final String nextLabel;
  final VoidCallback? onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _PageButton(
          icon: Icons.chevron_left_rounded,
          label: previousLabel,
          onPressed: onPrevious,
        ),
        Expanded(
          child: Text(
            pageLabel,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AuthTheme.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        _PageButton(
          icon: Icons.chevron_right_rounded,
          label: nextLabel,
          onPressed: onNext,
        ),
      ],
    );
  }
}

class _PageButton extends StatelessWidget {
  const _PageButton({
    required this.icon,
    required this.label,
    required this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: label,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, size: 22),
        style: IconButton.styleFrom(
          foregroundColor: AuthTheme.brandGold,
          disabledForegroundColor: AuthTheme.textMuted,
          minimumSize: const Size(40, 36),
        ),
      ),
    );
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({
    required this.loading,
    required this.tooltip,
    required this.onPressed,
  });

  final bool loading;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: IconButton(
        onPressed: loading ? null : onPressed,
        icon: loading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AuthTheme.brandGold,
                ),
              )
            : const Icon(
                Icons.refresh_rounded,
                color: AuthTheme.brandGold,
                size: 22,
              ),
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        visualDensity: VisualDensity.compact,
      ),
    );
  }
}

/// Welcome / feature panel beside login & setup on desktop.
class AuthInfoPanel extends StatefulWidget {
  const AuthInfoPanel({
    super.key,
    this.compact = false,
  });

  /// Setup screen — messages only, no long marketing blocks.
  final bool compact;

  @override
  State<AuthInfoPanel> createState() => _AuthInfoPanelState();
}

class _AuthInfoPanelState extends State<AuthInfoPanel> {
  AuthInfoController? _authInfo;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _authInfo = context.read<AuthInfoController>();
      _authInfo!.addListener(_syncOverlayRefresh);
      _authInfo!.refreshIfOnline();
      _syncOverlayRefresh();
    });
  }

  @override
  void deactivate() {
    _authInfo?.removeListener(_syncOverlayRefresh);
    context.read<DesktopOverlayActions>().clearRefresh();
    super.deactivate();
  }

  void _syncOverlayRefresh() {
    if (!mounted || !context.isDesktop) return;
    final s = context.read<LocaleController>().strings;
    final info = context.read<AuthInfoController>();
    context.read<DesktopOverlayActions>().setRefresh(
          tooltip: s.loginInfoRefresh,
          onPressed: info.loading ? null : info.refreshIfOnline,
          loading: info.loading,
        );
  }

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().strings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        AuthWelcomeBlock(compact: widget.compact),
        SizedBox(height: widget.compact ? 20 : 28),
        AuthRemoteNoticeList(compact: widget.compact),
        if (widget.compact) ...[
          const SizedBox(height: 16),
          Text(
            '${s.loginInfoVersionLabel} v${AppVersion.version}',
            style: TextStyle(
              color: AuthTheme.textMuted,
              fontSize: 11,
            ),
          ),
        ],
      ],
    );
  }
}

/// Pinned welcome block — remote/cache welcome when available, else localized copy.
class AuthWelcomeBlock extends StatelessWidget {
  const AuthWelcomeBlock({
    super.key,
    this.compact = false,
  });

  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().strings;
    final remote = context.watch<AuthInfoController>().pinnedWelcome;

    if (remote != null) {
      return _RemoteWelcomeCard(
        title: remote.title,
        body: remote.body,
        compact: compact,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          s.loginInfoWelcome,
          style: TextStyle(
            color: AuthTheme.textPrimary,
            fontSize: compact ? 18 : 26,
            fontWeight: FontWeight.w800,
            height: 1.2,
          ),
        ),
        SizedBox(height: compact ? 6 : 10),
        Text(
          s.loginInfoTagline,
          style: TextStyle(
            color: AuthTheme.textSecondary,
            fontSize: compact ? 12.5 : 14,
            height: 1.45,
          ),
        ),
        if (!compact) ...[
          const SizedBox(height: 18),
          Text(
            '${s.loginInfoVersionLabel} v${AppVersion.version}',
            style: TextStyle(
              color: AuthTheme.brandGold.withValues(alpha: 0.85),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),
          _InfoSection(
            icon: Icons.sports_esports_outlined,
            title: s.loginInfoOurGamesTitle,
            body: s.loginInfoOurGamesBody,
          ),
          const SizedBox(height: 18),
          _InfoSection(
            icon: Icons.casino_outlined,
            title: s.loginInfoGamesTitle,
            body: s.loginInfoGamesBody,
          ),
          const SizedBox(height: 18),
          _InfoSection(
            icon: Icons.star_outline_rounded,
            title: s.loginInfoFeaturesTitle,
            body: s.loginInfoFeaturesBody,
          ),
        ],
      ],
    );
  }
}

class _RemoteWelcomeCard extends StatelessWidget {
  const _RemoteWelcomeCard({
    required this.title,
    required this.body,
    required this.compact,
  });

  final String title;
  final String body;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final s = context.watch<LocaleController>().strings;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              Icons.push_pin_rounded,
              color: AuthTheme.brandGold.withValues(alpha: 0.95),
              size: compact ? 16 : 18,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title.isNotEmpty ? title : s.loginInfoWelcome,
                style: TextStyle(
                  color: AuthTheme.textPrimary,
                  fontSize: compact ? 18 : 26,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
              ),
            ),
          ],
        ),
        if (body.isNotEmpty) ...[
          SizedBox(height: compact ? 8 : 10),
          Text(
            body,
            style: TextStyle(
              color: AuthTheme.textSecondary,
              fontSize: compact ? 12.5 : 13.5,
              height: 1.5,
            ),
          ),
        ],
        if (!compact) ...[
          const SizedBox(height: 14),
          Text(
            '${s.loginInfoVersionLabel} v${AppVersion.version}',
            style: TextStyle(
              color: AuthTheme.brandGold.withValues(alpha: 0.85),
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );
  }
}

/// Back-compat alias.
typedef LoginInfoPanel = AuthInfoPanel;

class _RemoteNoticeCard extends StatelessWidget {
  const _RemoteNoticeCard({
    required this.title,
    required this.body,
    required this.messageType,
    this.compact = false,
  });

  final String title;
  final String body;
  final String messageType;
  final bool compact;

  Color get _accent {
    switch (messageType) {
      case 'warning':
        return BingoColors.lastCalled;
      case 'announcement':
        return BingoColors.accentTeal;
      case 'info':
        return const Color(0xFF64B5F6);
      default:
        return BingoColors.gold;
    }
  }

  IconData get _icon {
    switch (messageType) {
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'announcement':
        return Icons.campaign_outlined;
      case 'info':
        return Icons.info_outline;
      default:
        return Icons.notifications_active_outlined;
    }
  }

  String get _typeLabel {
    switch (messageType) {
      case 'warning':
        return 'Warning';
      case 'announcement':
        return 'Announcement';
      case 'info':
        return 'Info';
      default:
        return 'Notice';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: compact ? 12 : 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(_icon, color: _accent, size: compact ? 18 : 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title.isNotEmpty)
                      Text(
                        title,
                        style: TextStyle(
                          color: AuthTheme.textPrimary,
                          fontSize: compact ? 14 : 16,
                          fontWeight: FontWeight.w700,
                          height: 1.25,
                        ),
                      ),
                    const SizedBox(height: 4),
                    Text(
                      _typeLabel,
                      style: TextStyle(
                        color: _accent.withValues(alpha: 0.9),
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (body.isNotEmpty) ...[
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(left: 30),
              child: Text(
                body,
                style: TextStyle(
                  color: AuthTheme.textSecondary,
                  fontSize: compact ? 12.5 : 13.5,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: AuthTheme.brandGold, size: 18),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                style: const TextStyle(
                  color: AuthTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          body,
          style: TextStyle(
            color: AuthTheme.textSecondary,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
