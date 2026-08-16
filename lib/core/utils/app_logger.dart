import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';

/// Service de logging centralisé.
///
/// Désactivé par défaut en release. Le paramètre `feature:` sert de préfixe de
/// domaine (`[API]`, `[Auth]`…) pour filtrer les journaux à la lecture.
class AppLogger {
  factory AppLogger() => _instance;
  AppLogger._internal();

  static final AppLogger _instance = AppLogger._internal();

  Logger? _logger;

  /// Logger avec initialisation automatique si nécessaire.
  Logger get logger {
    if (_logger == null) {
      init();
    }
    return _logger!;
  }

  static bool _isEnabled = true;
  static bool _showInfo = true;
  static bool _showWarning = true;
  static bool _showError = true;
  static bool _showDebug = true;

  void init({
    bool? enabled,
    bool? showInfo,
    bool? showWarning,
    bool? showError,
    bool? showDebug,
  }) {
    _isEnabled = enabled ?? (!kReleaseMode);
    _showInfo = showInfo ?? true;
    _showWarning = showWarning ?? true;
    _showError = showError ?? true;
    _showDebug = showDebug ?? kDebugMode;

    _logger = Logger(
      printer: PrettyPrinter(
        dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
      ),
      level: _getLogLevel(),
    );
  }

  Level _getLogLevel() {
    if (!_isEnabled) return Level.off;
    if (_showDebug) return Level.debug;
    if (_showInfo) return Level.info;
    if (_showWarning) return Level.warning;
    if (_showError) return Level.error;
    return Level.off;
  }

  // ========== CONTRÔLES GLOBAUX ==========

  static void setEnabled(bool enabled) {
    _isEnabled = enabled;
    _instance._updateLogLevel();
  }

  static void configure({
    bool? showInfo,
    bool? showWarning,
    bool? showError,
    bool? showDebug,
  }) {
    if (showInfo != null) _showInfo = showInfo;
    if (showWarning != null) _showWarning = showWarning;
    if (showError != null) _showError = showError;
    if (showDebug != null) _showDebug = showDebug;
    _instance._updateLogLevel();
  }

  void _updateLogLevel() {
    Logger.level = _getLogLevel();
  }

  // ========== MÉTHODES DE LOGGING ==========

  void info(
    String message, {
    String? feature,
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_isEnabled || !_showInfo) return;
    logger.i(
      _formatMessage(message, feature, data),
      error: error,
      stackTrace: stackTrace,
    );
  }

  void debug(
    String message, {
    String? feature,
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_isEnabled || !_showDebug) return;
    logger.d(
      _formatMessage(message, feature, data),
      error: error,
      stackTrace: stackTrace,
    );
  }

  void warning(
    String message, {
    String? feature,
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_isEnabled || !_showWarning) return;
    logger.w(
      _formatMessage(message, feature, data),
      error: error,
      stackTrace: stackTrace,
    );
  }

  void error(
    String message, {
    String? feature,
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_isEnabled || !_showError) return;
    logger.e(
      _formatMessage(message, feature, data),
      error: error,
      stackTrace: stackTrace,
    );
  }

  void fatal(
    String message, {
    String? feature,
    Map<String, dynamic>? data,
    Object? error,
    StackTrace? stackTrace,
  }) {
    if (!_isEnabled) return;
    logger.f(
      _formatMessage(message, feature, data),
      error: error,
      stackTrace: stackTrace,
    );
  }

  // ========== MÉTHODES SPÉCIALISÉES ==========

  void navigation(String action, String route, {Map<String, dynamic>? params}) {
    info(
      '🧭 Navigation $action: $route',
      feature: 'Navigation',
      data: {'action': action, 'route': route, 'params': ?params},
    );
  }

  void auth(
    String action,
    String message, {
    String? userId,
    Map<String, dynamic>? data,
    Object? error,
  }) {
    final context = {'action': action, 'userId': ?userId, ...?data};

    if (error != null) {
      this.error(
        '🔐 Auth $action: $message',
        feature: 'Auth',
        data: context,
        error: error,
      );
    } else {
      info('🔐 Auth $action: $message', feature: 'Auth', data: context);
    }
  }

  void api(
    String method,
    String endpoint,
    String message, {
    int? statusCode,
    Map<String, dynamic>? data,
    Object? error,
  }) {
    final context = {
      'method': method,
      'endpoint': endpoint,
      'statusCode': ?statusCode,
      ...?data,
    };

    if (error != null) {
      this.error(
        '🌐 API $method $endpoint: $message',
        feature: 'API',
        data: context,
        error: error,
      );
    } else {
      info('🌐 API $method $endpoint: $message', feature: 'API', data: context);
    }
  }

  /// Journalise un évènement du canal temps réel (socket).
  ///
  /// La messagerie vit sur ce canal : sans trace nommée, un message perdu est
  /// indiscernable d'un message jamais émis.
  void realtime(
    String event,
    String message, {
    Map<String, dynamic>? data,
    Object? error,
  }) {
    final context = {'event': event, ...?data};

    if (error != null) {
      this.error(
        '📡 Realtime $event: $message',
        feature: 'Realtime',
        data: context,
        error: error,
      );
    } else {
      info('📡 Realtime $event: $message', feature: 'Realtime', data: context);
    }
  }

  // ========== UTILITAIRES ==========

  String _formatMessage(
    String message,
    String? feature,
    Map<String, dynamic>? data,
  ) {
    final buffer = StringBuffer();

    if (feature != null) {
      buffer.write('[$feature] ');
    }

    buffer.write(message);

    if (data != null && data.isNotEmpty) {
      buffer.write(' | Data: $data');
    }

    return buffer.toString();
  }
}
