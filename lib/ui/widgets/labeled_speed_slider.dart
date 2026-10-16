import 'package:flutter/material.dart';

/// Speed slider with the seconds label drawn inside the thumb (track endpoint).
class LabeledSpeedSlider extends StatelessWidget {
  const LabeledSpeedSlider({
    super.key,
    required this.value,
    required this.label,
    required this.min,
    required this.max,
    required this.onChanged,
    this.onChangeEnd,
    this.divisions,
    this.activeColor = const Color(0xFF00FF40),
    this.inactiveColor = Colors.black,
    this.thumbRadius = 20,
    this.trackHeight = 6,
  });

  final double value;
  final String label;
  final double min;
  final double max;
  final int? divisions;
  final ValueChanged<double>? onChanged;
  final ValueChanged<double>? onChangeEnd;
  final Color activeColor;
  final Color inactiveColor;
  final double thumbRadius;
  final double trackHeight;

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderThemeData(
        activeTrackColor: activeColor,
        inactiveTrackColor: inactiveColor,
        thumbColor: activeColor,
        overlayColor: activeColor.withValues(alpha: 0.18),
        trackHeight: trackHeight,
        thumbShape: _LabeledThumbShape(
          label: label,
          thumbRadius: thumbRadius,
          fillColor: activeColor,
        ),
        overlayShape: RoundSliderOverlayShape(overlayRadius: thumbRadius + 8),
        showValueIndicator: ShowValueIndicator.never,
      ),
      child: Slider(
        value: value.clamp(min, max),
        min: min,
        max: max,
        divisions: divisions,
        onChanged: onChanged,
        onChangeEnd: onChangeEnd,
      ),
    );
  }
}

class _LabeledThumbShape extends SliderComponentShape {
  const _LabeledThumbShape({
    required this.label,
    required this.thumbRadius,
    required this.fillColor,
  });

  final String label;
  final double thumbRadius;
  final Color fillColor;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) {
    return Size.fromRadius(thumbRadius);
  }

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    required bool isDiscrete,
    required TextPainter labelPainter,
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required TextDirection textDirection,
    required double value,
    required double textScaleFactor,
    required Size sizeWithOverflow,
  }) {
    final canvas = context.canvas;

    canvas.drawCircle(
      center,
      thumbRadius,
      Paint()
        ..color = fillColor
        ..style = PaintingStyle.fill,
    );

    canvas.drawCircle(
      center,
      thumbRadius,
      Paint()
        ..color = Colors.black.withValues(alpha: 0.18)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5,
    );

    final fontSize = (thumbRadius * 0.62).clamp(10.0, 13.0);
    final textPainter = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          color: Colors.black,
          fontWeight: FontWeight.w900,
          fontSize: fontSize,
          height: 1,
        ),
      ),
      textDirection: textDirection,
    )..layout();

    textPainter.paint(
      canvas,
      center - Offset(textPainter.width / 2, textPainter.height / 2),
    );
  }
}
