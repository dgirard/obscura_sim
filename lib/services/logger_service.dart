import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Service de logging centralisé pour l'application Obscura.
///
/// Remplace les print() par un système structuré avec niveaux de log.
/// En mode debug : tous les logs sont affichés.
/// En mode release : seuls les warnings et erreurs sont affichés.
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: false,
      dateTimeFormat: DateTimeFormat.onlyTime,
    ),
    level: kDebugMode ? Level.debug : Level.warning,
  );

  // Empêcher l'instanciation
  AppLogger._();

  /// Log général de debug
  static void debug(String message) {
    _logger.d(message);
  }

  /// Log spécifique à la caméra
  static void camera(String message) {
    _logger.d('[CAMERA] $message');
  }

  /// Log de performance (seulement en debug)
  static void perf(String message) {
    if (kDebugMode) {
      _logger.d('[PERF] $message');
    }
  }

  /// Log spécifique à la galerie
  static void gallery(String message) {
    _logger.d('[GALLERY] $message');
  }

  /// Log spécifique à l'audio
  static void audio(String message) {
    _logger.d('[AUDIO] $message');
  }

  /// Log d'information
  static void info(String message) {
    _logger.i(message);
  }

  /// Log d'avertissement
  static void warning(String message) {
    _logger.w(message);
  }

  /// Log d'erreur avec stack trace optionnel
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error: error, stackTrace: stackTrace);
  }
}
