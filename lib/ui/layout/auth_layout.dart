import '../../core/desktop/desktop_window_controller.dart';

/// Side-by-side auth layout breakpoint (desktop OS only).
abstract final class AuthLayout {
  static const authCardWidth = 400.0;
  static const sidePanelWidth = 440.0;
  static const gap = 28.0;
  static const loginFlex = 5;
  static const noticeFlex = 6;

  static double combinedWidth(bool showSidePanel) {
    return showSidePanel ? authCardWidth + gap + sidePanelWidth : authCardWidth;
  }

  static bool showSidePanel({
    required double maxWidth,
    required bool hasPanel,
  }) {
    if (!hasPanel || !DesktopWindowController.isSupported) return false;
    return maxWidth >= combinedWidth(true) - 40;
  }
}
