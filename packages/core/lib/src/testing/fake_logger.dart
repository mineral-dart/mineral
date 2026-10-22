import 'package:mineral/contracts.dart';

/// An in-memory [LoggerContract] for use in tests.
///
/// Captured messages are available in [warnings], [errors], [traces], and
/// [infos] so test assertions can inspect what was logged.
final class FakeLogger implements LoggerContract {
  final List<String> warnings = [];
  final List<String> errors = [];
  final List<Object> traces = [];
  final List<String> infos = [];

  /// Mirrors `package:logging`: a zero-argument closure is evaluated so
  /// assertions see the produced message, not the thunk.
  @override
  void trace(Object message) =>
      traces.add(message is Object Function() ? message() : message);
  @override
  void fatal(Exception message) {}
  @override
  void error(String message) => errors.add(message);
  @override
  void warn(String message) => warnings.add(message);
  @override
  void info(String message) => infos.add(message);
}
