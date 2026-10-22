import 'package:mineral/contracts.dart';

final class NoopLogger implements LoggerContract {
  const NoopLogger();

  @override
  void trace(Object message) {}

  @override
  void fatal(Exception message) {}

  @override
  void error(String message) {}

  @override
  void warn(String message) {}

  @override
  void info(String message) {}
}
