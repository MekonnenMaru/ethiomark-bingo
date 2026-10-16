import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../core/bootstrap/cartela_load_service.dart';
import '../../core/l10n/locale_controller.dart';
import '../theme/bingo_colors.dart';

/// Thin progress strip while card data loads in the background.
class CartelaLoadingBanner extends StatelessWidget {
  const CartelaLoadingBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return Selector<CartelaLoadService, ({bool show, bool loading, String? error, int current, int total, double? progress})>(
      selector: (_, loader) => (
        show: !(loader.isReady || (!loader.isLoading && loader.error == null)),
        loading: loader.isLoading,
        error: loader.error,
        current: loader.current,
        total: loader.total,
        progress: loader.progress,
      ),
      builder: (context, state, _) {
        if (!state.show) return const SizedBox.shrink();

        final s = context.read<LocaleController>().strings;

        if (state.error != null) {
          return Material(
            color: BingoColors.lastCalled.withValues(alpha: 0.92),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                state.error!,
                style: const TextStyle(color: Colors.white, fontSize: 12),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        final message = state.total > 0
            ? s.loadingCartelasProgress(state.current, state.total)
            : s.loadingCards;

        return Material(
          color: const Color(0xFF0C474E).withValues(alpha: 0.95),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  message,
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                if (state.progress != null) ...[
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: state.progress,
                    color: const Color(0xFFFF9800),
                    backgroundColor: BingoColors.surface,
                    minHeight: 4,
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}
