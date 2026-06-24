import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/api/common/user_client.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class User implements UserClient {
  final EntityContext _ctx;
  DataStoreContract get _datastore => _ctx.datastore;

  final Snowflake id;
  final String username;
  final String discriminator;
  final String? avatar;
  final bool? bot;
  final bool? system;
  final bool? mfaEnabled;
  final String? locale;
  final bool? verified;
  final String? email;
  final int? flags;
  final PremiumTier? premiumType;
  final int? publicFlags;
  final UserAssets assets;
  final DateTime? createdAt;
  Presence? presence;

  User({
    required EntityContext ctx,
    required this.id,
    required this.username,
    required this.discriminator,
    required this.avatar,
    required this.bot,
    required this.system,
    required this.mfaEnabled,
    required this.locale,
    required this.verified,
    required this.email,
    required this.flags,
    required this.premiumType,
    required this.publicFlags,
    required this.assets,
    required this.createdAt,
    required this.presence,
  }) : _ctx = ctx;

  /// Resolve the user as [Member] from [Guild] id.
  /// ```dart
  /// final member = await user.toMember('240561194958716928');
  /// ```
  Future<Member?> toMember(String guildId) =>
      _datastore.member.get(guildId, id.value, false);

  @override
  String toString() => '<@$id>';
}
