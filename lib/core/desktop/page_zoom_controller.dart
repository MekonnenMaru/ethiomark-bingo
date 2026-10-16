import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Browser-style whole-page zoom (Ctrl + / Ctrl − / Ctrl 0).
class PageZoomController extends ChangeNotifier {
  static const _prefsKey = 'app_page_zoom';
  static const minZoom = 0.7;
  static const maxZoom = 1.6;
  static const step = 0.1;
  static const defaultZoom = 1.0;

  double _zoom = defaultZoom;

  double get zoom => _zoom;

  int get percent => (_zoom * 100).round();

  bool get canZoomIn => _zoom < maxZoom - 0.001;

  bool get canZoomOut => _zoom > minZoom + 0.001;

  bool get isDefault => (_zoom - defaultZoom).abs() < 0.001;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _zoom = (prefs.getDouble(_prefsKey) ?? defaultZoom).clamp(minZoom, maxZoom);
    notifyListeners();
  }

  Future<void> zoomIn() => setZoom(_zoom + step);

  Future<void> zoomOut() => setZoom(_zoom - step);

  Future<void> reset() => setZoom(defaultZoom);

  Future<void> setZoom(double value) async {
    final next = (value * 10).round() / 10;
    final clamped = next.clamp(minZoom, maxZoom);
    if ((clamped - _zoom).abs() < 0.001) return;
    _zoom = clamped;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_prefsKey, _zoom);
  }
}
