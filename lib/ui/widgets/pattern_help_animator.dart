import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/bingo/bingo_patterns.dart';
import '../../core/bingo/pattern_animation_frames.dart';
import '../../core/l10n/app_strings.dart';
import '../theme/bingo_colors.dart';

/// Optional handle to stop pattern frame timers immediately (e.g. when a modal closes).
class PatternHelpAnimatorController {
  VoidCallback? _stop;

  void _attach(VoidCallback stop) => _stop = stop;

  void _detach() => _stop = null;

  void stop() => _stop?.call();
}

/// Live animated bingo pattern preview for help screens.
class PatternHelpAnimator extends StatefulWidget {
  const PatternHelpAnimator({
    super.key,
    required this.pattern,
    required this.strings,
    this.isActive = true,
    this.controller,
    this.minimalChrome = false,
    this.cellSize = 28,
    /// Multiplier for frame hold times (>1 = slower draw).
    this.holdScale = 1.0,
  });

  final int pattern;
  final AppStrings strings;
  final bool isActive;
  final PatternHelpAnimatorController? controller;
  final bool minimalChrome;
  final double cellSize;
  final double holdScale;

  @override
  State<PatternHelpAnimator> createState() => _PatternHelpAnimatorState();
}

class _PatternHelpAnimatorState extends State<PatternHelpAnimator> {
  static const _toneColors = [
    BingoColors.primary,
    Color(0xFF66BB6A),
    Color(0xFF43A047),
    Color(0xFF2E7D32),
    Color(0xFF81C784),
  ];

  Timer? _timer;
  int _frameIndex = 0;
  List<PatternAnimationFrame> _frames = [];

  @override
  void initState() {
    super.initState();
    widget.controller?._attach(_stop);
    _loadFrames();
    if (widget.isActive) _scheduleFrame();
  }

  @override
  void didUpdateWidget(covariant PatternHelpAnimator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      oldWidget.controller?._detach();
      widget.controller?._attach(_stop);
    }
    if (oldWidget.pattern != widget.pattern) {
      _stop();
      _frameIndex = 0;
      _loadFrames();
      if (widget.isActive) _scheduleFrame();
    } else if (oldWidget.isActive != widget.isActive) {
      if (widget.isActive) {
        _scheduleFrame();
      } else {
        _stop();
      }
    } else if (oldWidget.holdScale != widget.holdScale && widget.isActive) {
      _scheduleFrame();
    }
  }

  @override
  void dispose() {
    widget.controller?._detach();
    _stop();
    super.dispose();
  }

  void _loadFrames() {
    _frames = PatternAnimationFrames.buildForPattern(widget.pattern);
    if (_frames.isEmpty) {
      _frames = [
        PatternAnimationFrame(
          label: widget.strings.patternName(widget.pattern),
          groups: [{}],
        ),
      ];
    }
  }

  void _stop() {
    _timer?.cancel();
    _timer = null;
  }

  void _scheduleFrame() {
    _stop();
    if (!widget.isActive || _frames.isEmpty) return;

    final frame = _frames[_frameIndex];
    final loops = PatternAnimationFrames.loopsForPattern(widget.pattern);
    final minMs = loops ? PatternAnimationFrames.minHoldMs : 0;
    final baseMs = frame.holdMs < minMs ? minMs : frame.holdMs;
    final scale = widget.holdScale <= 0 ? 1.0 : widget.holdScale;
    final delayMs = (baseMs * scale).round().clamp(80, 20000);
    _timer = Timer(Duration(milliseconds: delayMs), () {
      if (!mounted || !widget.isActive) return;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !widget.isActive) return;
        final atLast = _frameIndex >= _frames.length - 1;
        if (atLast && !loops) {
          return;
        }
        setState(() {
          _frameIndex = loops ? (_frameIndex + 1) % _frames.length : _frameIndex + 1;
        });
        _scheduleFrame();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_frames.isEmpty) return const SizedBox.shrink();

    final frame = _frames[_frameIndex];

    final cellAnimMs = (220 * (widget.holdScale <= 0 ? 1.0 : widget.holdScale))
        .round()
        .clamp(180, 600);

    if (widget.minimalChrome) {
      return Center(
        child: _AnimatedPatternGrid(
          groups: frame.groups,
          toneColors: _toneColors,
          cellSize: widget.cellSize,
          cellAnimMs: cellAnimMs,
        ),
      );
    }

    final pct = frame.total > 0
        ? ((frame.index / frame.total) * 100).round()
        : 100;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.strings.patternAnimProgress(
            frame.index,
            frame.total,
            pct,
          ),
          style: TextStyle(
            fontSize: 11,
            color: Colors.black.withValues(alpha: 0.55),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          frame.label,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: BingoColors.bgDark,
            height: 1.3,
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: _AnimatedPatternGrid(
            groups: frame.groups,
            toneColors: _toneColors,
            cellSize: widget.cellSize,
            cellAnimMs: cellAnimMs,
          ),
        ),
        if (PatternAnimationFrames.loopsForPattern(widget.pattern)) ...[
          const SizedBox(height: 4),
          Text(
            widget.strings.patternAnimLoops,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10.5,
              color: Colors.black.withValues(alpha: 0.45),
            ),
          ),
        ],
      ],
    );
  }
}

class _AnimatedPatternGrid extends StatelessWidget {
  const _AnimatedPatternGrid({
    required this.groups,
    required this.toneColors,
    this.cellSize = 28,
    this.cellAnimMs = 220,
  });

  final List<Set<PatternAnimCell>> groups;
  final List<Color> toneColors;
  final double cellSize;
  final int cellAnimMs;

  static const _letters = ['B', 'I', 'N', 'G', 'O'];

  double get _cellGap => cellSize * 2.5 / 28;
  double get _headerHeight => cellSize * 20 / 28;
  double get _gridWidth => cellSize * 5 + _cellGap * 4;
  double get _gridHeight => cellSize * 5 + _cellGap * 4;

  PatternAnimCell _cell(int row, int col) => (row: row, col: col);

  Color? _toneForCell(int row, int col) {
    for (var i = 0; i < groups.length; i++) {
      if (groups[i].contains(_cell(row, col))) {
        return toneColors[i % toneColors.length];
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    // No outer board frame — grid cells only.
    final grid = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: _headerHeight,
          width: _gridWidth,
          child: Row(
            children: [
              for (var i = 0; i < _letters.length; i++) ...[
                if (i > 0) SizedBox(width: _cellGap),
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: BingoColors.columnColor(_letters[i]),
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _letters[i],
                        style: TextStyle(
                          fontSize: cellSize * 10 / 28,
                          fontWeight: FontWeight.w900,
                          color: BingoColors.columnTextColor(_letters[i]),
                          height: 1,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
        SizedBox(height: _cellGap),
        SizedBox(
          width: _gridWidth,
          height: _gridHeight,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var row = 0; row < 5; row++) ...[
                if (row > 0) SizedBox(height: _cellGap),
                Row(
                  children: [
                    for (var col = 0; col < 5; col++) ...[
                      if (col > 0) SizedBox(width: _cellGap),
                      _buildCell(row, col),
                    ],
                  ],
                ),
              ],
            ],
          ),
        ),
      ],
    );

    return SizedBox(
      width: _gridWidth,
      child: grid,
    );
  }

  Widget _buildCell(int row, int col) {
    final isCenter = row == 2 && col == 2;
    final tone = _toneForCell(row, col);
    final isWin = tone != null;

    return AnimatedContainer(
      duration: Duration(milliseconds: cellAnimMs),
      curve: Curves.easeOutCubic,
      width: cellSize,
      height: cellSize,
      decoration: BoxDecoration(
        color: isWin
            ? tone
            : isCenter
                ? BingoColors.accentTeal.withValues(alpha: 0.45)
                : BingoColors.mobileNumBoxBg,
        borderRadius: BorderRadius.circular(3),
        border: Border.all(
          color: isWin
              ? tone.withValues(alpha: 0.9)
              : BingoColors.mobileNumBoxBorder,
        ),
      ),
      // Center free-space only — no "W" on winning cells.
      child: isCenter
          ? Center(
              child: Text(
                '★',
                style: TextStyle(
                  fontSize: cellSize * 11 / 28,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.95),
                  height: 1,
                ),
              ),
            )
          : null,
    );
  }
}

/// Pattern picker + live animator for help pages.
class PatternHelpLiveSection extends StatefulWidget {
  const PatternHelpLiveSection({
    super.key,
    required this.strings,
    this.isActive = true,
    this.initialPattern = BingoPatterns.lineOne,
  });

  final AppStrings strings;
  final bool isActive;
  final int initialPattern;

  @override
  State<PatternHelpLiveSection> createState() => _PatternHelpLiveSectionState();
}

class _PatternHelpLiveSectionState extends State<PatternHelpLiveSection> {
  late int _pattern = widget.initialPattern;

  @override
  void didUpdateWidget(covariant PatternHelpLiveSection oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialPattern != widget.initialPattern) {
      _pattern = widget.initialPattern;
    }
  }

  @override
  Widget build(BuildContext context) {
    final comboCount = PatternAnimationFrames.combinationCount(_pattern);
    final borderColor = Colors.black.withValues(alpha: 0.18);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.strings.patternHelpFreeSpaceNote,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            height: 1.3,
            color: BingoColors.accentTeal,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.strings.patternSelectToPreview,
          style: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
            color: BingoColors.bgDark,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<int>(
          value: _pattern,
          isExpanded: true,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: borderColor),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: BingoColors.primary, width: 2),
            ),
          ),
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: BingoColors.bgDark,
          ),
          dropdownColor: Colors.white,
          icon: Icon(Icons.expand_more, color: BingoColors.bgDark),
          items: BingoPatterns.all
              .map(
                (p) => DropdownMenuItem(
                  value: p,
                  child: Text(widget.strings.patternName(p)),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => _pattern = value);
          },
        ),
        if (comboCount > 1) ...[
          const SizedBox(height: 6),
          Text(
            widget.strings.patternAnimComboHint(comboCount),
            style: TextStyle(
              fontSize: 11,
              color: Colors.black.withValues(alpha: 0.6),
              height: 1.3,
            ),
          ),
        ],
        const SizedBox(height: 8),
        PatternHelpAnimator(
          pattern: _pattern,
          strings: widget.strings,
          isActive: widget.isActive,
        ),
        const SizedBox(height: 8),
        Text(
          widget.strings.patternDescription(_pattern),
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            color: Colors.black.withValues(alpha: 0.78),
          ),
        ),
      ],
    );
  }
}
