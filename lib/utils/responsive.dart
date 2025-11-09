import 'package:flutter/material.dart';

/// Simple responsive helpers without external packages.
///
/// - Breakpoints are based on logical width.
/// - `sp` scales font size relative to 375px baseline and clamps result.
/// - `wp` `hp` return percentage sizes of screen.
extension ResponsiveContext on BuildContext {
  Size get _screenSize => MediaQuery.sizeOf(this);

  double get width => _screenSize.width;
  double get height => _screenSize.height;

  bool get isSmall => width < 360;
  bool get isMedium => width >= 360 && width < 420;
  bool get isLarge => width >= 420;

  double wp(double percent) => width * percent;
  double hp(double percent) => height * percent;

  /// Scales a base font size to the device width, clamped to avoid extremes.
  double sp(double base) {
    // 375 is a common design baseline (iPhone 11/12/13 non-pro width).
    final double scale = (width / 375).clamp(0.90, 1.20);
    final double factor = MediaQuery.of(this).textScaleFactor.clamp(0.9, 1.2);
    return base * scale * factor;
  }
}

