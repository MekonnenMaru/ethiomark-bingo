import 'package:flutter/material.dart';

import '../../core/desktop/desktop_overlay_actions.dart';
import '../theme/bingo_colors.dart';
import 'blocked_action_tooltip.dart';

const double kDesktopPlayToolbarWidth = 52;
const double kDesktopPlayToolbarTabWidth = 18;
const double kDesktopPlayToolbarButtonHeight = 36;
const double kDesktopPlayToolbarIconSize = 20;
const EdgeInsets kDesktopPlayToolbarButtonPadding =
    EdgeInsets.symmetric(horizontal: 4, vertical: 6);
const double kDesktopPlayToolbarZoomRowHeight = 26;
const EdgeInsets kDesktopPlayToolbarZoomPadding =
    EdgeInsets.symmetric(horizontal: 3, vertical: 2);

/// Space to reserve beside the prize box so overlay controls do not cover it.
double get kDesktopPlayToolbarReservedWidth =>
    kDesktopPlayToolbarWidth + kDesktopPlayToolbarTabWidth + 14;

/// Slide-out play toolbar panel: fullscreen, settings, vertical zoom.
class DesktopPlayToolbarPanel extends StatelessWidget {
  const DesktopPlayToolbarPanel({
    super.key,
    required this.fullscreenButton,
    required this.state,
  });

  final Widget fullscreenButton;
  final DesktopPlayToolbarState state;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        fullscreenButton,
        const SizedBox(height: 4),
        _buildSettingsButton(),
        const SizedBox(height: 4),
        _buildVerticalZoom(),
      ],
    );
  }

  Widget _buildSettingsButton() {
    final enabled = state.settingsEnabled;
    final iconColor =
        enabled ? BingoColors.gold : BingoColors.gold.withValues(alpha: 0.45);
    final borderColor = enabled
        ? BingoColors.lastCalled
        : BingoColors.lastCalled.withValues(alpha: 0.55);

    Widget button = _toolbarButton(
      onTap: enabled ? state.onOpenSettings : null,
      borderColor: borderColor,
      borderWidth: 2,
      child: Icon(
        Icons.settings,
        color: iconColor,
        size: kDesktopPlayToolbarIconSize,
      ),
    );

    button = Tooltip(message: state.settingsLabel, child: button);

    if (state.settingsBlockedReason != null) {
      button = BlockedActionTooltip(
        reason: state.settingsBlockedReason,
        child: button,
      );
    }

    return button;
  }

  Widget _buildVerticalZoom() {
    final percent = (state.boardZoom * 100).round();
    final canDecrease = state.boardZoom > state.minBoardZoom + 0.001;
    final canIncrease = state.boardZoom < state.maxBoardZoom - 0.001;

    return Tooltip(
      message: state.zoomTooltip,
      child: Container(
        padding: kDesktopPlayToolbarZoomPadding,
        decoration: BoxDecoration(
          color: const Color(0xFF0F2E50),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: BingoColors.accentTeal.withValues(alpha: 0.6),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _zoomTap(
              label: '−',
              enabled: canDecrease,
              onTap: state.onZoomDecrease,
              roundedTop: true,
            ),
            Container(
              height: kDesktopPlayToolbarZoomRowHeight,
              alignment: Alignment.center,
              child: Text(
                '$percent%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  decoration: TextDecoration.none,
                ),
              ),
            ),
            _zoomTap(
              label: '+',
              enabled: canIncrease,
              onTap: state.onZoomIncrease,
              roundedBottom: true,
            ),
          ],
        ),
      ),
    );
  }

  Widget _zoomTap({
    required String label,
    required bool enabled,
    required VoidCallback onTap,
    bool roundedTop = false,
    bool roundedBottom = false,
  }) {
    BorderRadius? radius;
    if (roundedTop) {
      radius = const BorderRadius.vertical(top: Radius.circular(7));
    } else if (roundedBottom) {
      radius = const BorderRadius.vertical(bottom: Radius.circular(7));
    }

    return Material(
      color: enabled
          ? BingoColors.accentTeal.withValues(alpha: 0.22)
          : BingoColors.accentTeal.withValues(alpha: 0.08),
      borderRadius: radius,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: radius,
        child: SizedBox(
          height: kDesktopPlayToolbarZoomRowHeight,
          width: double.infinity,
          child: Center(
            child: Text(
              label,
              style: TextStyle(
                color: Colors.white.withValues(alpha: enabled ? 1 : 0.45),
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _toolbarButton({
    required Widget child,
    required VoidCallback? onTap,
    Color? borderColor,
    double borderWidth = 1.2,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          height: kDesktopPlayToolbarButtonHeight,
          padding: kDesktopPlayToolbarButtonPadding,
          decoration: BoxDecoration(
            color: const Color(0xFF0F2E50),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: borderColor ?? Colors.white.withValues(alpha: 0.25),
              width: borderWidth,
            ),
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

/// Mini tab on the left edge of the panel; stays visible when panel collapses.
class DesktopPlayToolbarEdgeTab extends StatelessWidget {
  const DesktopPlayToolbarEdgeTab({
    super.key,
    required this.expanded,
    required this.onPressed,
    required this.showTooltip,
    required this.hideTooltip,
  });

  final bool expanded;
  final VoidCallback onPressed;
  final String showTooltip;
  final String hideTooltip;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: expanded ? hideTooltip : showTooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: const BorderRadius.horizontal(
            left: Radius.circular(8),
          ),
          child: Ink(
            width: kDesktopPlayToolbarTabWidth,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF0F2E50),
              borderRadius: const BorderRadius.horizontal(
                left: Radius.circular(8),
              ),
              border: Border.all(
                color: BingoColors.gold.withValues(alpha: 0.85),
                width: 1.2,
              ),
            ),
            child: Center(
              child: Icon(
                expanded ? Icons.chevron_right : Icons.chevron_left,
                color: BingoColors.gold,
                size: 18,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
