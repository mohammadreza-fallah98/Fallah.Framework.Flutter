enum LogLevel { debug, info, warning, error }

/// Logging contract. Apps plug in talker/logger/Sentry behind this interface
/// so framework packages never depend on a concrete logging library.
abstract interface class AppLogger {
  void log(LogLevel level, String message, {Object? error, StackTrace? stack});
}

/// Default logger: writes to the supplied `sink` (defaults to `print`) and
/// ignores levels below `minLevel`.
class ConsoleLogger implements AppLogger {
  ConsoleLogger({this.minLevel = LogLevel.debug, void Function(String)? sink})
      : _sink = sink ?? _defaultSink;

  final LogLevel minLevel;
  final void Function(String) _sink;

  static void _defaultSink(String line) {
    // Console output is this logger's whole purpose.
    // ignore: avoid_print
    print(line);
  }

  @override
  void log(LogLevel level, String message, {Object? error, StackTrace? stack}) {
    if (level.index < minLevel.index) return;
    final buffer = StringBuffer('[${level.name.toUpperCase()}] $message');
    if (error != null) buffer.write(' | $error');
    if (stack != null) buffer.write('\n$stack');
    _sink(buffer.toString());
  }
}
