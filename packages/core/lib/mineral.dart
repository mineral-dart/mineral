/// The main entry-point for building bots with Mineral.
///
/// Imports everything a bot developer needs in one line:
/// ```dart
/// import 'package:mineral/mineral.dart';
/// ```
///
/// For contracts used when writing DI extensions or custom services,
/// use `package:mineral/mineral_contracts.dart` instead.
library;
export 'package:mineral/api.dart';
export 'package:mineral/container.dart';
export 'package:mineral/events.dart';
// Hide the concrete Logger implementation — bot code uses the Logger mixin
// from container.dart (ioc.resolve<LoggerContract>()) instead.
export 'package:mineral/services.dart' hide Logger;
export 'package:mineral/utils.dart';
