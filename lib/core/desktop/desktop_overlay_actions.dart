import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

/// Optional top-right overlay action shown beside the desktop full-screen toggle.
class DesktopOverlayActions extends ChangeNotifier {
  String? _refreshTooltip;
  VoidCallback? _onRefresh;
  bool _refreshLoading = false;
  bool _playToolbarVisible = false;
  DesktopPlayToolbarState? _playToolbar;
  WidgetBuilder? _registerBarBuilder;
  bool _notifyScheduled = false;

  void _scheduleNotify() {
    if (_notifyScheduled) return;
    _notifyScheduled = true;
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _notifyScheduled = false;
      notifyListeners();
    });
  }
  String? get refreshTooltip => _refreshTooltip;
  VoidCallback? get onRefresh => _onRefresh;
  bool get refreshLoading => _refreshLoading;
  bool get hasRefresh => _onRefresh != null;
  DesktopPlayToolbarState? get playToolbar => _playToolbar;
  bool get hasPlayToolbar => _playToolbarVisible && _playToolbar != null;
  WidgetBuilder? get registerBarBuilder => _registerBarBuilder;
  bool get hasRegisterBar => _registerBarBuilder != null;

  void setRefresh({
    required String tooltip,
    required VoidCallback? onPressed,
    bool loading = false,
  }) {
    _refreshTooltip = tooltip;
    _onRefresh = onPressed;
    _refreshLoading = loading;
    _scheduleNotify();
  }

  void clearRefresh() {
    if (_onRefresh == null && !_refreshLoading && _refreshTooltip == null) {
      return;
    }
    _refreshTooltip = null;
    _onRefresh = null;
    _refreshLoading = false;
    _scheduleNotify();
  }

  void setPlayToolbar(DesktopPlayToolbarState state) {
    if (_samePlayToolbar(_playToolbar, state) && _playToolbarVisible) return;
    _playToolbarVisible = true;
    _playToolbar = state;
    _scheduleNotify();
  }

  void clearPlayToolbar() {
    if (!_playToolbarVisible && _playToolbar == null) return;
    _playToolbarVisible = false;
    _playToolbar = null;
    _scheduleNotify();
  }

  /// Compact register controls rendered inside the desktop top menu bar.
  void setRegisterBar(WidgetBuilder builder) {
    _registerBarBuilder = builder;
    _scheduleNotify();
  }

  void clearRegisterBar() {
    if (_registerBarBuilder == null) return;
    _registerBarBuilder = null;
    _scheduleNotify();
  }

  bool _samePlayToolbar(
    DesktopPlayToolbarState? current,
    DesktopPlayToolbarState? next,
  ) {
    if (identical(current, next)) return true;
    if (current == null || next == null) return false;
    return current.boardZoom == next.boardZoom &&
        current.minBoardZoom == next.minBoardZoom &&
        current.maxBoardZoom == next.maxBoardZoom &&
        current.zoomTooltip == next.zoomTooltip &&
        current.settingsLabel == next.settingsLabel &&
        current.settingsEnabled == next.settingsEnabled &&
        current.settingsBlockedReason == next.settingsBlockedReason &&
        current.showControlsLabel == next.showControlsLabel &&
        current.hideControlsLabel == next.hideControlsLabel;
  }
}

/// Play-screen controls rendered below the desktop full-screen button.
class DesktopPlayToolbarState {
  const DesktopPlayToolbarState({
    required this.boardZoom,
    required this.minBoardZoom,
    required this.maxBoardZoom,
    required this.zoomTooltip,
    required this.onZoomDecrease,
    required this.onZoomIncrease,
    required this.settingsLabel,
    required this.settingsEnabled,
    required this.onOpenSettings,
    required this.showControlsLabel,
    required this.hideControlsLabel,
    this.settingsBlockedReason,
  });

  final double boardZoom;
  final double minBoardZoom;
  final double maxBoardZoom;
  final String zoomTooltip;
  final VoidCallback onZoomDecrease;
  final VoidCallback onZoomIncrease;
  final String settingsLabel;
  final bool settingsEnabled;
  final VoidCallback onOpenSettings;
  final String showControlsLabel;
  final String hideControlsLabel;
  final String? settingsBlockedReason;
}
