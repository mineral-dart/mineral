import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/api/common/permissions.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/common/utils/helper.dart';
import 'package:mineral/src/domains/common/utils/utils.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/types/serializer.dart';

final class MemberSerializer implements SerializerContract<Member> {
  final MarshallerContract _marshaller;
  final EntityContext _ctx;

  MemberSerializer(this._marshaller, this._ctx);

  @override
  Future<Map<String, dynamic>> normalize(Map<String, dynamic> json) async {
    // Handle both nested user object (from GET) and flat structure (from PATCH)
    final user = json['user'] as Map<String, dynamic>?;
    final userId = user?['id'] ?? json['id'];
    final username = user?['username'] ?? json['username'];
    final globalName = user?['global_name'] ?? json['global_name'];
    final discriminator = user?['discriminator'] ?? json['discriminator'];
    final avatar = user?['avatar'] ?? json['avatar'];
    final avatarDecorationData =
        user?['avatar_decoration_data'] ?? json['avatar_decoration_data'];
    final publicFlags = user?['public_flags'] ?? json['public_flags'];
    final isBot = user?['bot'] ?? json['bot'] ?? false;
    final mfaEnabled = user?['mfa_enabled'] ?? json['mfa_enabled'] ?? false;
    final locale = user?['locale'] ?? json['locale'];
    final premiumType = user?['premium_type'] ?? json['premium_type'];

    final payload = {
      'id': userId,
      'username': username,
      'nickname': json['nick'],
      'global_name': globalName,
      'discriminator': discriminator,
      'assets': {
        'guild_id': json['guild_id'],
        'member_id': userId,
        'avatar': avatar,
        'avatar_decoration': avatarDecorationData?['sku_id'],
        'banner': json['banner'],
      },
      'flags': json['flags'],
      'roles': List.from(json['roles'] as Iterable<dynamic>? ?? []),
      'premium_since': json['premium_since'],
      'public_flags': publicFlags,
      'is_bot': isBot,
      'is_pending': json['pending'] ?? false,
      'timeout': json['communication_disabled_until'],
      'mfa_enabled': mfaEnabled,
      'locale': locale,
      'premium_type': premiumType,
      'joined_at': json['joined_at'],
      'permissions': json['permissions'],
      'accent_color': json['accent_color'],
      'guild_id': json['guild_id'],
    };

    final cacheKey = _marshaller.cacheKey.member(json['guild_id'] as String, userId as String);
    await _marshaller.cache?.put(cacheKey, payload);

    return payload;
  }

  @override
  Future<Member> serialize(Map<String, dynamic> json) async {
    final assets = Map<String, dynamic>.from(json['assets'] as Map<dynamic, dynamic>);
    final memberAsset = MemberAssets(
      avatar: Helper.createOrNull(
          field: assets['avatar'],
          fn: () => ImageAsset(['avatars', assets['member_id'].toString()],
              assets['avatar'].toString())),
      avatarDecoration: Helper.createOrNull(
          field: assets['avatar_decoration'],
          fn: () => ImageAsset(
              ['avatar-decorations', assets['member_id'].toString()],
              assets['avatar_decoration'].toString())),
      banner: Helper.createOrNull(
          field: assets['banner'],
          fn: () =>
              ImageAsset(['banners', assets['member_id'] as String], assets['banner'] as String)),
    );

    final memberRoleManager = MemberRoleManager(
        List.from(json['roles'] as Iterable<dynamic>).map((e) => Snowflake.parse(e as String)).toList(),
        Snowflake.parse(json['guild_id']),
        Snowflake.parse(json['id'] as String),
        ctx: _ctx);

    return Member(
      ctx: _ctx,
      id: Snowflake.parse(json['id'] as String),
      guildId: Snowflake.parse(json['guild_id'] as String),
      username: (json['nick'] ?? json['username']) as String,
      nickname: (json['nick'] ?? json['display_name']) as String?,
      globalName: json['global_name'] as String?,
      discriminator: json['discriminator'] as String?,
      assets: memberAsset,
      flags: MemberFlagsManager(
          bitfieldToList(MemberFlag.values, json['flags'] as int),
          ctx: _ctx),
      premiumSince: Helper.createOrNull(
          field: json['premium_since'],
          fn: () => DateTime.parse(json['premium_since'] as String)),
      publicFlags: json['public_flags'] as int?,
      roles: memberRoleManager,
      isBot: json['is_bot'] as bool? ?? false,
      isPending: json['is_pending'] as bool? ?? false,
      timeout: MemberTimeout(
          duration: Helper.createOrNull(
              field: json['communication_disabled_until'],
              fn: () => DateTime.parse(json['communication_disabled_until'] as String))),
      mfaEnabled: json['mfa_enabled'] as bool? ?? false,
      locale: json['locale'] as String?,
      premiumType: PremiumTier.values.firstWhere(
          (e) => e == json['premium_type'],
          orElse: () => PremiumTier.none),
      joinedAt: Helper.createOrNull(
          field: json['joined_at'],
          fn: () => DateTime.parse(json['joined_at'] as String)),
      permissions: switch (json['permissions']) {
        int() => Permissions.fromInt(json['permissions'] as int),
        String() => Permissions.fromInt(int.parse(json['permissions'] as String)),
        _ => Permissions.fromInt(0),
      },
      accentColor: json['accent_color'] as int?,
    );
  }

  @override
  Future<Map<String, dynamic>> deserialize(Member member) async {
    return {
      'id': member.id.value,
      'username': member.username,
      'nickname': member.nickname,
      'global_name': member.globalName,
      'discriminator': member.discriminator,
      'assets': {
        'avatar': member.assets.avatar?.hash,
        'avatar_decoration': member.assets.avatarDecoration?.hash,
        'banner': member.assets.banner?.hash,
      },
      'roles': member.roles.currentIds.map((e) => e.value).toList(),
      'flags': listToBitfield(member.flags.list),
      'premium_since': member.premiumSince?.toIso8601String(),
      'public_flags': member.publicFlags,
      'is_bot': member.isBot,
      'is_pending': member.isPending,
      'timeout': member.timeout.duration?.toIso8601String(),
      'mfa_enabled': member.mfaEnabled,
      'locale': member.locale,
      'premium_type': member.premiumType.value,
      'joined_at': member.joinedAt?.toIso8601String(),
      'permissions': listToBitfield(member.permissions.list),
      'accent_color': member.accentColor,
      'guild_id': member.guildId.value,
    };
  }
}
