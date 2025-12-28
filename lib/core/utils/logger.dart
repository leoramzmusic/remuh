import 'package:flutter/foundation.dart';

/// Utilidad de logging para la aplicación
class Logger {
  static const String _prefix = '[REMUH]';

  /// Log de debug
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('$_prefix [DEBUG] $message');
      if (error != null) {
        debugPrint('Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('StackTrace: $stackTrace');
      }
    }
  }

  /// Log de información
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('$_prefix [INFO] $message');
    }
  }

  /// Log de advertencia
  static void warning(String message, [Object? error]) {
    if (kDebugMode) {
      debugPrint('$_prefix [WARNING] $message');
      if (error != null) {
        debugPrint('Error: $error');
      }
    }
  }

  /// Log de error
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    debugPrint('$_prefix [ERROR] $message');
    if (error != null) {
      debugPrint('Error: $error');
    }
    if (stackTrace != null) {
      debugPrint('StackTrace: $stackTrace');
    }
  }
}
