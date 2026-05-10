import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/commands/command_context.dart';

final class MessageCommandContext extends CommandContext {
  final Message target;
  final Server? server;

  MessageCommandContext({
    required super.id,
    required super.applicationId,
    required super.token,
    required super.version,
    required this.target,
    this.server,
    super.channel,
  });

  static Future<MessageCommandContext> fromMap(MarshallerContract marshaller,
      DataStoreContract datastore, Map<String, dynamic> payload) async {
    final data = payload['data'] as Map<String, dynamic>;
    final targetId = data['target_id'] as String;
    final resolved = data['resolved'] as Map<String, dynamic>?;

    final messagesMap =
        resolved?['messages'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final messageJson = messagesMap[targetId] as Map<String, dynamic>?;

    if (messageJson == null) {
      throw StateError(
          'Cannot build MessageCommandContext: target message $targetId not '
          'present in interaction.data.resolved.messages');
    }

    final guildId = payload['guild_id'] as String?;

    final enrichedMessageJson = {
      ...messageJson,
      if (guildId != null && messageJson['guild_id'] == null)
        'guild_id': guildId,
      if (messageJson['channel_id'] == null && payload['channel_id'] != null)
        'channel_id': payload['channel_id'],
    };

    final raw =
        await marshaller.serializers.message.normalize(enrichedMessageJson);
    final target = await marshaller.serializers.message.serialize(raw);
    Server? server;
    if (guildId != null) {
      server = await datastore.server.get(guildId, false);
    }

    final channelId = payload['channel_id'] as String?;

    return MessageCommandContext(
      id: Snowflake.parse(payload['id']),
      applicationId: Snowflake.parse(payload['application_id']),
      token: payload['token'] as String,
      version: payload['version'] as int,
      target: target,
      server: server,
      channel: channelId != null
          ? await datastore.channel.get(channelId, false)
          : null,
    );
  }
}
