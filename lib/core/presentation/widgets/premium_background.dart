import 'dart:ui';
import 'package:flutter/material.dart';

class PremiumBackground extends StatelessWidget {
  final Widget child;

  const PremiumBackground({required this.child, super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Stack(
      children: [
        // Base black/dark background
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF0F172A), // Slate 900
                Color(0xFF020617), // Slate 950
              ],
            ),
          ),
        ),

        // Decorative blurry circles
        Positioned(
          top: -100,
          left: -100,
          child: _buildBlurCircle(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3), // Indigo
            size: 300,
          ),
        ),
        Positioned(
          bottom: -50,
          right: -50,
          child: _buildBlurCircle(
            color: const Color(0xFFEC4899).withValues(alpha: 0.2), // Pink
            size: 250,
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).size.height * 0.4,
          left: MediaQuery.of(context).size.width * 0.6,
          child: _buildBlurCircle(
            color: const Color(0xFF8B5CF6).withValues(alpha: 0.2), // Violet
            size: 200,
          ),
        ),

        // Content
        SafeArea(child: child),
      ],
    ),
  );

  Widget _buildBlurCircle({
    required Color color,
    required double size,
  }) => Container(
    width: size,
    height: size,
    decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    // Temporarily disabled BackdropFilter as it might cause rendering issues on some Android devices
    /* child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
        child: Container(
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.transparent,
          ),
        ),
      ), */
  );
}
