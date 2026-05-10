import 'dart:async';
import 'dart:io';
import 'dart:isolate';

import 'package:glob/glob.dart';
import 'package:hmr/hmr.dart';
import 'package:mansion/mansion.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/runtime_state.dart';
import 'package:mineral/src/domains/services/packets/packet_dispatcher.dart';
import 'package:mineral/src/domains/services/wss/running_strategy.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/ready_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:mineral/src/infrastructure/internals/wss/websocket_isolate_message_transfert.dart';
import 'package:mineral/src/infrastructure/services/wss/websocket_message.dart';
import 'package:path/path.dart' as path;

final class HmrRunningStrategy implements RunningStrategy {
  final WebsocketOrchestratorContract _wss;
  final RuntimeState _runtimeState;

  final SendPort? _devPort;
  final PacketDispatcherContract _packetDispatcher;
  final List<Glob> _watchedFiles;

  late final Runner _runner;
  (File, int)? lastFileChanged;

  HmrRunningStrategy(
    this._devPort,
    this._packetDispatcher,
    this._watchedFiles, {
    required WebsocketOrchestratorContract wss,
    required RuntimeState runtimeState,
  })  : _wss = wss,
        _runtimeState = runtimeState;

  @override
  Future<void> init(RunningStrategyFactory createShards) async {
    if (Isolate.current.debugName == 'main') {
      // Main isolate spawns HMR child
      final mainFile =
          File(path.joinAll([Directory.current.path, 'bin', 'main.dart']));
      final tempDirectory = await Directory.systemTemp.createTemp();

      _runner = Runner(
          entrypoint: mainFile,
          tempDirectory: tempDirectory,
          isolateName: 'development');

      final dateTime = DateTime.now();

      Watcher(middlewares: [
        IgnoreMiddleware(
            ['~', '.dart_tool', '.git', '.idea', '.vscode', '.cursor']),
        IncludeMiddleware([Glob('**.dart'), ..._watchedFiles]),
        DebounceMiddleware(Duration(milliseconds: 50), dateTime),
      ], onStart: handleStart, onFileChange: handleModify)
          .watch();

      await _runner.run();

      _runner.listen((message) {
        _wss.send(WebsocketIsolateMessageTransfert.fromJson(message as Map<String, dynamic>));
      });

      await createShards(this);
    } else {
      final ReceivePort port = ReceivePort();
      final Stream stream = port.asBroadcastStream();
      _devPort!.send(port.sendPort);

      await for (final Map<String, dynamic> message in stream.cast<Map<String, dynamic>>()) {
        _packetDispatcher.dispatch(ShardMessage.of(message));
      }
    }
  }

  @override
  Future<void> dispatch(WebsocketMessage message) async {
    final strategy = _wss.config.encoding;
    final decoded = strategy.decode(message);
    final messageContent = decoded.content.serialize();

    if (messageContent case final Map<String, dynamic> json
        when json['t'] == PacketType.ready.name) {
      _runtimeState.readyPacketMessage =
          ReadyPacketMessage(decoded.content as ShardMessage<dynamic>);
    }

    await _runner.send(decoded.content.serialize());
  }

  Future<void> handleStart() async {
    final List<Sequence> sequences = [
      const CursorPosition.moveTo(0, 0),
      Clear.afterCursor,
      Clear.allAndScrollback,
      SetStyles(Style.foreground(Color.green)),
      Print('[hmr]'),
      Print(' wait to watch changes...'),
      SetStyles.reset,
      AsciiControl.lineFeed
    ];

    stdout.writeAnsiAll(sequences);
  }

  Future<void> handleModify(int eventType, File file) async {
    lastFileChanged = (
      file,
      file.path != lastFileChanged?.$1.path ? 0 : lastFileChanged!.$2 + 1
    );

    final action = switch (eventType) {
      FileSystemEvent.create => 'created',
      FileSystemEvent.modify => 'modified',
      FileSystemEvent.delete => 'deleted',
      FileSystemEvent.move => 'moved',
      _ => 'changed'
    };

    final List<Sequence> sequences = [
      const CursorPosition.moveTo(0, 0),
      Clear.afterCursor,
      Clear.allAndScrollback,
      SetStyles(Style.foreground(Color.green)),
      Print('[hmr] $action '),
      SetStyles(Style.foreground(Color.brightBlack)),
      Print(file.path.replaceFirst('${Directory.current.path}/', '')),
      SetStyles.reset
    ];

    if (lastFileChanged?.$2 != 0) {
      sequences.addAll([
        SetStyles(Style.foreground(Color.yellow)),
        Print(' (x${lastFileChanged!.$2})'),
        SetStyles.reset,
      ]);
    }

    sequences.add(AsciiControl.lineFeed);
    stdout.writeAnsiAll(sequences);

    await _runner.reload();

    if (_runtimeState.readyPacketMessage case final ReadyPacketMessage packet) {
      await _runner.send(packet.message.serialize());
    }
  }
}
