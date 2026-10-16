import 'package:shared_preferences/shared_preferences.dart';

class RegisterPrefs {
  static const _fontScaleKey = 'register_font_scale';
  static const _sidebarWidthKey = 'register_sidebar_width';

  static const minFontScale = 0.75;
  static const maxFontScale = 1.5;
  static const fontScaleStep = 0.05;
  static const defaultFontScale = 1.15;

  /// Right controls panel width (left card grid gets the rest).
  /// Lower default → wider card display.
  static const minSidebarWidth = 180.0;
  static const maxSidebarWidth = 900.0;
  static const defaultSidebarWidth = 280.0;

  static Future<double> loadFontScale() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getDouble(_fontScaleKey) ?? defaultFontScale)
        .clamp(minFontScale, maxFontScale);
  }

  static Future<void> saveFontScale(double scale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(
      _fontScaleKey,
      scale.clamp(minFontScale, maxFontScale),
    );
  }

  static Future<double> loadSidebarWidth() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getDouble(_sidebarWidthKey) ?? defaultSidebarWidth)
        .clamp(minSidebarWidth, maxSidebarWidth);
  }

  static Future<void> saveSidebarWidth(double width) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(
      _sidebarWidthKey,
      width.clamp(minSidebarWidth, maxSidebarWidth),
    );
  }
}
