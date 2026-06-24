import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

enum GuildScheduledEventStatus {
  scheduled(1),
  active(2),
  completed(3),
  canceled(4);

  const GuildScheduledEventStatus(this.value);
  final int value;

  factory GuildScheduledEventStatus.of(int value) =>
      values.firstWhere((e) => e.value == value);
}

enum GuildScheduledEventEntityType {
  stageInstance(1),
  voice(2),
  external(3);

  const GuildScheduledEventEntityType(this.value);
  final int value;

  factory GuildScheduledEventEntityType.of(int value) =>
      values.firstWhere((e) => e.value == value);
}

enum GuildScheduledEventPrivacyLevel {
  guildOnly(2);

  const GuildScheduledEventPrivacyLevel(this.value);
  final int value;

  factory GuildScheduledEventPrivacyLevel.of(int value) =>
      values.firstWhere((e) => e.value == value);
}

final class GuildScheduledEventEntityMetadata {
  final String? location;

  GuildScheduledEventEntityMetadata({this.location});

  Map<String, dynamic> toJson() => {if (location != null) 'location': location};
}

final class GuildScheduledEvent {
  final EntityContext _ctx;
  DataStoreContract get _datastore => _ctx.datastore;

  final Snowflake id;
  final Snowflake guildId;
  final Snowflake? channelId;
  final Snowflake? creatorId;
  final String name;
  final String? description;
  final DateTime scheduledStartTime;
  final DateTime? scheduledEndTime;
  final GuildScheduledEventPrivacyLevel privacyLevel;
  final GuildScheduledEventStatus status;
  final GuildScheduledEventEntityType entityType;
  final Snowflake? entityId;
  final GuildScheduledEventEntityMetadata? entityMetadata;
  final int? userCount;
  final String? image;

  GuildScheduledEvent({
    required EntityContext ctx,
    required this.id,
    required this.guildId,
    required this.name,
    required this.scheduledStartTime,
    required this.privacyLevel,
    required this.status,
    required this.entityType,
    this.channelId,
    this.creatorId,
    this.description,
    this.scheduledEndTime,
    this.entityId,
    this.entityMetadata,
    this.userCount,
    this.image,
  }) : _ctx = ctx;

  Future<Guild> resolveServer() async {
    return _datastore.guild.get(guildId.value, false);
  }

  Future<T?> resolveChannel<T extends Channel>() async {
    if (channelId == null) {
      return null;
    }
    return _datastore.channel.get<T>(channelId!.value, false);
  }

  Future<User?> resolveCreator() async {
    if (creatorId == null) {
      return null;
    }
    return _datastore.user.get(creatorId!.value, false);
  }

  Future<GuildScheduledEvent?> update({
    Object? channelId,
    GuildScheduledEventEntityMetadata? entityMetadata,
    String? name,
    GuildScheduledEventPrivacyLevel? privacyLevel,
    DateTime? scheduledStartTime,
    DateTime? scheduledEndTime,
    String? description,
    GuildScheduledEventEntityType? entityType,
    GuildScheduledEventStatus? status,
    String? image,
    String? reason,
  }) {
    return _datastore.scheduledEvent.update(
      guildId: guildId.value,
      id: id.value,
      channelId: channelId,
      entityMetadata: entityMetadata,
      name: name,
      privacyLevel: privacyLevel,
      scheduledStartTime: scheduledStartTime,
      scheduledEndTime: scheduledEndTime,
      description: description,
      entityType: entityType,
      status: status,
      image: image,
      reason: reason,
    );
  }

  Future<void> delete({String? reason}) {
    return _datastore.scheduledEvent.delete(
      guildId: guildId.value,
      id: id.value,
      reason: reason,
    );
  }

  Future<List<GuildScheduledEventUser>> fetchUsers({
    int? limit,
    bool? withMember,
    Object? before,
    Object? after,
  }) {
    return _datastore.scheduledEvent.fetchUsers(
      guildId: guildId.value,
      id: id.value,
      limit: limit,
      withMember: withMember,
      before: before,
      after: after,
    );
  }
}

final class GuildScheduledEventUser {
  final Snowflake eventId;
  final Snowflake userId;
  final Snowflake? memberId;

  GuildScheduledEventUser({
    required this.eventId,
    required this.userId,
    this.memberId,
  });
}
