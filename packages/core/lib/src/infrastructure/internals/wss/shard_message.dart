import 'package:collection/collection.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';

final class ShardMessage<T> implements ShardMessageContract<T, OpCode> {
  @override
  final String? type;

  @override
  final OpCode opCode;

  @override
  final int? sequence;

  @override
  final T payload;

  ShardMessage({
    required this.type,
    required this.opCode,
    required this.sequence,
    required this.payload,
  });

  factory ShardMessage.of(Map<String, dynamic> message) {
    final opCode =
        OpCode.values.firstWhereOrNull(
          (element) => element.value == message['op'],
        ) ??
        OpCode.unknown;

    return ShardMessage(
      type: message['t'] as String?,
      opCode: opCode,
      sequence: message['s'] as int?,
      payload: message['d'] as T,
    );
  }

  @override
  Object serialize() {
    return {'t': type, 'op': opCode.value, 's': sequence, 'd': payload};
  }
}
