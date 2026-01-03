import 'dart:math' as math;

import 'package:flutter/material.dart';

class AnimatedCounter extends ImplicitlyAnimatedWidget {
  AnimatedCounter({
    required this.value,
    super.key,
    this.durationMs = 600,
    super.curve = Curves.easeOutCubic,
    this.prefix = '',
    this.style,
    this.decimals = 2,
  }) : super(duration: Duration(milliseconds: durationMs));

  final double value;
  final int durationMs;
  final String prefix;
  final TextStyle? style;
  final int decimals;

  @override
  AnimatedWidgetBaseState<AnimatedCounter> createState() =>
      _AnimatedCounterState();
}

class _AnimatedCounterState extends AnimatedWidgetBaseState<AnimatedCounter> {
  Tween<double>? _tween;

  @override
  Widget build(BuildContext context) {
    _tween ??= Tween<double>(begin: widget.value, end: widget.value);
    final double v = _tween!.evaluate(animation);
    final double rounded =
        (v * math.pow(10, widget.decimals)).round() /
        math.pow(10, widget.decimals);
    return Text(
      '${widget.prefix}${rounded.toStringAsFixed(widget.decimals)}',
      style: widget.style,
    );
  }

  @override
  void forEachTween(TweenVisitor<dynamic> visitor) {
    _tween =
        visitor(
              _tween,
              widget.value,
              (dynamic value) => Tween<double>(begin: value as double),
            )
            as Tween<double>?;
  }
}
