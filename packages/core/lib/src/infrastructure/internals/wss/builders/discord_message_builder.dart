import 'dart:convert';

import 'package:mineral/src/domains/services/wss/constants/op_code.dart';

final class ShardMessageBuilder<OpCodeEnum extends OpCode> {
  OpCodeEnum? _code;
  dynamic _rawPayload;
  Map<String, dynamic>? _payload;

  ShardMessageBuilder();

  void setOpCode(OpCodeEnum code) => _code = code;

  void setPayload(dynamic payload) => _rawPayload = payload;

  void append(String key, dynamic payload) {
    _payload ??= {};
    _payload![key] = payload;
  }

  dynamic get _resolvedPayload => _payload ?? _rawPayload;

  Map<String, dynamic> toJson() {
    return {'op': _code!.value, 'd': _resolvedPayload};
  }

  String build() {
    return jsonEncode({'op': _code!.value, 'd': _resolvedPayload});
  }
}
