import 'dart:async';

import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/components/selects/select_context_base.dart';

final class PrivateSelectContext extends SelectContextBase {
  DataStoreContract get _datastore => ctx.datastore;

  final Snowflake userId;

  PrivateSelectContext({
    required super.id,
    required super.applicationId,
    required super.token,
    required super.version,
    required super.customId,
    required super.messageId,
    required this.userId,
    required super.channelId,
    required super.ctx,
  });

  Future<User?> resolveUser({bool force = false}) =>
      _datastore.user.get(userId.value, force);

  @override
  FutureOr<PrivateMessage?> resolveMessage({bool force = false}) {
    if ([channelId, messageId].contains(null)) {
      return null;
    }

    return _datastore.message.get(channelId!.value, messageId!.value, force);
  }

  FutureOr<PrivateChannel?> resolveChannel({bool force = false}) {
    if (channelId == null) {
      return null;
    }

    return _datastore.channel.get<PrivateChannel>(channelId!.value, force);
  }

  static Future<PrivateSelectContext> fromMap(
    MarshallerContract marshaller,
    DataStoreContract datastore,
    EntityContext ctx,
    Map<String, dynamic> payload,
  ) async {
    return PrivateSelectContext(
      ctx: ctx,
      customId:
          (payload['data'] as Map<String, dynamic>)['custom_id'] as String,
      id: Snowflake.parse(payload['id']),
      applicationId: Snowflake.parse(payload['application_id']),
      token: payload['token'] as String,
      version: payload['version'] as int,
      userId: Snowflake.parse((payload['user'] as Map<String, dynamic>)['id']),
      messageId: Snowflake.nullable(
        (payload['message'] as Map<String, dynamic>)['id'] as String?,
      ),
      channelId: Snowflake.nullable(payload['channel_id'] as String?),
    );
  }
}
