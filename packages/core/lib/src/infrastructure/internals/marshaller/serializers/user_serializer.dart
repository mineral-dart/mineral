import 'package:mineral/api.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/common/utils/helper.dart';
import 'package:mineral/src/domains/services/marshaller/marshaller.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/types/serializer.dart';

final class UserSerializer implements SerializerContract<User> {
  final MarshallerContract _marshaller;
  final EntityContext _ctx;

  UserSerializer(this._marshaller, this._ctx);

  @override
  Future<Map<String, dynamic>> normalize(Map<String, dynamic> json) async {
    final payload = {
      'id': json['id'],
      'username': json['username'],
      'discriminator': json['discriminator'],
      'flags': json['flags'],
      'public_flags': json['public_flags'],
      'avatar': json['avatar'],
      'is_bot': json['bot'],
      'system': json['system'],
      'mfa_enabled': json['mfa_enabled'],
      'locale': json['locale'],
      'verified': json['verified'],
      'email': json['email'],
      'premium_type': json['premium_type'],
      'assets': {
        'user_id': json['user_id'],
        'avatar': json['avatar'],
        'avatar_decoration': json['avatar_decoration_data']?['sku_id'],
        'banner': json['banner'],
      },
    };

    final cacheKey = _marshaller.cacheKey.user(json['id'] as String);
    await _marshaller.cache?.put(cacheKey, payload);

    return payload;
  }

  @override
  Future<User> serialize(Map<String, dynamic> json) async {
    final userAssets = Map<String, dynamic>.from(
      json['assets'] as Map<dynamic, dynamic>,
    );
    final assets = UserAssets(
      avatar: Helper.createOrNull(
        field: userAssets['avatar'],
        fn: () => ImageAsset([
          'avatars',
          json['id'] as String,
        ], userAssets['avatar'] as String),
      ),
      avatarDecoration: Helper.createOrNull(
        field: userAssets['avatar_decoration'],
        fn: () => ImageAsset([
          'avatar-decorations',
          json['id'] as String,
        ], userAssets['avatar_decoration'] as String),
      ),
      banner: Helper.createOrNull(
        field: userAssets['banner'],
        fn: () => ImageAsset([
          'banners',
          json['id'] as String,
        ], userAssets['banner'] as String),
      ),
    );

    return User(
      ctx: _ctx,
      id: json['id'] as Snowflake,
      username: json['username'] as String,
      discriminator: json['discriminator'] as String,
      avatar: json['avatar'] as String?,
      bot: json['is_bot'] as bool?,
      system: json['system'] as bool?,
      mfaEnabled: json['mfa_enabled'] as bool?,
      locale: json['locale'] as String?,
      verified: json['verified'] as bool?,
      email: json['email'] as String?,
      flags: json['flags'] as int?,
      premiumType: PremiumTier.values.firstWhere(
        (e) => e == json['premium_type'],
        orElse: () => PremiumTier.none,
      ),
      publicFlags: json['public_flags'] as int?,
      assets: assets,
      createdAt: Helper.createOrNull(
        field: json['created_at'],
        fn: () => DateTime.parse(json['created_at'] as String),
      ),
      presence: null,
    );
  }

  @override
  Map<String, dynamic> deserialize(User user) {
    return {
      'id': user.id,
      'username': user.username,
      'discriminator': user.discriminator,
      'flags': user.flags,
      'public_flags': user.publicFlags,
      'avatar': user.avatar,
      'is_bot': user.bot,
      'system': user.system,
      'mfa_enabled': user.mfaEnabled,
      'locale': user.locale,
      'verified': user.verified,
      'email': user.email,
      'premium_type': user.premiumType?.value,
      'created_at': user.createdAt?.toIso8601String(),
      'assets': {
        'avatar': user.assets.avatar?.hash,
        'avatar_decoration': user.assets.avatarDecoration?.hash,
        'banner': user.assets.banner?.hash,
      },
    };
  }
}
