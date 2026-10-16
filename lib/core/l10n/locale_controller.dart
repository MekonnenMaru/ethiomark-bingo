import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_language.dart';
import 'app_strings.dart';

class LocaleController extends ChangeNotifier {
  static const _prefsKey = 'app_language';

  AppLanguage _language = AppLanguage.en;

  AppLanguage get language => _language;
  AppStrings get strings => AppStrings(_language);

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _language = AppLanguage.fromCode(prefs.getString(_prefsKey));
    notifyListeners();
  }

  Future<void> setLanguage(AppLanguage language) async {
    if (_language == language) return;
    _language = language;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefsKey, language.code);
  }
}
