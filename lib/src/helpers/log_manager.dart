// lib/src/helpers/log_manager.dart

import 'package:flutter/foundation.dart';

/// Manages logging for the Rive Animation Manager package.
///
/// Can be used to log animation lifecycle events, input changes, and errors.
/// Logs are only printed in debug mode.
class LogManager {
  static final List<String> _logs = [];
  static const int _maxLogs = 100;
  static bool _enabled = true;

  /// Enable or disable logging
  static set enabled(bool value) => _enabled = value;

  /// Get all logged messages
  static List<String> get logs => List.unmodifiable(_logs);

  /// Add a log message
  static void addLog(
    String message, {
    bool isExpected = true,
  }) {
    if (!_enabled) return;

    final timestamp = DateTime.now();
    final logMessage =
        '[${timestamp.hour}:${timestamp.minute}:${timestamp.second}] $message';

    _logs.add(logMessage);
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }

    if (kDebugMode) {
      print(logMessage);
    }
  }

  /// Clear all logs
  static void clearLogs() {
    _logs.clear();
  }

  /// Get last N logs
  static List<String> getLastLogs(int count) {
    return _logs.length > count ? _logs.sublist(_logs.length - count) : _logs;
  }
}
