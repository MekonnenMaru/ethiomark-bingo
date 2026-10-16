import 'package:flutter/material.dart';

/// Breakpoints aligned with ethiomark web CSS (desktop-first at ~900px+).
abstract final class AppBreakpoints {
  static const double desktop = 900;
  static const double wide = 1280;
  static const double contentMaxWidth = 1700;
}

extension ResponsiveContext on BuildContext {
  double get screenWidth => MediaQuery.sizeOf(this).width;
  double get screenHeight => MediaQuery.sizeOf(this).height;
  bool get isDesktop => screenWidth >= AppBreakpoints.desktop;
  bool get isWide => screenWidth >= AppBreakpoints.wide;
  /// Phone-width layouts (overflow-prone toolbars).
  bool get isNarrowMobile =>
      screenWidth < AppBreakpoints.desktop && screenWidth < 400;
}

/// Centers content on wide screens while allowing full bleed on mobile.
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.maxWidth = AppBreakpoints.contentMaxWidth,
    this.padding = const EdgeInsets.symmetric(horizontal: 16),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
