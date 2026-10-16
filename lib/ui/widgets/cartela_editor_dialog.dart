import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/l10n/app_strings.dart';
import '../../data/models/cartela.dart';
import '../theme/bingo_colors.dart';

class CartelaEditorResult {
  const CartelaEditorResult({
    required this.number,
    required this.b,
    required this.i,
    required this.n,
    required this.g,
    required this.o,
  });

  final int number;
  final List<int> b;
  final List<int> i;
  final List<int> n;
  final List<int> g;
  final List<int> o;
}

Future<CartelaEditorResult?> showCartelaEditorDialog({
  required BuildContext context,
  required AppStrings strings,
  Cartela? cartela,
  int? suggestedNumber,
}) {
  return showDialog<CartelaEditorResult>(
    context: context,
    builder: (ctx) => CartelaEditorDialog(
      strings: strings,
      cartela: cartela,
      suggestedNumber: suggestedNumber,
    ),
  );
}

class CartelaEditorDialog extends StatefulWidget {
  const CartelaEditorDialog({
    super.key,
    required this.strings,
    this.cartela,
    this.suggestedNumber,
  });

  final AppStrings strings;
  final Cartela? cartela;
  final int? suggestedNumber;

  @override
  State<CartelaEditorDialog> createState() => _CartelaEditorDialogState();
}

class _CartelaEditorDialogState extends State<CartelaEditorDialog> {
  static const _headers = ['B', 'I', 'N', 'G', 'O'];

  late final TextEditingController _numberController;
  late final List<List<TextEditingController>> _cells;

  String? _error;

  @override
  void initState() {
    super.initState();
    final cartela = widget.cartela;
    _numberController = TextEditingController(
      text: cartela != null
          ? '${cartela.number}'
          : widget.suggestedNumber != null
          ? '${widget.suggestedNumber}'
          : '',
    );

    final cols = cartela != null
        ? [cartela.b, cartela.i, cartela.n, cartela.g, cartela.o]
        : List.generate(5, (_) => List.filled(5, 0));

    _cells = List.generate(
      5,
      (c) => List.generate(
        5,
        (r) => TextEditingController(
          text: c == 2 && r == 2
              ? ''
              : cols[c][r] == 0
              ? ''
              : '${cols[c][r]}',
        ),
      ),
    );
  }

  @override
  void dispose() {
    _numberController.dispose();
    for (final col in _cells) {
      for (final cell in col) {
        cell.dispose();
      }
    }
    super.dispose();
  }

  void _save() {
    final number = int.tryParse(_numberController.text.trim());
    if (number == null || number < 1) {
      setState(() => _error = widget.strings.enterValidCartela);
      return;
    }

    final columns = <List<int>>[];
    for (var c = 0; c < 5; c++) {
      final col = <int>[];
      for (var r = 0; r < 5; r++) {
        if (c == 2 && r == 2) {
          col.add(0);
          continue;
        }
        final parsed = int.tryParse(_cells[c][r].text.trim());
        if (parsed == null || parsed < 1) {
          setState(() => _error = widget.strings.invalidCartelaGrid);
          return;
        }
        col.add(parsed);
      }
      columns.add(col);
    }

    Navigator.of(context).pop(
      CartelaEditorResult(
        number: number,
        b: columns[0],
        i: columns[1],
        n: columns[2],
        g: columns[3],
        o: columns[4],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final isEdit = widget.cartela != null;

    return AlertDialog(
      backgroundColor: BingoColors.bgDark,
      title: Text(
        isEdit ? s.editCartela : s.newCartela,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800),
      ),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _numberController,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: s.cartelaNumberLabel,
                  labelStyle: TextStyle(
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(
                      color: BingoColors.accentTeal.withValues(alpha: 0.5),
                    ),
                  ),
                  focusedBorder: const OutlineInputBorder(
                    borderSide: BorderSide(color: BingoColors.accentTeal),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Table(
                defaultColumnWidth: const FixedColumnWidth(64),
                children: [
                  TableRow(
                    children: _headers
                        .map(
                          (h) => Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              h,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: BingoColors.columnColor(h),
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  for (var r = 0; r < 5; r++)
                    TableRow(
                      children: List.generate(5, (c) {
                        final free = c == 2 && r == 2;
                        if (free) {
                          return Container(
                            height: 40,
                            alignment: Alignment.center,
                            child: const Text(
                              '★',
                              style: TextStyle(
                                color: BingoColors.gold,
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          );
                        }
                        return Padding(
                          padding: const EdgeInsets.all(2),
                          child: TextField(
                            controller: _cells[c][r],
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                            decoration: InputDecoration(
                              isDense: true,
                              contentPadding: const EdgeInsets.symmetric(
                                vertical: 8,
                                horizontal: 4,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        );
                      }),
                    ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(
                  _error!,
                  style: const TextStyle(color: BingoColors.lastCalled),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(s.cancel),
        ),
        FilledButton(
          onPressed: _save,
          style: FilledButton.styleFrom(
            backgroundColor: BingoColors.accentTeal,
          ),
          child: Text(s.save),
        ),
      ],
    );
  }
}
