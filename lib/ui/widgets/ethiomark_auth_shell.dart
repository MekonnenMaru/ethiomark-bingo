import 'package:flutter/material.dart';

import '../../core/performance/resource_budget.dart';
import '../layout/auth_layout.dart';
import '../layout/responsive_layout.dart';
import '../theme/auth_theme.dart';
import '../theme/bingo_colors.dart';
import '../widgets/app_card.dart';
import '../widgets/app_logo.dart';
import 'app_loading.dart';
import 'login_info_panel.dart';

/// Login / setup shell — professional split desktop, stacked mobile.

class EthiomarkAuthShell extends StatelessWidget {
  const EthiomarkAuthShell({
    super.key,
    this.title,
    required this.child,
    this.subtitle,
    this.brandTitle,
    this.footer,
    this.desktopSidePanel,
    this.showMobileNotices = false,
  });

  final String? title;
  final String? subtitle;
  final String? brandTitle;
  final Widget child;
  final Widget? footer;
  final Widget? desktopSidePanel;
  final bool showMobileNotices;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthTheme.pageBackground(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final showSidePanel = AuthLayout.showSidePanel(
              maxWidth: constraints.maxWidth,
              hasPanel: desktopSidePanel != null,
            );

            if (showSidePanel) {
              return Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    flex: AuthLayout.loginFlex,
                    child: Container(
                      decoration: BoxDecoration(
                        color: AuthTheme.panelBg.withValues(alpha: 0.92),
                        border: Border(
                          right: BorderSide(
                            color: Colors.white.withValues(alpha: 0.08),
                          ),
                        ),
                      ),
                      child: SafeArea(
                        child: Center(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 48,
                              vertical: 36,
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 420),
                              child: _buildAuthContent(showSidePanel: true),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: AuthLayout.noticeFlex,
                    child: RepaintBoundary(
                      child: SafeArea(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(40, 40, 48, 40),
                          child: desktopSidePanel!,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }

            return SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 32),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          padding: const EdgeInsets.fromLTRB(28, 32, 28, 28),
                          decoration: AuthTheme.panelDecoration(elevated: true),
                          child: _buildAuthContent(showSidePanel: false),
                        ),
                        if (showMobileNotices) ...[
                          const SizedBox(height: 20),
                          const AuthMobileNoticeExpander(),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAuthContent({required bool showSidePanel}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Center(child: AppLogo(size: showSidePanel ? 88 : 80)),
        const SizedBox(height: 14),
        if (brandTitle != null) ...[
          Text(
            brandTitle!,
            style: const TextStyle(
              fontSize: 17,
              color: AuthTheme.brandGold,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),
        ],
        if (title != null) ...[
          Text(
            title!,
            style: const TextStyle(
              fontSize: 32,
              color: AuthTheme.textPrimary,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle != null) const SizedBox(height: 8),
        ],
        if (subtitle != null) ...[
          Text(
            subtitle!,
            style: const TextStyle(
              fontSize: 14,
              color: AuthTheme.textSecondary,
              height: 1.45,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        SizedBox(height: title != null || subtitle != null ? 24 : 4),
        child,
        if (footer != null) ...[
          const SizedBox(height: 16),
          footer!,
        ],
      ],
    );
  }
}

/// Primary action button for login / setup.

class EthiomarkLoginButton extends StatelessWidget {
  const EthiomarkLoginButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null || loading;
    final reduceFx = ResourceBudget.reduceDecorations;
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: enabled && !reduceFx ? AuthTheme.primaryButtonGradient : null,
          color: !enabled
              ? AuthTheme.textMuted.withValues(alpha: 0.4)
              : (reduceFx ? AuthTheme.brandGold : null),
          borderRadius: BorderRadius.circular(10),
          boxShadow: enabled && !reduceFx
              ? [
                  BoxShadow(
                    color: AuthTheme.brandGold.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: loading ? null : onPressed,
            borderRadius: BorderRadius.circular(10),
            child: Center(
              child: loading
                  ? const AppButtonLoader(color: Color(0xFF1A1A1A), size: 24)
                  : Text(
                      label,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF1A1408),
                        letterSpacing: 0.3,
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Section card used in profile/settings desktop layout.

class EthiomarkSectionCard extends StatelessWidget {
  const EthiomarkSectionCard({
    super.key,
    required this.title,
    required this.child,
    this.trailing,
    this.compact = false,
    this.expanded = false,
  });

  final String title;
  final Widget child;
  final Widget? trailing;
  final bool compact;
  final bool expanded;

  @override
  Widget build(BuildContext context) {
    final desktop = context.isDesktop;

    final card = AppCard(
      padding: EdgeInsets.all(
        compact ? 12 : (desktop ? 16 : 12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 3,
                height: compact ? 16 : 20,
                color: BingoColors.accentTeal,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: compact
                        ? (desktop ? 14 : 13)
                        : (desktop ? 16 : 14),
                    fontWeight: FontWeight.w700,
                    color: BingoColors.gold,
                  ),
                ),
              ),
              ?trailing,
            ],
          ),
          Container(
            margin: EdgeInsets.symmetric(vertical: compact ? 8 : 10),
            height: 1,
            color: BingoColors.accentTeal.withValues(alpha: 0.45),
          ),
          if (expanded) Expanded(child: child) else child,
        ],
      ),
    );

    if (expanded) {
      return SizedBox.expand(child: card);
    }

    return card;
  }
}
