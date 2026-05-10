import 'dart:async';
import 'dart:io';

import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/utils/file.dart';
import 'package:mineral/src/domains/services/packets/packet_dispatcher.dart';
import 'package:mineral/src/domains/services/wss/running_strategy.dart';
import 'package:mineral/src/infrastructure/services/wss/websocket_message.dart';
import 'package:path/path.dart' as path;
import 'package:yaml/yaml.dart';

final class DefaultRunningStrategy implements RunningStrategy {
  final PacketDispatcherContract packetDispatcher;
  final LoggerContract _logger;

  DefaultRunningStrategy(this.packetDispatcher, {required LoggerContract logger})
      : _logger = logger;

  @override
  Future<void> init(RunningStrategyFactory createShards) async {
    final package = await readPubspec(Directory.current.path);

    final coreVersion = package['dependencies']['mineral'];
    String version = 'not found';

    if (coreVersion case final YamlMap dep) {
      if (dep['path'] != null) {
        final location = path.join(Directory.current.path, dep['path'] as String);
        final remoteCorePackage = await readPubspec(location);
        version = remoteCorePackage['version'] as String;
      }
    } else {
      version = package['dependencies']['mineral'] as String;
    }

    _logger.info('Core version: $version');

    await createShards(this);
  }

  Future<Map> readPubspec(String location) async {
    final packageFile = File(path.join(location, 'pubspec.yaml'));
    return packageFile.readAsYaml();
  }

  @override
  void dispatch(WebsocketMessage payload) {
    packetDispatcher.dispatch(payload.content);
  }
}
