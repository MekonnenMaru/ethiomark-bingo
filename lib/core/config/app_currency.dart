/// Display currency codes stored in `settings_json.system.currency`.
abstract final class AppCurrency {
  static const birr = 'birr';
  static const usd = 'usd';
  static const eur = 'eur';
  static const gbp = 'gbp';
  static const kes = 'kes';

  static const defaultCode = birr;

  static const codes = [birr, usd, eur, gbp, kes];

  static String normalize(Object? code) {
    final value = '$code'.trim().toLowerCase();
    return codes.contains(value) ? value : defaultCode;
  }

  static String fromSettings(Map<String, dynamic> settings) {
    final system = settings['system'] as Map<String, dynamic>? ?? {};
    return normalize(system['currency']);
  }
}
