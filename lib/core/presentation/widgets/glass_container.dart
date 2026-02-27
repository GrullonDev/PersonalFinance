import 'dart:ui';
import 'package:flutter/material.dart';

class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final double opacity;
  final Color? color;

  const GlassContainer({
    required this.child,
    super.key,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.blur = 15,
    this.opacity = 0.1,
    this.color,
  });

  @override
  Widget build(BuildContext context) => Container(
    width: width,
    height: height,
    margin: margin,
    child: Container(
      padding: padding,
      decoration: BoxDecoration(
        color: (color ?? Colors.white).withValues(alpha: opacity),
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1.5,
        ),
        gradient: LinearGradient(
          colors: [
            (color ?? Colors.white).withValues(alpha: 0.2),
            (color ?? Colors.white).withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: child,
    ),
  );
}
