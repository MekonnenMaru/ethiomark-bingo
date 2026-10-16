enum AppLanguage {
  am('am', 'አማርኛ'),
  en('en', 'English'),
  om('om', 'Afaan Oromoo'),
  ti('ti', 'ትግርኛ');

  const AppLanguage(this.code, this.nativeName);

  final String code;
  final String nativeName;

  static AppLanguage fromCode(String? code) {
    return AppLanguage.values.firstWhere(
      (l) => l.code == code,
      orElse: () => AppLanguage.en,
    );
  }
}
