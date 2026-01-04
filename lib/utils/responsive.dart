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

  Orientation get orientation => MediaQuery.orientationOf(this);
  bool get isPortrait => orientation == Orientation.portrait;
  bool get isLandscape => orientation == Orientation.landscape;

  /// Breakpoints focused on Mobile and Tablet
  /// Mobile: Portrait < 600 or Landscape with small width
  bool get isMobile => width < 600;

  /// Tablet: 600 <= width < 1200
  bool get isTablet => width >= 600 && width < 1200;

  /// Large Tablet / Landscape Tablet: width >= 1200
  bool get isLargeTablet => width >= 1200;

  // Compatibility aliases
  bool get isSmall => isMobile;
  bool get isMedium => isTablet;
  bool get isLarge => isLargeTablet || isTablet;

  double wp(double percent) => width * percent;
  double hp(double percent) => height * percent;

  /// Scales font size to fit different mobile and tablet screens
  double sp(double base) {
    double scale;
    if (isMobile) {
      // Base on 375px (iPhone standard)
      // Allow it to shrink slightly for very small devices (320px)
      // but not too much to maintain legibility.
      scale = (width / 375).clamp(0.85, 1.15);
    } else {
      // Tablets use 768px (iPad standard) as baseline
      scale = (width / 768).clamp(1.0, 1.4);
    }

    // Combine with system text scaling preference
    final double factor = MediaQuery.textScaleFactorOf(this).clamp(0.9, 1.3);
    return base * scale * factor;
  }

  /// Helper to choose a value based on device size
  T responsive<T>({required T mobile, T? tablet, T? largeTablet}) {
    if (isLargeTablet && largeTablet != null) return largeTablet;
    if (isTablet && tablet != null) return tablet;
    return mobile;
  }
}
