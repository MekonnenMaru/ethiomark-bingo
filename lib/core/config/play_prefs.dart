import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../bingo/player_bonus.dart';

class PlayPrefs {
  static const _boardZoomKey = 'play_board_zoom';
  static const _bonusRoundStatePrefix = 'player_bonus_round_';
  static const _bonusClaimPrefix = 'player_bonus_claim_';
  static const minBoardZoom = 0.75;
  static const maxBoardZoom = 1.5;
  static const boardZoomStep = 0.05;
  static const defaultBoardZoom = 1.15;

  static Future<double> loadBoardZoom() async {
    final prefs = await SharedPreferences.getInstance();
    return (prefs.getDouble(_boardZoomKey) ?? defaultBoardZoom)
        .clamp(minBoardZoom, maxBoardZoom);
  }

  static Future<void> saveBoardZoom(double zoom) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(
      _boardZoomKey,
      zoom.clamp(minBoardZoom, maxBoardZoom),
    );
  }

  static String _dayStamp() {
    final day = DateTime.now();
    return '${day.year.toString().padLeft(4, '0')}-'
        '${day.month.toString().padLeft(2, '0')}-'
        '${day.day.toString().padLeft(2, '0')}';
  }

  static String _bonusRoundKey(String cashierId, int roundNumber) {
    return '$_bonusRoundStatePrefix${cashierId}_${_dayStamp()}_$roundNumber';
  }

  static String _bonusClaimKey(String cashierId, int roundNumber) {
    return '$_bonusClaimPrefix${cashierId}_${_dayStamp()}_$roundNumber';
  }

  static Future<PlayerBonusRoundState> loadBonusRoundState({
    required String cashierId,
    required int roundNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_bonusRoundKey(cashierId, roundNumber));
    switch (raw) {
      case 'ready':
        return PlayerBonusRoundState.ready;
      case 'claimed':
        return PlayerBonusRoundState.claimed;
      case 'skipped':
        return PlayerBonusRoundState.skipped;
      default:
        return PlayerBonusRoundState.none;
    }
  }

  static Future<void> saveBonusRoundState({
    required String cashierId,
    required int roundNumber,
    required PlayerBonusRoundState state,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _bonusRoundKey(cashierId, roundNumber);
    switch (state) {
      case PlayerBonusRoundState.none:
        await prefs.remove(key);
        await prefs.remove(_bonusClaimKey(cashierId, roundNumber));
      case PlayerBonusRoundState.ready:
        await prefs.setString(key, 'ready');
        await prefs.remove(_bonusClaimKey(cashierId, roundNumber));
      case PlayerBonusRoundState.claimed:
        await prefs.setString(key, 'claimed');
      case PlayerBonusRoundState.skipped:
        await prefs.setString(key, 'skipped');
        await prefs.remove(_bonusClaimKey(cashierId, roundNumber));
    }
  }

  /// Lucky cards + amount for a claimed bonus (so cashier can re-open the overlay).
  static Future<PlayerBonusClaimResult?> loadBonusClaimDetails({
    required String cashierId,
    required int roundNumber,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_bonusClaimKey(cashierId, roundNumber));
    if (raw == null || raw.isEmpty) return null;
    try {
      final map = jsonDecode(raw) as Map<String, dynamic>;
      final cards = (map['cards'] as List?)
              ?.map((e) => int.tryParse('$e'))
              .whereType<int>()
              .toList() ??
          const <int>[];
      final amount = (num.tryParse('${map['amount']}') ?? 0).round();
      if (cards.isEmpty) return null;
      return PlayerBonusClaimResult(
        luckyCards: cards,
        amount: amount,
        skipped: false,
      );
    } catch (_) {
      return null;
    }
  }

  static Future<void> saveBonusClaimDetails({
    required String cashierId,
    required int roundNumber,
    required List<int> luckyCards,
    required int amount,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      _bonusClaimKey(cashierId, roundNumber),
      jsonEncode({
        'cards': luckyCards,
        'amount': amount,
      }),
    );
  }
}
