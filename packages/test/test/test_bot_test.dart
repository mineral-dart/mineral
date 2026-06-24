import 'package:mineral/container.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral_test/mineral_test.dart';
import 'package:test/test.dart';

void main() {
  group('TestBot', () {
    test('boots and disposes cleanly', () async {
      final bot = await TestBot.create();
      addTearDown(bot.dispose);

      expect(bot.commands, isNotNull);
      expect(bot.components, isNotNull);
      expect(bot.logger, isNotNull);
    });

    test('binds Mineral contracts on the active IoC container', () async {
      final bot = await TestBot.create();
      addTearDown(bot.dispose);

      expect(ioc.resolve<LoggerContract>(), same(bot.logger));
      expect(
        ioc.resolve<CommandInteractionManagerContract>(),
        same(bot.commands),
      );
      expect(
        ioc.resolve<InteractiveComponentManagerContract>(),
        same(bot.components),
      );
      expect(ioc.resolveOrNull<MarshallerContract>(), isNotNull);
      expect(ioc.resolveOrNull<DataStoreContract>(), isNotNull);
      expect(ioc.resolveOrNull<HttpClientContract>(), isNotNull);
    });

    test('boot + dispose completes in under 100ms', () async {
      final stopwatch = Stopwatch()..start();
      final bot = await TestBot.create();
      await bot.dispose();
      stopwatch.stop();

      expect(stopwatch.elapsedMilliseconds, lessThan(100));
    });

    test('successive bots get isolated IoC containers', () async {
      final first = await TestBot.create();
      final firstLogger = first.logger;
      await first.dispose();

      final second = await TestBot.create();
      addTearDown(second.dispose);

      expect(second.logger, isNot(same(firstLogger)));
    });

    test('dispose restores the previous global container', () async {
      final outer = IocContainer();
      final restoreOuter = scopedIoc(outer);
      addTearDown(restoreOuter);

      final bot = await TestBot.create();
      expect(ioc, isNot(same(outer)));

      await bot.dispose();
      expect(ioc, same(outer));
    });
  });
}
