import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class HapticFeedbackService {
  HapticFeedbackService._();

  static bool get _isCupertinoLike =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.iOS;

  static Future<void> selection() async {
    if (_isCupertinoLike) {
      await HapticFeedback.selectionClick();
    }
  }

  static Future<void> lightImpact() async {
    if (_isCupertinoLike) {
      await HapticFeedback.lightImpact();
    }
  }

  static Future<void> mediumImpact() async {
    if (_isCupertinoLike) {
      await HapticFeedback.mediumImpact();
    }
  }

  static Future<void> success() async {
    if (_isCupertinoLike) {
      await HapticFeedback.lightImpact();
    }
  }

  static Future<void> error() async {
    if (_isCupertinoLike) {
      await HapticFeedback.heavyImpact();
    }
  }
}
