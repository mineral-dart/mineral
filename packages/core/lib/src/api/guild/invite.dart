import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class Invite {
  final EntityContext _ctx;
  DataStoreContract get _datastore => _ctx.datastore;

  final InviteType type;
  final String code;

  final Snowflake? guildId;
  final Snowflake? channelId;
  final Snowflake inviterId;

  final Duration maxAge;
  final int maxUses;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final bool isTemporary;

  Invite({
    required EntityContext ctx,
    required this.type,
    required this.code,
    required this.maxAge,
    required this.maxUses,
    required this.inviterId,
    required this.isTemporary,
    required this.createdAt,
    this.guildId,
    this.channelId,
    this.expiresAt,
  }) : _ctx = ctx;

  Future<User?> resolveInviter() {
    return _datastore.user.get(inviterId.value, false);
  }

  Future<T?> resolveChannel<T extends Channel>() async {
    if (channelId == null) {
      return null;
    }

    return _datastore.channel.get<T>(channelId!.value, false);
  }

  Future<InviteMetadata?> resolveMetadata({bool force = false}) {
    return _datastore.invite.getExtrasMetadata(code, force);
  }

  Future<void> delete({String? reason}) {
    return _datastore.invite.delete(code, reason);
  }
}

final class InviteMetadata {
  final int approximateMemberCount;
  final int approximatePresenceCount;

  InviteMetadata({
    this.approximateMemberCount = 0,
    this.approximatePresenceCount = 0,
  });
}

enum InviteType {
  guild(0),
  privateGroup(1),
  friend(2);

  const InviteType(this.value);
  final int value;

  factory InviteType.of(int value) {
    return values.firstWhere((e) => e.value == value);
  }
}

enum InviteTargetType {
  unknown(-1),
  stream(0),
  embededApplication(1);

  const InviteTargetType(this.value);
  final int value;

  factory InviteTargetType.of(int value) {
    return values.firstWhere((e) => e.value == value);
  }
}
