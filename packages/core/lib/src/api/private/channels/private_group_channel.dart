import 'package:mineral/api.dart';
import 'package:mineral/src/api/common/managers/message_manager.dart';

final class PrivateGroupChannel extends Channel {
  final ChannelProperties _properties;

  late final MessageManager<PrivateMessage> messages;

  @override
  Snowflake get id => _properties.id;

  @override
  ChannelType get type => _properties.type;

  List<User> get users => _properties.recipients;

  PrivateGroupChannel(this._properties) {
    messages = MessageManager(_properties.id, ctx: _properties.ctx);
  }
}
