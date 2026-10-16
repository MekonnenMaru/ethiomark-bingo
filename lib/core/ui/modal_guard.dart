/// Prevents the same modal route from opening more than once at a time.
abstract final class ModalGuard {
  static final _openKeys = <String>{};

  static bool isOpen(String key) => _openKeys.contains(key);

  static Future<T?> run<T>(
    String key,
    Future<T?> Function() action, {
    T? blockedValue,
  }) async {
    if (_openKeys.contains(key)) return blockedValue;
    _openKeys.add(key);
    try {
      return await action();
    } finally {
      _openKeys.remove(key);
    }
  }
}

/// Stable keys for guarded modals.
abstract final class ModalKeys {
  static const playControls = 'play_controls';
  static const startRound = 'start_round';
  static const resumeGameNotice = 'resume_game_notice';
  static const checkCard = 'check_card';
  static const checkCardHelp = 'check_card_help';
  static const patternHelp = 'pattern_help';
  static const settingsFieldHelp = 'settings_field_help';
}
