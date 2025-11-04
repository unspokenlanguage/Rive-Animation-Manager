// lib/src/helpers/log_manager.dart

import 'package:flutter/material.dart';

/// Manages logging for the Rive Animation Manager package.
///
/// Features:
/// - Log storage with timestamp
/// - ValueNotifier for reactive UI updates
/// - Log filtering and search
/// - Export logs as string or JSON
/// - Safe logging during widget build phases
class LogManager {
  static final LogManager _instance = LogManager._internal();

  /// ValueNotifier for reactive UI updates
  static final logMessages =
      ValueNotifier<List<Map<String, dynamic>>>(<Map<String, dynamic>>[]);

  /// Legacy list for backwards compatibility
  static final List<String> _logs = [];

  /// Internal flag to track build phase
  static bool _isInBuildPhase = false;

  factory LogManager() {
    return _instance;
  }

  LogManager._internal();

  /// Add a log message with safe handling during widget builds
  static void addLog(String message, {bool isExpected = true}) {
    final timestamp = DateTime.now().toString().split('.')[0].split(' ').last;
    final logEntry = {
      'message': message,
      'text': message,
      'timestamp': timestamp,
      'type': isExpected ? 'info' : 'error',
      'isExpected': isExpected,
    };

    _logs.add(message);
    if (_logs.length > 100) {
      _logs.removeAt(0);
    }

    // Defer notification if during build phase to prevent Flutter errors
    if (_isInBuildPhase) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _notifyListeners(logEntry);
      });
    } else {
      _notifyListeners(logEntry);
    }
  }

  /// Internal: Notify listeners of log changes
  static void _notifyListeners(Map<String, dynamic> logEntry) {
    if (!mounted) return;

    final newLogs = [...logMessages.value, logEntry];
    if (newLogs.length > 100) {
      newLogs.removeAt(0);
    }
    logMessages.value = newLogs;
  }

  /// Internal: Mark the start of a build phase to defer notifications
  static void markBuildPhaseStart() {
    _isInBuildPhase = true;
  }

  /// Internal: Mark the end of a build phase
  static void markBuildPhaseEnd() {
    _isInBuildPhase = false;
  }

  /// Check if widget binding is available (always true in Flutter apps)
  static bool get mounted => true;

  /// Get logs as unmodifiable list of strings (backwards compatible)
  static List<String> get logsAsStrings => List.unmodifiable(_logs);

  /// Get all logs as unmodifiable list
  static List<String> get logs => List.unmodifiable(_logs);

  /// Get total log count
  static int get logCount => _logs.length;

  /// Get count of error logs
  static int get errorCount =>
      logMessages.value.where((log) => log['type'] == 'error').length;

  /// Get count of info logs
  static int get infoCount =>
      logMessages.value.where((log) => log['type'] == 'info').length;

  /// Filter logs by expected/error type
  static List<Map<String, dynamic>> getLogsByType(bool isExpected) {
    return logMessages.value
        .where((log) => log['isExpected'] == isExpected)
        .toList();
  }

  /// Search logs by query string
  static List<Map<String, dynamic>> searchLogs(String query) {
    return logMessages.value
        .where((log) => log['message']
            .toString()
            .toLowerCase()
            .contains(query.toLowerCase()))
        .toList();
  }

  /// Export all logs as formatted string
  static String exportAsString() {
    return _logs.join('\n');
  }

  /// Export all logs as JSON string
  static String exportAsJSON() {
    return logMessages.value.toString();
  }

  /// Get last N logs as strings
  static List<String> getLastLogsAsStrings(int count) {
    final start = (_logs.length - count).clamp(0, _logs.length);
    return _logs.sublist(start);
  }

  /// Add multiple log messages at once
  static void addMultipleLogs(List<String> messages) {
    for (var msg in messages) {
      addLog(msg);
    }
  }

  /// Clear all logs
  static void clearLogs() {
    _logs.clear();
    logMessages.value = [];
  }

  /// Dispose and cleanup resources
  static void dispose() {
    _logs.clear();
    logMessages.dispose();
  }
}
