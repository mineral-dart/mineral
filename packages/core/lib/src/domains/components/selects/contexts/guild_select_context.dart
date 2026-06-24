import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/components/selects/select_context_base.dart';

final class GuildSelectContext extends SelectContextBase {
  DataStoreContract get _datastore => ctx.datastore;

  final Snowflake? memberId;

  final Snowflake guildId;

  GuildSelectContext({
    required super.id,
    required super.applicationId,
    required super.token,
    required super.version,
    required super.customId,
    required this.guildId,
    required super.messageId,
    required this.memberId,
    required super.channelId,
    required super.ctx,
  });

  Future<Member?> resolveMember({bool force = false}) async {
    if (memberId == null) {
      return null;
    }

    return _datastore.member.get(guildId.value, memberId!.value, force);
  }

  @override
  Future<GuildMessage?> resolveMessage({bool force = false}) async {
    if (messageId == null) {
      return null;
    }

    return _datastore.message
        .get<GuildMessage>(guildId.value, messageId!.value, force);
  }

  Future<T?> resolveChannel<T extends Channel>({bool force = false}) async {
    if (channelId == null) {
      return null;
    }

    return _datastore.channel.get<T>(channelId!.value, force);
  }

  Future<Guild?> resolveServer({bool force = false}) =>
      _datastore.guild.get(guildId.value, force);

  static Future<GuildSelectContext> fromMap(
      DataStoreContract datastore,
      EntityContext ctx,
      Map<String, dynamic> payload) async {
    return GuildSelectContext(
      ctx: ctx,
      customId: (payload['data'] as Map<String, dynamic>)['custom_id'] as String,
      id: Snowflake.parse(payload['id']),
      applicationId: Snowflake.parse(payload['application_id']),
      token: payload['token'] as String,
      version: payload['version'] as int,
      messageId: Snowflake.parse((payload['message'] as Map<String, dynamic>)['id']),
      memberId: Snowflake.parse(((payload['member'] as Map<String, dynamic>)['user'] as Map<String, dynamic>)['id']),
      guildId: Snowflake.parse(payload['guild_id']),
      channelId: Snowflake.parse(payload['channel_id']),
    );
  }
}
