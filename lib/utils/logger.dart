import 'package:flutter/foundation.dart';

/// Niveles de logging
enum LogLevel { debug, info, warning, error, fatal }

/// Logger profesional para la aplicación.
/// En producción (kDebugMode == false) todos los métodos son no-op para evitar
/// filtrar información sensible (montos, emails, stack traces) a la consola del
/// sistema o a herramientas de instrumentación.
class AppLogger {
  static const String _tag = '[PersonalFinance]';

  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _log(LogLevel.debug, message, error, stackTrace);
    }
  }

  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _log(LogLevel.info, message, error, stackTrace);
    }
  }

  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _log(LogLevel.warning, message, error, stackTrace);
    }
  }

  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _log(LogLevel.error, message, error, stackTrace);
    }
  }

  static void fatal(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _log(LogLevel.fatal, message, error, stackTrace);
    }
  }

  static void _log(
    LogLevel level,
    String message,
    Object? error,
    StackTrace? stackTrace,
  ) {
    final String timestamp = DateTime.now().toIso8601String();
    final String levelString = level.name.toUpperCase();

    final StringBuffer logMessage = StringBuffer();
    logMessage.write('$_tag [$levelString] $timestamp: $message');

    if (error != null) {
      logMessage.write('\nError: $error');
    }

    if (stackTrace != null) {
      logMessage.write('\nStackTrace: $stackTrace');
    }

    debugPrint(logMessage.toString());
  }

  /// Log específico para transacciones — omite el monto en producción.
  static void logTransaction(String type, String title, double amount) {
    if (kDebugMode) {
      info('$type agregado: $title - \$${amount.toStringAsFixed(2)}');
    }
  }

  static void logDatabaseError(String operation, Object error) {
    AppLogger.error('Error en operación de base de datos: $operation', error);
  }

  static void logNetworkError(String endpoint, Object error) {
    AppLogger.error('Error de red en: $endpoint', error);
  }

  static void logUIError(String widget, Object error) {
    AppLogger.error('Error en UI: $widget', error);
  }
}
