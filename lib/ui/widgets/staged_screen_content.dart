import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/performance/managed_loader.dart';
import '../../core/performance/resource_budget.dart';

/// Mounts [steps] one step per frame so heavy screens do not build in a single pass.
class StagedScreenContent extends StatefulWidget {
  const StagedScreenContent({
    super.key,
    required this.steps,
    this.enabled,
    this.stepDelay,
    this.crossAxisAlignment = CrossAxisAlignment.stretch,
    this.mainAxisSize = MainAxisSize.max,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  final List<Widget> steps;
  final bool? enabled;
  final Duration? stepDelay;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final MainAxisAlignment mainAxisAlignment;

  bool get _enabled => enabled ?? ResourceBudget.sequentialScreenLoads;

  @override
  State<StagedScreenContent> createState() => _StagedScreenContentState();
}

class _StagedScreenContentState extends State<StagedScreenContent> {
  late int _visibleCount;
  bool _scheduling = false;

  @override
  void initState() {
    super.initState();
    _visibleCount = _initialVisibleCount();
    _scheduleMoreIfNeeded();
  }

  @override
  void didUpdateWidget(covariant StagedScreenContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.steps.length != oldWidget.steps.length) {
      _visibleCount = _initialVisibleCount();
      _scheduleMoreIfNeeded();
    }
  }

  int _initialVisibleCount() {
    if (!widget._enabled || widget.steps.isEmpty) return widget.steps.length;
    return 1;
  }

  void _scheduleMoreIfNeeded() {
    if (!widget._enabled || _visibleCount >= widget.steps.length) return;
    if (_scheduling) return;
    _scheduling = true;
    unawaited(_revealNextSteps());
  }

  Future<void> _revealNextSteps() async {
    while (mounted && _visibleCount < widget.steps.length) {
      await ManagedLoader.breathe();
      final delay = widget.stepDelay;
      if (delay != null && delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }
      if (!mounted || _visibleCount >= widget.steps.length) break;
      setState(() => _visibleCount++);
    }
    _scheduling = false;
  }

  @override
  Widget build(BuildContext context) {
    final children = widget._enabled
        ? widget.steps.take(_visibleCount).toList()
        : widget.steps;

    return Column(
      crossAxisAlignment: widget.crossAxisAlignment,
      mainAxisSize: widget.mainAxisSize,
      mainAxisAlignment: widget.mainAxisAlignment,
      children: children,
    );
  }
}

/// Horizontal counterpart to [StagedScreenContent] for row layouts.
class StagedScreenRow extends StatefulWidget {
  const StagedScreenRow({
    super.key,
    required this.steps,
    this.enabled,
    this.stepDelay,
    this.crossAxisAlignment = CrossAxisAlignment.center,
    this.mainAxisSize = MainAxisSize.max,
    this.mainAxisAlignment = MainAxisAlignment.start,
  });

  final List<Widget> steps;
  final bool? enabled;
  final Duration? stepDelay;
  final CrossAxisAlignment crossAxisAlignment;
  final MainAxisSize mainAxisSize;
  final MainAxisAlignment mainAxisAlignment;

  bool get _enabled => enabled ?? ResourceBudget.sequentialScreenLoads;

  @override
  State<StagedScreenRow> createState() => _StagedScreenRowState();
}

class _StagedScreenRowState extends State<StagedScreenRow> {
  late int _visibleCount;
  bool _scheduling = false;

  @override
  void initState() {
    super.initState();
    _visibleCount = _initialVisibleCount();
    _scheduleMoreIfNeeded();
  }

  @override
  void didUpdateWidget(covariant StagedScreenRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.steps.length != oldWidget.steps.length) {
      _visibleCount = _initialVisibleCount();
      _scheduleMoreIfNeeded();
    }
  }

  int _initialVisibleCount() {
    if (!widget._enabled || widget.steps.isEmpty) return widget.steps.length;
    return 1;
  }

  void _scheduleMoreIfNeeded() {
    if (!widget._enabled || _visibleCount >= widget.steps.length) return;
    if (_scheduling) return;
    _scheduling = true;
    unawaited(_revealNextSteps());
  }

  Future<void> _revealNextSteps() async {
    while (mounted && _visibleCount < widget.steps.length) {
      await ManagedLoader.breathe();
      final delay = widget.stepDelay;
      if (delay != null && delay > Duration.zero) {
        await Future<void>.delayed(delay);
      }
      if (!mounted || _visibleCount >= widget.steps.length) break;
      setState(() => _visibleCount++);
    }
    _scheduling = false;
  }

  @override
  Widget build(BuildContext context) {
    final children = widget._enabled
        ? widget.steps.take(_visibleCount).toList()
        : widget.steps;

    return Row(
      crossAxisAlignment: widget.crossAxisAlignment,
      mainAxisSize: widget.mainAxisSize,
      mainAxisAlignment: widget.mainAxisAlignment,
      children: children,
    );
  }
}
