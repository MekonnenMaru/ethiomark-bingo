import 'package:flutter/material.dart';

import '../theme/bingo_colors.dart';

/// Shared spinner used across the app.
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({
    super.key,
    this.message,
    this.size = 36,
    this.color = const Color(0xFFFF9800),
    this.strokeWidth = 3,
  });

  final String? message;
  final double size;
  final Color color;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            strokeWidth: strokeWidth,
            color: color,
          ),
        ),
        if (message != null) ...[
          const SizedBox(height: 14),
          Text(
            message!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: BingoColors.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ],
    );
  }
}

/// Full-page loading state.
class AppLoadingView extends StatelessWidget {
  const AppLoadingView({super.key, this.message = 'Loading…'});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: AppLoadingIndicator(message: message, color: BingoColors.primary),
    );
  }
}

/// Semi-transparent overlay shown on top of existing content while busy.
class AppLoadingOverlay extends StatelessWidget {
  const AppLoadingOverlay({
    super.key,
    required this.loading,
    required this.child,
    this.message,
  });

  final bool loading;
  final Widget child;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (loading)
          Positioned.fill(
            child: AbsorbPointer(
              child: ColoredBox(
                color: Colors.black.withValues(alpha: 0.55),
                child: Center(
                  child: Container(
                    margin: const EdgeInsets.all(32),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 28,
                      vertical: 24,
                    ),
                    decoration: BoxDecoration(
                      color: BingoColors.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: BingoColors.border),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: AppLoadingIndicator(
                      message: message ?? 'Please wait…',
                      size: 40,
                      color: const Color(0xFFFF9800),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}

/// Small inline spinner for buttons.
class AppButtonLoader extends StatelessWidget {
  const AppButtonLoader({super.key, this.color = Colors.white, this.size = 20});

  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(strokeWidth: 2, color: color),
    );
  }
}
