import 'package:mineral/api.dart';
import 'package:mineral/container.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/commands/command_declaration_bucket.dart';
import 'package:mineral/src/domains/common/kernel.dart';
import 'package:mineral/src/domains/common/utils/listenable.dart';
import 'package:mineral/src/domains/events/event_bucket.dart';
import 'package:mineral/src/domains/events/types/listenable_event.dart';

final class Client {
  final Kernel _kernel;

  final EventBucket events;

  final CommandBucket commands;

  final DataStoreContract rest;

  final CommandInteractionManagerContract _commands;

  final CacheProviderContract? _cache;

  IocContainer get container => ioc;

  LoggerContract get logger => _kernel.logger;

  WebsocketOrchestratorContract get wss => _kernel.wss;

  InteractiveComponentService get components => _kernel.interactiveComponent;

  Client(
    Kernel kernel, {
    required this.rest,
    required CommandInteractionManagerContract commandManager,
    CacheProviderContract? cache,
  }) : events = EventBucket(kernel),
       commands = CommandBucket(commandManager),
       _commands = commandManager,
       _cache = cache,
       _kernel = kernel;

  void register<T>(Listenable Function() constructor) {
    final instance = constructor();

    return switch (instance) {
      final CommandContract command => _commands.addCommand(command.build()),
      final GlobalState state => _kernel.globalState.register<T>(state as T),
      final Provider provider => _kernel.providerManager.register(provider),
      final ListenableEvent event => _kernel.eventListener.listen(
        event: event.event,
        handle: event.handler,
        customId: event.customId,
      ),
      final InteractiveComponent component =>
        _kernel.interactiveComponent.register(component),
      _ => throw UnimplementedError(),
    };
  }

  set onCommandError(void Function(CommandFailure failure) handler) {
    _commands.onCommandError = handler;
  }

  Future<void> init() async {
    await _cache?.init();
    await _kernel.init();
  }

  Future<void> dispose() => _kernel.dispose();
}
