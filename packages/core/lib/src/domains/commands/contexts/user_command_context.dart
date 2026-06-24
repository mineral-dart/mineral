import 'package:mineral/contracts.dart';
import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/api/guild/guild.dart';
import 'package:mineral/src/api/guild/member.dart';
import 'package:mineral/src/api/private/user.dart';
import 'package:mineral/src/domains/commands/command_context.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class UserCommandContext extends CommandContext {
  final User target;
  final Member? targetMember;
  final Guild? guild;

  UserCommandContext({
    required super.id,
    required super.applicationId,
    required super.token,
    required super.version,
    required super.ctx,
    required this.target,
    this.targetMember,
    this.guild,
    super.channel,
  });

  static Future<UserCommandContext> fromMap(
    MarshallerContract marshaller,
    DataStoreContract datastore,
    EntityContext ctx,
    Map<String, dynamic> payload,
  ) async {
    final data = payload['data'] as Map<String, dynamic>;
    final targetId = data['target_id'] as String;
    final resolved = data['resolved'] as Map<String, dynamic>?;

    final usersMap =
        resolved?['users'] as Map<String, dynamic>? ?? <String, dynamic>{};
    final userJson = usersMap[targetId] as Map<String, dynamic>?;

    if (userJson == null) {
      throw StateError(
        'Cannot build UserCommandContext: target user $targetId not '
        'present in interaction.data.resolved.users',
      );
    }

    final raw = await marshaller.serializers.user.normalize(userJson);
    final target = await marshaller.serializers.user.serialize(raw);

    final guildId = payload['guild_id'] as String?;
    Guild? guild;
    Member? targetMember;
    if (guildId != null) {
      guild = await datastore.guild.get(guildId, false);
      targetMember = await datastore.member.get(guildId, targetId, false);
    }

    final channelId = payload['channel_id'] as String?;

    return UserCommandContext(
      ctx: ctx,
      id: Snowflake.parse(payload['id']),
      applicationId: Snowflake.parse(payload['application_id']),
      token: payload['token'] as String,
      version: payload['version'] as int,
      target: target,
      targetMember: targetMember,
      guild: guild,
      channel: channelId != null
          ? await datastore.channel.get(channelId, false)
          : null,
    );
  }
}
