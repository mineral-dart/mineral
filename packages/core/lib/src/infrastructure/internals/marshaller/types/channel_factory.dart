import 'dart:async';

import 'package:mineral/src/api/common/channel.dart';
import 'package:mineral/src/api/common/types/channel_type.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/services/marshaller/marshaller.dart';

abstract interface class ChannelFactoryContract<T extends Channel> {
  ChannelType get type;
  FutureOr<Map<String, dynamic>> normalize(
      MarshallerContract marshaller, Map<String, dynamic> json);
  FutureOr<T> serialize(MarshallerContract marshaller, EntityContext ctx,
      Map<String, dynamic> json);
  FutureOr<Map<String, dynamic>> deserialize(
      MarshallerContract marshaller, T channel);
}
