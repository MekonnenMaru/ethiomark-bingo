import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/device/device_date_validator.dart';
import '../../core/device/east_africa_time.dart';
import '../../core/device/open_date_settings.dart';
import '../../core/device/stored_date.dart';
import '../../core/l10n/app_strings.dart';
import '../layout/responsive_layout.dart';
import '../theme/bingo_colors.dart';

const _panelRadius = 8.0;
const _panelBorderWidth = 1.5;

/// Tracks the active device-date overlay so logout can dismiss it.
abstract final class DeviceDateAlertHandle {
  static VoidCallback? _dismiss;

  static void register(VoidCallback dismiss) => _dismiss = dismiss;

  static void unregister(VoidCallback dismiss) {
    if (identical(_dismiss, dismiss)) _dismiss = null;
  }

  static void dismissIfOpen() {
    final dismiss = _dismiss;
    _dismiss = null;
    dismiss?.call();
  }
}

Future<void> showDeviceDateMismatchAlert(
  BuildContext context, {
  required AppStrings strings,
  required DeviceDateMismatch mismatch,
  required Future<DeviceDateMismatch?> Function() recheck,
}) {
  final overlay = Overlay.of(context, rootOverlay: true);
  final completer = Completer<void>();
  late OverlayEntry entry;

  void dismiss() {
    DeviceDateAlertHandle.unregister(dismiss);
    if (entry.mounted) {
      entry.remove();
    }
    if (!completer.isCompleted) {
      completer.complete();
    }
  }

  entry = OverlayEntry(
    builder: (overlayContext) {
      return Stack(
        fit: StackFit.expand,
        children: [
          ModalBarrier(
            dismissible: false,
            color: Colors.black.withValues(alpha: 0.82),
          ),
          Center(
            child: _DeviceDateMismatchDialog(
              strings: strings,
              mismatch: mismatch,
              recheck: recheck,
              onDismiss: dismiss,
            ),
          ),
        ],
      );
    },
  );

  DeviceDateAlertHandle.register(dismiss);
  overlay.insert(entry);

  return completer.future;
}

class _DeviceDateMismatchDialog extends StatefulWidget {
  const _DeviceDateMismatchDialog({
    required this.strings,
    required this.mismatch,
    required this.recheck,
    required this.onDismiss,
  });

  final AppStrings strings;
  final DeviceDateMismatch mismatch;
  final Future<DeviceDateMismatch?> Function() recheck;
  final VoidCallback onDismiss;

  @override
  State<_DeviceDateMismatchDialog> createState() =>
      _DeviceDateMismatchDialogState();
}

class _DeviceDateMismatchDialogState extends State<_DeviceDateMismatchDialog> {
  bool _checking = false;
  bool _stillWrong = false;
  late DeviceDateMismatch _current = widget.mismatch;

  Future<void> _checkAgain() async {
    setState(() {
      _checking = true;
      _stillWrong = false;
    });

    final next = await widget.recheck();
    if (!mounted) return;

    if (next == null) {
      widget.onDismiss();
      return;
    }

    setState(() {
      _checking = false;
      _stillWrong = true;
      _current = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final desktop = context.isDesktop;
    final mismatch = _current;

    return Material(
      color: Colors.transparent,
      elevation: 48,
      shadowColor: Colors.black.withValues(alpha: 0.65),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: desktop ? 500 : 380),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF1A2238),
            borderRadius: BorderRadius.circular(_panelRadius),
            border: Border.all(
              color: BingoColors.lastCalled.withValues(alpha: 0.7),
              width: _panelBorderWidth,
            ),
            boxShadow: [
              BoxShadow(
                color: BingoColors.lastCalled.withValues(alpha: 0.28),
                blurRadius: 28,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.55),
                blurRadius: 32,
                offset: const Offset(0, 16),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(_panelRadius),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHeader(s),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    desktop ? 30 : 22,
                    desktop ? 24 : 20,
                    desktop ? 30 : 22,
                    desktop ? 22 : 18,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        _introFor(s, mismatch),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.92),
                          fontSize: desktop ? 15 : 14,
                          height: 1.55,
                        ),
                      ),
                      const SizedBox(height: 20),
                      _TimeInfoCard(
                        label: s.deviceDateDeviceTimeLabel,
                        value: StoredDate.formatDateTime(mismatch.deviceTime),
                        icon: Icons.smartphone_outlined,
                        accent: BingoColors.lastCalled,
                      ),
                      if (mismatch.wrongTimezone) ...[
                        const SizedBox(height: 12),
                        _TimeInfoCard(
                          label: s.deviceDateTimezoneLabel,
                          value: EastAfricaTime.deviceZoneDescription(
                            mismatch.deviceTime,
                          ),
                          icon: Icons.public,
                          accent: BingoColors.lastCalled,
                        ),
                        const SizedBox(height: 12),
                        _TimeInfoCard(
                          label: s.deviceDateRequiredTimezoneLabel,
                          value: s.deviceDateRequiredTimezoneValue,
                          icon: Icons.check_circle_outline,
                          accent: BingoColors.primary,
                        ),
                      ],
                      if (mismatch.dateBehind &&
                          mismatch.lastActivityTime != null) ...[
                        const SizedBox(height: 12),
                        _TimeInfoCard(
                          label: s.deviceDateLastActivityLabel,
                          value: StoredDate.formatDateTime(
                            mismatch.lastActivityTime!,
                          ),
                          icon: Icons.history,
                          accent: BingoColors.gold,
                        ),
                      ],
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 14,
                        ),
                        decoration: BoxDecoration(
                          color: BingoColors.accentTeal.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: BingoColors.accentTeal.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              Icons.info_outline,
                              size: 20,
                              color: BingoColors.accentTeal.withValues(alpha: 0.9),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                s.deviceDateFixInstructions,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.88),
                                  fontSize: 13.5,
                                  height: 1.5,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_stillWrong) ...[
                        const SizedBox(height: 14),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: BingoColors.lastCalled.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: BingoColors.lastCalled.withValues(alpha: 0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: BingoColors.lastCalled,
                                size: 22,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  s.deviceDateStillWrongTitle,
                                  style: const TextStyle(
                                    color: BingoColors.lastCalled,
                                    fontWeight: FontWeight.w700,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Divider(height: 1, color: Color(0x33FFFFFF)),
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    desktop ? 26 : 20,
                    16,
                    desktop ? 26 : 20,
                    desktop ? 22 : 18,
                  ),
                  child: Row(
                    children: [
                      if (canOpenSystemDateSettings)
                        Expanded(
                          child: _PulsingDateSettingsButton(
                            enabled: !_checking,
                            label: s.openDateSettings,
                            onPressed: openSystemDateSettings,
                          ),
                        ),
                      if (canOpenSystemDateSettings) const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton.icon(
                          onPressed: _checking ? null : _checkAgain,
                          icon: _checking
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.black,
                                  ),
                                )
                              : const Icon(Icons.refresh, size: 18),
                          label: Text(
                            s.checkDateAgain,
                            style: const TextStyle(fontWeight: FontWeight.w800),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: BingoColors.gold,
                            foregroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _introFor(AppStrings s, DeviceDateMismatch mismatch) {
    if (mismatch.dateBehind && mismatch.wrongTimezone) {
      return s.deviceDateAndTimezoneMismatchIntro;
    }
    if (mismatch.wrongTimezone) return s.deviceTimezoneMismatchIntro;
    return s.deviceDateMismatchIntro;
  }

  Widget _buildHeader(AppStrings s) {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            BingoColors.lastCalled.withValues(alpha: 0.95),
            const Color(0xFFB71C1C),
          ],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.schedule,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              s.deviceDateMismatchTitle,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w800,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PulsingDateSettingsButton extends StatefulWidget {
  const _PulsingDateSettingsButton({
    required this.enabled,
    required this.label,
    required this.onPressed,
  });

  final bool enabled;
  final String label;
  final VoidCallback onPressed;

  @override
  State<_PulsingDateSettingsButton> createState() =>
      _PulsingDateSettingsButtonState();
}

class _PulsingDateSettingsButtonState extends State<_PulsingDateSettingsButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _glow;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 850),
    )..repeat(reverse: true);
    _glow = Tween<double>(begin: 0.25, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
    _scale = Tween<double>(begin: 1.0, end: 1.03).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        return Transform.scale(
          scale: widget.enabled ? _scale.value : 1.0,
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              boxShadow: widget.enabled
                  ? [
                      BoxShadow(
                        color: BingoColors.gold.withValues(
                          alpha: 0.35 + _glow.value * 0.55,
                        ),
                        blurRadius: 10 + _glow.value * 14,
                        spreadRadius: _glow.value * 2.5,
                      ),
                      BoxShadow(
                        color: BingoColors.lastCalled.withValues(
                          alpha: 0.2 + _glow.value * 0.35,
                        ),
                        blurRadius: 16 + _glow.value * 18,
                        spreadRadius: _glow.value * 1.5,
                      ),
                    ]
                  : null,
            ),
            child: OutlinedButton.icon(
              onPressed: widget.enabled ? widget.onPressed : null,
              icon: Icon(
                Icons.settings_outlined,
                size: 18,
                color: widget.enabled
                    ? BingoColors.gold.withValues(alpha: 0.85 + _glow.value * 0.15)
                    : Colors.white54,
              ),
              label: Text(widget.label),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: const Color(0xFF24304A).withValues(alpha: 0.85),
                side: BorderSide(
                  color: Color.lerp(
                    Colors.white.withValues(alpha: 0.35),
                    BingoColors.gold,
                    widget.enabled ? _glow.value : 0.0,
                  )!,
                  width: 1.2 + (widget.enabled ? _glow.value * 0.8 : 0),
                ),
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TimeInfoCard extends StatelessWidget {
  const _TimeInfoCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFF0F1628),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: accent.withValues(alpha: 0.45)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.65),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.2,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  value,
                  style: TextStyle(
                    color: accent,
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
