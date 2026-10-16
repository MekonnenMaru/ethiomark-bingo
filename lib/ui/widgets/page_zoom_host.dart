import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../core/desktop/page_zoom_controller.dart';

/// Scales the whole app like a browser page zoom.
class PageZoomHost extends StatefulWidget {
  const PageZoomHost({super.key, required this.child});

  final Widget child;

  @override
  State<PageZoomHost> createState() => _PageZoomHostState();
}

class _PageZoomHostState extends State<PageZoomHost> {
  @override
  void initState() {
    super.initState();
    HardwareKeyboard.instance.addHandler(_handleShortcut);
  }

  @override
  void dispose() {
    HardwareKeyboard.instance.removeHandler(_handleShortcut);
    super.dispose();
  }

  bool _isZoomModifierPressed() {
    return HardwareKeyboard.instance.isControlPressed ||
        HardwareKeyboard.instance.isMetaPressed;
  }

  bool _handleShortcut(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    if (!_isZoomModifierPressed()) return false;

    final zoom = context.read<PageZoomController>();
    final key = event.logicalKey;

    if (key == LogicalKeyboardKey.equal ||
        key == LogicalKeyboardKey.add ||
        key == LogicalKeyboardKey.numpadAdd) {
      zoom.zoomIn();
      return true;
    }

    if (key == LogicalKeyboardKey.minus ||
        key == LogicalKeyboardKey.numpadSubtract) {
      zoom.zoomOut();
      return true;
    }

    if (key == LogicalKeyboardKey.digit0 || key == LogicalKeyboardKey.numpad0) {
      zoom.reset();
      return true;
    }

    return false;
  }

  void _handlePointerSignal(PointerSignalEvent event) {
    if (event is! PointerScrollEvent) return;
    if (!_isZoomModifierPressed()) return;

    GestureBinding.instance.pointerSignalResolver.register(event, (resolved) {
      if (!mounted) return;
      final scroll = resolved as PointerScrollEvent;
      final zoom = context.read<PageZoomController>();
      if (scroll.scrollDelta.dy < 0) {
        zoom.zoomIn();
      } else if (scroll.scrollDelta.dy > 0) {
        zoom.zoomOut();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final zoom = context.watch<PageZoomController>().zoom;
    final media = MediaQuery.of(context);

    Widget child = Listener(
      onPointerSignal: _handlePointerSignal,
      child: widget.child,
    );

    if ((zoom - 1.0).abs() < 0.001) return child;

    final logicalSize = Size(media.size.width / zoom, media.size.height / zoom);

    return MediaQuery(
      data: media.copyWith(size: logicalSize),
      child: FittedBox(
        fit: BoxFit.fill,
        alignment: Alignment.center,
        child: SizedBox(
          width: logicalSize.width,
          height: logicalSize.height,
          child: child,
        ),
      ),
    );
  }
}
