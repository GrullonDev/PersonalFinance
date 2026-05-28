import 'package:flutter/material.dart';

Future<T?> showPremiumBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) => showGeneralDialog<T>(
  context: context,
  barrierDismissible: true,
  barrierLabel: 'Dismiss',
  barrierColor: Colors.black54,
  transitionDuration: const Duration(milliseconds: 300),
  pageBuilder:
      (context, animation, secondaryAnimation) => Align(
        alignment: Alignment.bottomCenter,
        child: Material(color: Colors.transparent, child: builder(context)),
      ),
  transitionBuilder: (context, animation, secondaryAnimation, child) {
    final curve = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    );
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 1),
        end: Offset.zero,
      ).animate(curve),
      child: FadeTransition(opacity: curve, child: child),
    );
  },
);

Future<T?> showPremiumDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
}) => showGeneralDialog<T>(
  context: context,
  barrierDismissible: true,
  barrierLabel: 'Dismiss',
  barrierColor: Colors.black54,
  transitionDuration: const Duration(milliseconds: 300),
  pageBuilder:
      (context, animation, secondaryAnimation) => SafeArea(
        child: Center(
          child: Material(color: Colors.transparent, child: builder(context)),
        ),
      ),
  transitionBuilder: (context, animation, secondaryAnimation, child) {
    final curve = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
    ); // Or easeOutBack if we want bounce
    return SlideTransition(
      position: Tween<Offset>(
        begin: const Offset(0, 0.05),
        end: Offset.zero,
      ).animate(curve),
      child: FadeTransition(
        opacity: curve,
        child: ScaleTransition(
          scale: Tween<double>(begin: 0.95, end: 1).animate(curve),
          child: child,
        ),
      ),
    );
  },
);
