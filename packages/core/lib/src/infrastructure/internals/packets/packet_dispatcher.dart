import 'dart:async';

import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/kernel.dart';
import 'package:mineral/src/domains/services/packets/packet_dispatcher.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class PacketDispatcher implements PacketDispatcherContract {
  final Map<String, StreamController<ShardMessage>> _controllers = {};
  final List<StreamSubscription> _subscriptions = [];
  final Kernel _kernel;

  PacketDispatcher(this._kernel);

  StreamController<ShardMessage> _controllerFor(String packetName) {
    return _controllers.putIfAbsent(
        packetName, StreamController<ShardMessage>.broadcast);
  }

  @override
  void listen(PacketTypeContract packet,
      Function(ShardMessage, DispatchEvent) listener) {
    final controller = _controllerFor(packet.name);

    final subscription = controller.stream.listen((ShardMessage message) async {
      try {
        await Function.apply(
            listener, [message, _kernel.eventListener.dispatcher.dispatch]);
      } on Exception catch (e, stackTrace) {
        _kernel.logger.error(
          'PacketDispatcher: error in listener for ${message.type}: $e',
        );
        _kernel.logger.trace('$stackTrace');
      } on Error catch (e, stackTrace) {
        _kernel.logger.error(
          'PacketDispatcher: fatal error in listener for ${message.type}: $e',
        );
        _kernel.logger.trace('$stackTrace');
      }
    });

    _subscriptions.add(subscription);
  }

  @override
  void dispatch(dynamic payload) {
    if (payload case ShardMessage(type: final String type)) {
      final controller = _controllers[type];
      if (controller != null && controller.hasListener) {
        controller.add(payload);
      }
    }
  }

  @override
  void dispose() {
    for (final subscription in _subscriptions) {
      subscription.cancel();
    }
    _subscriptions.clear();
    for (final controller in _controllers.values) {
      controller.close();
    }
    _controllers.clear();
  }
}
