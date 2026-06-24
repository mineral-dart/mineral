import 'dart:async';
import 'dart:io';

import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/utils/file.dart';
import 'package:mineral/src/domains/services/packets/packet_dispatcher.dart';
import 'package:mineral/src/domains/services/wss/running_strategy.dart';
import 'package:mineral/src/infrastructure/services/wss/websocket_message.dart';
import 'package:path/path.dart' as path;

class DefaultRunningStrategy implements RunningStrategy {
  final PacketDispatcherContract packetDispatcher;
  final LoggerContract _logger;

  DefaultRunningStrategy(this.packetDispatcher, {required LoggerContract logger})
      : _logger = logger;

  @override
  Future<void> init(RunningStrategyFactory createShards) async {
    final version = await resolveVersion();
    _logger.info('Core version: $version');
    await createShards(this);
  }

  /// Reads the core version from pubspec.yaml files at runtime.
  ///
  /// Returns 'unknown' if the pubspec cannot be read (e.g. in a compiled
  /// binary or Docker image without sources present). All dynamic map accesses
  /// use safe [is]-checks to avoid [TypeError]/[NoSuchMethodError].
  Future<String> resolveVersion() async {
    try {
      final package = await readPubspec(Directory.current.path);

      final deps = package['dependencies'];
      if (deps is! Map) {
        return 'unknown';
      }

      final coreVersion = deps['mineral'];

      // YamlMap is a subtype of Map; accepting Map covers both real YAML
      // parsing and plain-Map test doubles.
      if (coreVersion is Map) {
        final depPath = coreVersion['path'];
        if (depPath is! String) {
          return 'unknown';
        }
        final location = path.join(Directory.current.path, depPath);
        final remoteCorePackage = await readPubspec(location);
        final version = remoteCorePackage['version'];
        return version is String ? version : 'unknown';
      }

      return coreVersion is String ? coreVersion : 'unknown';
    } on Exception {
      return 'unknown';
    }
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
