import 'package:mineral/api.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/common/utils/helper.dart';
import 'package:mineral/src/domains/services/marshaller/marshaller.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/types/serializer.dart';

final class InviteSerializer implements SerializerContract<Invite> {
  final MarshallerContract _marshaller;
  final EntityContext _ctx;

  InviteSerializer(this._marshaller, this._ctx);

  @override
  Future<Map<String, dynamic>> normalize(Map<String, dynamic> json) async {
    final inviter = json['inviter'] as Map<String, dynamic>?;
    final guild = json['guild'] as Map<String, dynamic>?;
    final channel = json['channel'] as Map<String, dynamic>?;

    // Discord sends two incompatible shapes into this method. The REST
    // invite object (InvitePart.get/create) nests a partial `guild` and
    // `channel` and never carries a flat `guild_id`/`channel_id`. The
    // gateway INVITE_CREATE event (InviteCreatePacket) is the opposite: it
    // carries flat `guild_id`/`channel_id` and no nested objects. Both IDs
    // are independently optional regardless of shape — group-DM invites
    // have no guild at all.
    final guildId = json['guild_id'] as String? ?? guild?['id'] as String?;
    final channelId =
        json['channel_id'] as String? ?? channel?['id'] as String?;

    final payload = {
      'channelId': channelId,
      'code': json['code'],
      'createdAt': json['created_at'],
      'expiresAt': json['expires_at'],
      'guildId': guildId,
      'inviterId': inviter?['id'],
      'maxAge': json['max_age'],
      'maxUses': json['max_uses'],
      'temporary': json['temporary'],
      'type': json['type'],
    };

    final code = json['code'] as String;
    await _marshaller.cache?.put(_marshaller.cacheKey.invite(code), payload);

    return payload;
  }

  @override
  Future<Invite> serialize(Map<String, dynamic> json) async {
    return Invite(
      ctx: _ctx,
      type: InviteType.of(json['type'] as int? ?? InviteType.guild.value),
      code: json['code'] as String,
      inviterId: Snowflake.nullable(json['inviterId'] as String?),
      maxAge: Duration(seconds: json['maxAge'] as int? ?? 0),
      maxUses: json['maxUses'] as int? ?? 0,
      isTemporary: json['temporary'] as bool? ?? false,
      channelId: Snowflake.nullable(json['channelId']),
      guildId: Snowflake.nullable(json['guildId']),
      createdAt: Helper.createOrNull(
        field: json['createdAt'],
        fn: () => DateTime.parse(json['createdAt'] as String),
      ),
      expiresAt: Helper.createOrNull(
        field: json['expiresAt'],
        fn: () => DateTime.parse(json['expiresAt'] as String),
      ),
    );
  }

  @override
  Map<String, dynamic> deserialize(Invite invite) {
    return {
      'channelId': invite.channelId?.value,
      'code': invite.code,
      'createdAt': invite.createdAt?.toIso8601String(),
      'expiresAt': invite.expiresAt?.toIso8601String(),
      'guildId': invite.guildId?.value,
      'inviterId': invite.inviterId?.value,
      'maxAge': invite.maxAge.inSeconds,
      'maxUses': invite.maxUses,
      'temporary': invite.isTemporary,
      'type': invite.type.value,
    };
  }
}
