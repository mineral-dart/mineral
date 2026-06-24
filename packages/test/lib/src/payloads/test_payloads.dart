/// Lightweight, framework-agnostic wrappers used by builders and recorders.
///
/// These types stand in for the corresponding Mineral domain objects (`User`,
/// `Guild`, `Member`, `Role`, `Channel`) at the boundary between user tests
/// and the framework. Simulators convert them to real Mineral types when
/// invoking command/event/component dispatchers.
library;

import 'dart:math' as math;

final _rng = math.Random();

String generateId() {
  final hi = (_rng.nextInt(1 << 30) << 30);
  final lo = _rng.nextInt(1 << 30);
  return (hi | lo).toString();
}

/// A test-only stand-in for [User].
final class TestUser {
  final String id;
  final String username;
  final String discriminator;
  final bool bot;
  final String? globalName;

  const TestUser({
    required this.id,
    required this.username,
    required this.discriminator,
    required this.bot,
    required this.globalName,
  });

  Map<String, dynamic> toRawJson() => {
    'id': id,
    'username': username,
    'discriminator': discriminator,
    'global_name': globalName,
    'bot': bot,
    'avatar': null,
  };

  @override
  bool operator ==(Object other) => other is TestUser && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'TestUser(id: $id, username: $username)';
}

/// A test-only stand-in for [Guild].
final class TestGuild {
  final String id;
  final String name;
  final String ownerId;

  const TestGuild({
    required this.id,
    required this.name,
    required this.ownerId,
  });

  Map<String, dynamic> toRawJson() => {
    'id': id,
    'name': name,
    'owner_id': ownerId,
    'description': null,
    'icon': null,
    'splash': null,
    'banner': null,
    'application_id': null,
    'settings': const <String, dynamic>{},
    'channel_settings': const <String, dynamic>{},
  };

  @override
  bool operator ==(Object other) => other is TestGuild && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'TestGuild(id: $id, name: $name)';
}

/// A test-only stand-in for [Role].
final class TestRole {
  final String id;
  final String name;
  final String guildId;
  final int color;
  final int position;

  const TestRole({
    required this.id,
    required this.name,
    required this.guildId,
    required this.color,
    required this.position,
  });

  Map<String, dynamic> toRawJson() => {
    'id': id,
    'name': name,
    'color': color,
    'hoist': false,
    'position': position,
    'permissions': '0',
    'managed': false,
    'mentionable': false,
    'flags': 0,
    'guild_id': guildId,
  };

  @override
  bool operator ==(Object other) => other is TestRole && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'TestRole(id: $id, name: $name)';
}

/// A test-only stand-in for [Member].
final class TestMember {
  final String id;
  final String guildId;
  final TestUser user;
  final List<TestRole> roles;
  final String? nickname;

  TestMember({
    required this.id,
    required this.guildId,
    required this.user,
    required this.roles,
    required this.nickname,
  });

  Map<String, dynamic> toRawJson() => {
    'user': user.toRawJson(),
    'nick': nickname,
    'guild_id': guildId,
    'roles': roles.map((r) => r.id).toList(),
    'flags': 0,
    'joined_at': DateTime.now().toUtc().toIso8601String(),
  };

  @override
  bool operator ==(Object other) =>
      other is TestMember && other.id == id && other.guildId == guildId;

  @override
  int get hashCode => Object.hash(id, guildId);

  @override
  String toString() => 'TestMember(id: $id, guild: $guildId)';
}

/// A test-only stand-in for [Channel].
final class TestChannel {
  final String id;
  final String name;
  final String? guildId;
  final int type;

  const TestChannel({
    required this.id,
    required this.name,
    required this.guildId,
    required this.type,
  });

  Map<String, dynamic> toRawJson() => {
    'id': id,
    'name': name,
    'guild_id': guildId,
    'type': type,
  };

  @override
  bool operator ==(Object other) => other is TestChannel && other.id == id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'TestChannel(id: $id, name: $name)';
}
