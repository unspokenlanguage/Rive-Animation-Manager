// lib/src/helpers/log_manager.dart - ENHANCED VERSION

import 'package:flutter/foundation.dart';

/// Enhanced Manages logging for the Rive Animation Manager package.
///
/// Features:
/// - Log storage with timestamp
/// - ValueNotifier for reactive UI updates
/// - Enable/disable logging
/// - Clear logs
/// - Get last N logs
/// - Separate tracking of expected vs error logs
///
/// Can be used to log animation lifecycle events, input changes, and errors.
/// Logs are only printed in debug mode.
///
/// Usage:
/// ```dart
/// // Add a log
/// LogManager.addLog('Animation initialized', isExpected: true);
///
/// // Listen to log changes with ValueNotifier
/// ValueListenableBuilder<List<Map<String, dynamic>>>(
///   valueListenable: LogManager.logMessages,
///   builder: (context, logs, _) {
///     return ListView.builder(
///       itemCount: logs.length,
///       itemBuilder: (context, index) {
///         final log = logs[index];
///         return Text(log['message']);
///       },
///     );
///   },
/// )
///
/// // Clear all logs
/// LogManager.clearLogs();
/// ```
class LogManager {
  // Private storage
  static final List<Map<String, dynamic>> _logs = [];
  static const int _maxLogs = 100;
  static bool _enabled = true;

  // Public ValueNotifier for reactive UI
  static final ValueNotifier<List<Map<String, dynamic>>> logMessages =
      ValueNotifier([]);

  /// Enable or disable logging
  static set enabled(bool value) => _enabled = value;

  /// Get all logged messages
  static List<Map<String, dynamic>> get logs => List.unmodifiable(_logs);

  /// Get legacy string logs (for backward compatibility)
  static List<String> get logsAsStrings =>
      _logs.map((log) => log['message'] as String).toList();

  /// Add a log message with detailed information
  ///
  /// Parameters:
  /// - [message]: The log message text
  /// - [isExpected]: Whether this is an expected event (true) or warning/error (false)
  /// - [timestamp]: Optional custom timestamp (uses current time if not provided)
  static void addLog(
    String message, {
    bool isExpected = true,
    DateTime? timestamp,
  }) {
    if (!_enabled) return;

    final ts = timestamp ?? DateTime.now();
    final formattedTime =
        '${ts.hour.toString().padLeft(2, '0')}:${ts.minute.toString().padLeft(2, '0')}:${ts.second.toString().padLeft(2, '0')}';
    final fullMessage = '[$formattedTime] $message';

    // Create detailed log entry
    final logEntry = {
      'message': fullMessage,
      'text': message, // Plain message without timestamp
      'timestamp': ts,
      'isExpected': isExpected,
      'type': isExpected ? 'info' : 'warning',
    };

    // Add to storage
    _logs.add(logEntry);
    if (_logs.length > _maxLogs) {
      _logs.removeAt(0);
    }

    // Notify listeners (UI updates)
    logMessages.value = List.from(_logs);

    // Debug print
    if (kDebugMode) {
      print(fullMessage);
    }
  }

  /// Clear all logs
  static void clearLogs() {
    _logs.clear();
    logMessages.value = [];
  }

  /// Get last N logs
  ///
  /// Returns up to [count] most recent logs
  static List<Map<String, dynamic>> getLastLogs(int count) {
    return _logs.length > count
        ? _logs.sublist(_logs.length - count)
        : List.from(_logs);
  }

  /// Get last N logs as strings (for backward compatibility)
  static List<String> getLastLogsAsStrings(int count) {
    return getLastLogs(count).map((log) => log['message'] as String).toList();
  }

  /// Get logs filtered by type
  ///
  /// [isExpected]: If true, get info logs; if false, get warning/error logs
  static List<Map<String, dynamic>> getLogsByType(bool isExpected) {
    return _logs.where((log) => log['isExpected'] == isExpected).toList();
  }

  /// Get total count of logs
  static int get logCount => _logs.length;

  /// Get count of error/warning logs
  static int get errorCount => _logs.where((log) => !log['isExpected']).length;

  /// Get count of info logs
  static int get infoCount => _logs.where((log) => log['isExpected']).length;

  /// Add multiple logs at once
  static void addMultipleLogs(List<String> messages, {bool isExpected = true}) {
    for (final message in messages) {
      addLog(message, isExpected: isExpected);
    }
  }

  /// Export all logs as a formatted string
  static String exportAsString() {
    return _logs.map((log) => log['message']).join('\n');
  }

  /// Export all logs as JSON-compatible format
  static List<Map<String, dynamic>> exportAsJSON() {
    return _logs
        .map((log) => {
              'message': log['message'],
              'text': log['text'],
              'timestamp': (log['timestamp'] as DateTime).toIso8601String(),
              'isExpected': log['isExpected'],
              'type': log['type'],
            })
        .toList();
  }

  /// Search logs by text
  static List<Map<String, dynamic>> searchLogs(String query) {
    final lowerQuery = query.toLowerCase();
    return _logs
        .where((log) =>
            (log['message'] as String).toLowerCase().contains(lowerQuery))
        .toList();
  }
}
