import '../../core/bingo/bingo_patterns.dart';

class GameRound {
  const GameRound({
    required this.roundNumber,
    required this.cartelaNumbers,
    required this.price,
    required this.pattern,
    required this.result,
    required this.isCompleted,
    required this.lockedCartelas,
    required this.firstDraw,
    this.id,
  });

  final int? id;
  final int roundNumber;
  final List<int> cartelaNumbers;
  final int price;
  final int pattern;
  final List<int> result;
  final bool isCompleted;
  final List<int> lockedCartelas;
  final List<int> firstDraw;

  int get cardCount => cartelaNumbers.length;
  List<int> get drawnNumbers => result;

  factory GameRound.fromMap(Map<String, Object?> map) {
    return GameRound(
      id: map['id'] as int?,
      roundNumber: map['round_number'] as int? ?? 0,
      cartelaNumbers: _parseInts(map['cartela_number'] as String?),
      price: int.tryParse('${map['price']}') ?? 0,
      pattern: BingoPatterns.normalize(
        int.tryParse('${map['pattern']}') ?? BingoPatterns.defaultPattern,
      ),
      result: _parseInts(map['result'] as String?),
      isCompleted: (map['iscompleted'] as int? ?? 0) == 1,
      lockedCartelas: _parseInts(map['locked_cartela_number'] as String?),
      firstDraw: _parseInts(map['first_draw'] as String?),
    );
  }

  static List<int> _parseInts(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    return raw
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .where((n) => n > 0)
        .toList();
  }
}
