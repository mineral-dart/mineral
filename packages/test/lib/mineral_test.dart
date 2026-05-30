/// Testing utilities for the Mineral Discord bot framework.
///
/// ```dart
/// import 'package:mineral_test/mineral_test.dart';
/// import 'package:test/test.dart';
///
/// void main() {
///   late TestBot bot;
///
///   setUp(() async {
///     bot = await TestBot.create();
///   });
///
///   tearDown(() => bot.dispose());
///
///   test('replies with pong', () async {
///     bot.events.register(PingListener());
///     final user = UserBuilder().build();
///
///     await bot.simulateCommand('ping', invokedBy: user);
///
///     expect(
///       bot.actions.interactionReplies,
///       contains(isInteractionReplied(content: 'pong')),
///     );
///   });
/// }
/// ```
library;

export 'src/data_store/test_data_store_facade.dart';
export 'src/dsl/dsl.dart';
export 'src/handlers/listener.dart';
export 'src/kernel/test_bot.dart';
export 'src/kernel/test_bot_events.dart';
export 'src/kernel/test_kernel.dart';
export 'src/matchers/matchers.dart';
export 'src/payloads/builders.dart';
export 'src/payloads/test_payloads.dart';
export 'src/recorders/bot_actions.dart';
export 'src/recorders/handler_error.dart';
export 'src/recorders/recorded_action.dart';
export 'src/simulators/registries.dart' show TestInteractionResponder;

// The package name (`mineral_test`) makes this library's filename match the
// `_test.dart` glob used by `package:test`. When `dart test` scans broad
// paths (e.g. `dart test .` from the workspace root), it tries to load this
// library file and fails on the missing `main`. The empty entry point keeps
// the runner happy — it loads, finds zero tests, and moves on.
void main() {}
