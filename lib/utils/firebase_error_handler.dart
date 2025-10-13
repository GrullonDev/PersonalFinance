import 'package:flutter/material.dart';

/// Clase para manejar errores de Firebase de manera centralizada
class FirebaseErrorHandler {
  /// Maneja errores de Firebase y devuelve un valor por defecto si ocurre un error
  static Future<T?> handleOperation<T>({
    required Future<T?> Function() operation,
    required String errorMessage,
    T? defaultValue,
    bool showDebugLog = true,
  }) async {
    try {
      return await operation();
    } catch (e) {
      if (showDebugLog) {
        debugPrint('$errorMessage: $e');
      }
      return defaultValue;
    }
  }

  /// Maneja operaciones de Firebase que no devuelven valor (void)
  static Future<bool> handleVoidOperation({
    required Future<void> Function() operation,
    required String errorMessage,
    bool showDebugLog = true,
  }) async {
    try {
      await operation();
      return true;
    } catch (e) {
      if (showDebugLog) {
        debugPrint('$errorMessage: $e');
      }
      return false;
    }
  }
}
