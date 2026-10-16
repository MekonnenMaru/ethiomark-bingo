import 'package:shared_preferences/shared_preferences.dart';

class ManualDepositLockoutState {
  const ManualDepositLockoutState({
    required this.isLocked,
    required this.failedAttempts,
    this.remaining = Duration.zero,
  });

  final bool isLocked;
  final int failedAttempts;
  final Duration remaining;

  int get attemptsRemaining =>
      (ManualDepositLockout.maxAttempts - failedAttempts).clamp(0, ManualDepositLockout.maxAttempts);
}

/// Limits invalid manual-deposit code trials: 5 failures → 5 minute lockout.
class ManualDepositLockout {
  ManualDepositLockout._();

  static const maxAttempts = 5;
  static const lockDuration = Duration(minutes: 5);

  static const _attemptsKey = 'manual_deposit_failed_attempts';
  static const _lockedUntilKey = 'manual_deposit_locked_until_ms';

  static Future<ManualDepositLockoutState> load() async {
    final prefs = await SharedPreferences.getInstance();
    final lockedUntilMs = prefs.getInt(_lockedUntilKey);
    final now = DateTime.now();

    if (lockedUntilMs != null) {
      final lockedUntil = DateTime.fromMillisecondsSinceEpoch(lockedUntilMs);
      if (now.isBefore(lockedUntil)) {
        return ManualDepositLockoutState(
          isLocked: true,
          failedAttempts: maxAttempts,
          remaining: lockedUntil.difference(now),
        );
      }
      await _clear(prefs);
    }

    return ManualDepositLockoutState(
      isLocked: false,
      failedAttempts: prefs.getInt(_attemptsKey) ?? 0,
    );
  }

  static Future<ManualDepositLockoutState> recordFailedAttempt() async {
    final prefs = await SharedPreferences.getInstance();
    final lockedUntilMs = prefs.getInt(_lockedUntilKey);
    final now = DateTime.now();

    if (lockedUntilMs != null) {
      final lockedUntil = DateTime.fromMillisecondsSinceEpoch(lockedUntilMs);
      if (now.isBefore(lockedUntil)) {
        return ManualDepositLockoutState(
          isLocked: true,
          failedAttempts: maxAttempts,
          remaining: lockedUntil.difference(now),
        );
      }
      await _clear(prefs);
    }

    final attempts = (prefs.getInt(_attemptsKey) ?? 0) + 1;
    if (attempts >= maxAttempts) {
      final lockedUntil = now.add(lockDuration);
      await prefs.setInt(_lockedUntilKey, lockedUntil.millisecondsSinceEpoch);
      await prefs.remove(_attemptsKey);
      return ManualDepositLockoutState(
        isLocked: true,
        failedAttempts: maxAttempts,
        remaining: lockDuration,
      );
    }

    await prefs.setInt(_attemptsKey, attempts);
    return ManualDepositLockoutState(
      isLocked: false,
      failedAttempts: attempts,
    );
  }

  static Future<void> reset() async {
    final prefs = await SharedPreferences.getInstance();
    await _clear(prefs);
  }

  static Future<void> _clear(SharedPreferences prefs) async {
    await prefs.remove(_attemptsKey);
    await prefs.remove(_lockedUntilKey);
  }

  static String formatRemaining(Duration remaining) {
    final totalSeconds = remaining.inSeconds.clamp(0, lockDuration.inSeconds);
    final minutes = totalSeconds ~/ 60;
    final seconds = totalSeconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }
}
