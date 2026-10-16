import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/desktop/desktop_overlay_actions.dart';
import '../../core/desktop/desktop_window_controller.dart';
import '../../core/l10n/app_strings.dart';
import '../../core/l10n/locale_controller.dart';
import '../../core/performance/resource_budget.dart';
import '../layout/responsive_layout.dart';
import '../theme/bingo_colors.dart';
import 'desktop_play_toolbar_controls.dart';

/// Desktop-only overlay: top-right full-screen toggle on every route.
class DesktopFullscreenOverlay extends StatefulWidget {
  const DesktopFullscreenOverlay({super.key, required this.child});

  final Widget child;

  @override
  State<DesktopFullscreenOverlay> createState() => _DesktopFullscreenOverlayState();
}

class _DesktopFullscreenOverlayState extends State<DesktopFullscreenOverlay> {
  OverlayEntry? _overlayEntry;
  DesktopWindowController? _windowController;
  DesktopOverlayActions? _overlayActions;
  bool _overlayInsertScheduled = false;
  bool _overlayRebuildScheduled = false;

  @override
  void initState() {
    super.initState();
    if (DesktopWindowController.isSupported) {
      HardwareKeyboard.instance.addHandler(_handleGlobalShortcut);
    }
  }

  @override
  void dispose() {
    if (DesktopWindowController.isSupported) {
      HardwareKeyboard.instance.removeHandler(_handleGlobalShortcut);
    }
    _windowController?.removeListener(_scheduleOverlayRebuild);
    _overlayActions?.removeListener(_scheduleOverlayRebuild);
    _overlayEntry?.remove();
    _overlayEntry = null;
    super.dispose();
  }

  bool _handleGlobalShortcut(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (!DesktopWindowController.isSupported) return false;

    final controller = _windowController;
    if (controller == null) return false;

    if (event.logicalKey == LogicalKeyboardKey.f11) {
      controller.toggleFullScreen();
      return true;
    }

    if (event.logicalKey == LogicalKeyboardKey.escape &&
        controller.isFullScreen) {
      controller.setFullScreen(false);
      return true;
    }

    return false;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!DesktopWindowController.isSupported) return;

    final controller = context.read<DesktopWindowController>();
    if (!identical(_windowController, controller)) {
      _windowController?.removeListener(_scheduleOverlayRebuild);
      _windowController = controller;
      _windowController!.addListener(_scheduleOverlayRebuild);
    }

    final actions = context.read<DesktopOverlayActions>();
    if (!identical(_overlayActions, actions)) {
      _overlayActions?.removeListener(_scheduleOverlayRebuild);
      _overlayActions = actions;
      _overlayActions!.addListener(_scheduleOverlayRebuild);
    }

    _syncOverlay();
  }

  bool get _showOverlay =>
      DesktopWindowController.isSupported && context.isDesktop;

  void _syncOverlay() {
    if (!_showOverlay) {
      _overlayEntry?.remove();
      _overlayEntry = null;
      return;
    }

    _scheduleOverlayInsert();
  }

  void _scheduleOverlayInsert() {
    if (_overlayEntry != null || _overlayInsertScheduled) return;
    _overlayInsertScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _overlayInsertScheduled = false;
      if (!mounted) return;
      _insertOverlay();
    });
  }

  void _insertOverlay() {
    if (_overlayEntry != null) return;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) {
      _scheduleOverlayInsert();
      return;
    }

    final controller = _windowController;
    if (controller == null) return;

    _overlayEntry = OverlayEntry(
      builder: (overlayContext) => _DesktopTopRightToolbar(
        onToggleFullScreen: controller.toggleFullScreen,
      ),
    );
    overlay.insert(_overlayEntry!);
  }

  void _scheduleOverlayRebuild() {
    if (_overlayRebuildScheduled) return;
    _overlayRebuildScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _overlayRebuildScheduled = false;
      if (!mounted) return;
      _overlayEntry?.markNeedsBuild();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_showOverlay) return widget.child;

    return Shortcuts(
          shortcuts: const {
            SingleActivator(LogicalKeyboardKey.f11): ToggleFullScreenIntent(),
            SingleActivator(LogicalKeyboardKey.escape): ExitFullScreenIntent(),
          },
          child: Actions(
            actions: {
              ToggleFullScreenIntent: CallbackAction<ToggleFullScreenIntent>(
                onInvoke: (_) {
                  context.read<DesktopWindowController>().toggleFullScreen();
                  return null;
                },
              ),
              ExitFullScreenIntent: CallbackAction<ExitFullScreenIntent>(
                onInvoke: (_) {
                  final controller = context.read<DesktopWindowController>();
                  if (controller.isFullScreen) {
                    controller.setFullScreen(false);
                  }
                  return null;
                },
              ),
            },
            child: Focus(
              autofocus: true,
              canRequestFocus: true,
              child: widget.child,
            ),
          ),
        );
  }
}

class _DesktopTopRightToolbar extends StatefulWidget {
  const _DesktopTopRightToolbar({required this.onToggleFullScreen});

  final Future<void> Function() onToggleFullScreen;

  @override
  State<_DesktopTopRightToolbar> createState() =>
      _DesktopTopRightToolbarState();
}

class _DesktopTopRightToolbarState extends State<_DesktopTopRightToolbar> {
  bool _panelHidden = false;

  void _togglePanel() => setState(() => _panelHidden = !_panelHidden);

  @override
  Widget build(BuildContext context) {
    final window = context.watch<DesktopWindowController>();
    final actions = context.watch<DesktopOverlayActions>();
    final exiting = window.isFullScreen;

    if (actions.hasPlayToolbar) {
      final playState = actions.playToolbar!;

      return Positioned(
        top: exiting ? 6 : 4,
        right: 6,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            DesktopPlayToolbarEdgeTab(
              expanded: !_panelHidden,
              onPressed: _togglePanel,
              showTooltip: playState.showControlsLabel,
              hideTooltip: playState.hideControlsLabel,
            ),
            ClipRect(
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOutCubic,
                alignment: Alignment.centerRight,
                widthFactor: _panelHidden ? 0 : 1,
                child: SizedBox(
                  width: kDesktopPlayToolbarWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (actions.hasRefresh) ...[
                        _DesktopRefreshButton(
                          tooltip: actions.refreshTooltip ?? '',
                          loading: actions.refreshLoading,
                          onPressed: actions.onRefresh,
                          compact: true,
                        ),
                        const SizedBox(height: 6),
                      ],
                      DesktopPlayToolbarPanel(
                        fullscreenButton: _DesktopFullscreenButton(
                          onToggle: widget.onToggleFullScreen,
                          stretch: true,
                          compact: true,
                        ),
                        state: playState,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Positioned(
      top: exiting ? 6 : 4,
      right: 6,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (actions.hasRefresh) ...[
            _DesktopRefreshButton(
              tooltip: actions.refreshTooltip ?? '',
              loading: actions.refreshLoading,
              onPressed: actions.onRefresh,
            ),
            const SizedBox(width: 6),
          ],
          _DesktopFullscreenButton(onToggle: widget.onToggleFullScreen),
        ],
      ),
    );
  }
}

class _DesktopRefreshButton extends StatelessWidget {
  const _DesktopRefreshButton({
    required this.tooltip,
    required this.loading,
    required this.onPressed,
    this.compact = false,
  });

  final String tooltip;
  final bool loading;
  final VoidCallback? onPressed;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        elevation: 10,
        shadowColor: BingoColors.gold.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: loading ? null : onPressed,
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF4DD0E1),
                  Color(0xFF00ACC1),
                  Color(0xFF00838F),
                ],
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Padding(
              padding: compact
                  ? kDesktopPlayToolbarButtonPadding
                  : const EdgeInsets.all(5),
              child: loading
                  ? SizedBox(
                      width: compact ? kDesktopPlayToolbarIconSize : 18,
                      height: compact ? kDesktopPlayToolbarIconSize : 18,
                      child: const CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      Icons.refresh_rounded,
                      color: Colors.white,
                      size: compact ? kDesktopPlayToolbarIconSize : 18,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DesktopFullscreenButton extends StatefulWidget {
  const _DesktopFullscreenButton({
    required this.onToggle,
    this.stretch = false,
    this.compact = false,
    this.showLabel = false,
  });

  final Future<void> Function() onToggle;
  final bool stretch;
  final bool compact;
  final bool showLabel;

  @override
  State<_DesktopFullscreenButton> createState() => _DesktopFullscreenButtonState();
}

class _DesktopFullscreenButtonState extends State<_DesktopFullscreenButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    if (!ResourceBudget.reduceAnimations) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final window = context.watch<DesktopWindowController>();
    final s = context.watch<LocaleController>().strings;
    final exiting = window.isFullScreen;
    final content = _buttonContent(s, exiting);

    Widget shell(double glow) {
      return DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          boxShadow: ResourceBudget.reduceDecorations
              ? null
              : [
                  BoxShadow(
                    color: (exiting ? BingoColors.lastCalled : BingoColors.gold)
                        .withValues(alpha: glow),
                    blurRadius: 10 + (glow * 6),
                    spreadRadius: 1 + (glow * 2),
                  ),
                ],
        ),
        child: content,
      );
    }

    return Material(
      type: MaterialType.transparency,
      elevation: 12,
      shadowColor: BingoColors.gold.withValues(alpha: 0.9),
      child: ResourceBudget.reduceAnimations
          ? shell(0.7)
          : AnimatedBuilder(
              animation: _pulse,
              builder: (context, _) => shell(0.55 + (_pulse.value * 0.45)),
            ),
    );
  }

  Widget _buttonContent(AppStrings s, bool exiting) {
    return Tooltip(
      message: exiting
          ? '${s.exitFullScreen} (${s.fullScreenShortcut})'
          : '${s.enterFullScreen} (F11)',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => widget.onToggle(),
          borderRadius: BorderRadius.circular(8),
          child: Ink(
            width: widget.stretch ? double.infinity : null,
            height: widget.compact || widget.showLabel
                ? kDesktopPlayToolbarButtonHeight
                : null,
            decoration: BoxDecoration(
              gradient: ResourceBudget.reduceDecorations
                  ? null
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: exiting
                          ? const [
                              Color(0xFFFF8A80),
                              Color(0xFFE53935),
                              Color(0xFFB71C1C),
                            ]
                          : const [
                              Color(0xFFFFF59D),
                              Color(0xFFFFC107),
                              Color(0xFFFF9800),
                              Color(0xFFE65100),
                            ],
                    ),
              color: ResourceBudget.reduceDecorations
                  ? (exiting ? const Color(0xFFE53935) : const Color(0xFFFFC107))
                  : null,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.white, width: 1.5),
            ),
            child: Padding(
              padding: kDesktopPlayToolbarButtonPadding,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize:
                    widget.stretch ? MainAxisSize.max : MainAxisSize.min,
                children: [
                  Icon(
                    exiting ? Icons.fullscreen_exit : Icons.fullscreen,
                    color: exiting ? Colors.white : const Color(0xFF1A1A1A),
                    size: widget.compact || widget.showLabel
                        ? kDesktopPlayToolbarIconSize
                        : 18,
                    weight: 900,
                  ),
                  if (widget.showLabel) ...[
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        (exiting ? s.exitFullScreen : s.enterFullScreen)
                            .toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: exiting
                              ? Colors.white
                              : const Color(0xFF1A1A1A),
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
