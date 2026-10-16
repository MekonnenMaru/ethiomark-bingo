class Cartela {
  const Cartela({
    required this.id,
    required this.number,
    required this.b,
    required this.i,
    required this.n,
    required this.g,
    required this.o,
    required this.category,
  });

  final int id;
  final int number;
  final List<int> b;
  final List<int> i;
  final List<int> n;
  final List<int> g;
  final List<int> o;
  final String category;

  Map<String, List<int>> get columns => {
    'B': b,
    'I': i,
    'N': n,
    'G': g,
    'O': o,
  };

  factory Cartela.fromMap(Map<String, Object?> map) {
    return Cartela(
      id: map['id'] as int? ?? 0,
      number: map['cartela_number'] as int? ?? 0,
      b: _col(map['b']),
      i: _col(map['i']),
      n: _col(map['n']),
      g: _col(map['g']),
      o: _col(map['o']),
      category: map['category'] as String? ?? 'default',
    );
  }

  static List<int> _col(Object? raw) {
    return '$raw'
        .split(',')
        .map((e) => int.tryParse(e.trim()))
        .whereType<int>()
        .toList();
  }
}
