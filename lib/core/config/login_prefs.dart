import 'package:shared_preferences/shared_preferences.dart';

/// Saved login — kept across logout until cashier account is deleted.
class LoginPrefs {
  static const _cashierKey = 'saved_cashier_id';
  static const _passwordKey = 'saved_password';

  static Future<void> save(String cashierId, String password) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cashierKey, cashierId.trim());
    await prefs.setString(_passwordKey, password);
  }

  static Future<({String? cashierId, String? password})> load() async {
    final prefs = await SharedPreferences.getInstance();
    return (
      cashierId: prefs.getString(_cashierKey),
      password: prefs.getString(_passwordKey),
    );
  }

  static Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_cashierKey);
    await prefs.remove(_passwordKey);
  }
}
