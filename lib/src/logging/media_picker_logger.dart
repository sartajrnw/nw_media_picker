import 'package:flutter/foundation.dart';

/// Logging abstraction used throughout the package.
///
/// The package never depends on Crashlytics, Sentry, or any concrete logging
/// SDK. Consuming apps may supply their own implementation to forward logs to
/// whatever backend they use.
abstract interface class MediaPickerLogger {
  /// Logs a debug-level message.
  void debug(String message);

  /// Logs an info-level message.
  void info(String message);

  /// Logs a warning-level message.
  void warning(String message);

  /// Logs an error, optionally with the originating [error] and [stackTrace].
  void error(String message, {Object? error, StackTrace? stackTrace});
}

/// Default logger: prints via [debugPrint] in debug mode only, and is a no-op
/// in release/profile builds.
class DebugMediaPickerLogger implements MediaPickerLogger {
  /// Creates the default debug logger.
  const DebugMediaPickerLogger();

  void _log(String level, String message) {
    if (kDebugMode) {
      debugPrint('[nw_media_picker][$level] $message');
    }
  }

  @override
  void debug(String message) => _log('DEBUG', message);

  @override
  void info(String message) => _log('INFO', message);

  @override
  void warning(String message) => _log('WARN', message);

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      debugPrint(
        '[nw_media_picker][ERROR] $message'
        '${error == null ? '' : '\n  error: $error'}'
        '${stackTrace == null ? '' : '\n$stackTrace'}',
      );
    }
  }
}

/// A logger that discards everything. Useful for tests.
class SilentMediaPickerLogger implements MediaPickerLogger {
  /// Creates a no-op logger.
  const SilentMediaPickerLogger();

  @override
  void debug(String message) {}

  @override
  void info(String message) {}

  @override
  void warning(String message) {}

  @override
  void error(String message, {Object? error, StackTrace? stackTrace}) {}
}
