import 'package:flutter/foundation.dart';

/// Niveles de logging
enum LogLevel {
  debug,
  info,
  warning,
  error,
  fatal,
}

/// Logger profesional para la aplicación
/// Reemplaza los print statements con un sistema de logging estructurado
class AppLogger {
  static const String _tag = '[PersonalFinance]';
  
  /// Log de debug - solo en modo debug
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      _log(LogLevel.debug, message, error, stackTrace);
    }
  }
  
  /// Log de información
  static void info(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.info, message, error, stackTrace);
  }
  
  /// Log de advertencia
  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.warning, message, error, stackTrace);
  }
  
  /// Log de error
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error, stackTrace);
  }
  
  /// Log fatal
  static void fatal(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.fatal, message, error, stackTrace);
  }
  
  /// Método interno para logging
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
    
    // En modo debug, usar debugPrint para mejor formato
    if (kDebugMode) {
      debugPrint(logMessage.toString());
    } else {
      // En producción, podrías enviar a un servicio de logging
      debugPrint(logMessage.toString());
    }
  }
  
  /// Log específico para transacciones
  static void logTransaction(String type, String title, double amount) {
    info('$type agregado: $title - \$${amount.toStringAsFixed(2)}');
  }
  
  /// Log específico para errores de base de datos
  static void logDatabaseError(String operation, Object error) {
    AppLogger.error('Error en operación de base de datos: $operation', error);
  }
  
  /// Log específico para errores de red
  static void logNetworkError(String endpoint, Object error) {
    AppLogger.error('Error de red en: $endpoint', error);
  }
  
  /// Log específico para errores de UI
  static void logUIError(String widget, Object error) {
    AppLogger.error('Error en UI: $widget', error);
  }
} 