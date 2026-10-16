/// Primary defaults for new cashier rows and missing preference values.
abstract final class CashierDefaults {
  /// Failed login passwords allowed before the cashier account is locked.
  static const maxLoginAttempts = 100;

  /// 1=Wedi, 2=Addis, 3=Foromifa, 4=Modern Arada, 5=Arada, 6=Bereket
  static const callerVoice = 5;

  /// Seconds of silence after each call sound before the next number is called.
  static const speedRange = 3;

  /// Default instant-bingo rule: no late-claim restriction.
  static const bingoClaimMode = 'no_restriction';

  /// Legacy mirror of [bingoClaimMode] (`-1` = no restriction).
  static const bingoClaimLimit = -1;

  /// 0=good.wav, 1=clapping.mp3, 2=goodbingo.mp3
  static const goodBingoSound = 0;

  /// `auto` = app confirms winners; `manual` = cashier taps Good / Not Bingo.
  static const checkMode = 'auto';

  /// Factory settings for a new cashier / new computer.
  /// Matches the current production play settings (bonus random, claim unlimited).
  /// Bonus amount is 50 (minimum allowed); saved `10` is no longer valid.
  static const settingsJson =
      '{"bonus":{"round":"random","count":"1","per_day":"1","amount":"50","min_bet":"100"},'
      '"system":{"check_result":"auto","color_mode":"three","profit":"0",'
      '"good_bingo_sound":"0","bingo_claim_mode":"no_restriction","bingo_claim_limit":-1,"currency":"birr",'
      '"language":"en","income_rounding":"off"},'
      '"toggles":{"will_start":true,"started":true,"stopped":true,'
      '"show_card_count":true,"show_pattern_on_play":true}}';
}
