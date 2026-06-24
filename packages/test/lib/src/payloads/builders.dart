import 'test_payloads.dart';

/// Fluent builder for [TestUser].
final class UserBuilder {
  String? _id;
  String _username = 'test_user';
  String _discriminator = '0';
  bool _bot = false;
  String? _globalName;

  UserBuilder withId(String id) {
    _id = id;
    return this;
  }

  UserBuilder withUsername(String username) {
    _username = username;
    return this;
  }

  UserBuilder withDiscriminator(String discriminator) {
    _discriminator = discriminator;
    return this;
  }

  UserBuilder asBot() {
    _bot = true;
    return this;
  }

  UserBuilder withGlobalName(String name) {
    _globalName = name;
    return this;
  }

  TestUser build() => TestUser(
    id: _id ?? generateId(),
    username: _username,
    discriminator: _discriminator,
    bot: _bot,
    globalName: _globalName,
  );
}

/// Fluent builder for [TestGuild].
final class GuildBuilder {
  String? _id;
  String _name = 'Test Guild';
  String? _ownerId;

  GuildBuilder withId(String id) {
    _id = id;
    return this;
  }

  GuildBuilder withName(String name) {
    _name = name;
    return this;
  }

  GuildBuilder ownedBy(TestUser owner) {
    _ownerId = owner.id;
    return this;
  }

  TestGuild build() => TestGuild(
    id: _id ?? generateId(),
    name: _name,
    ownerId: _ownerId ?? generateId(),
  );
}

/// Fluent builder for [TestRole].
final class RoleBuilder {
  String? _id;
  String _name = 'role';
  String? _guildId;
  int _color = 0;
  int _position = 0;

  RoleBuilder withId(String id) {
    _id = id;
    return this;
  }

  RoleBuilder withName(String name) {
    _name = name;
    return this;
  }

  RoleBuilder ofGuild(TestGuild guild) {
    _guildId = guild.id;
    return this;
  }

  RoleBuilder withColor(int color) {
    _color = color;
    return this;
  }

  RoleBuilder atPosition(int position) {
    _position = position;
    return this;
  }

  TestRole build() {
    final guildId = _guildId;
    if (guildId == null) {
      throw StateError('RoleBuilder requires .ofGuild(...)');
    }
    return TestRole(
      id: _id ?? generateId(),
      name: _name,
      guildId: guildId,
      color: _color,
      position: _position,
    );
  }
}

/// Fluent builder for [TestChannel].
final class ChannelBuilder {
  String? _id;
  String _name = 'test-channel';
  String? _guildId;
  int _type = 0;

  ChannelBuilder withId(String id) {
    _id = id;
    return this;
  }

  ChannelBuilder withName(String name) {
    _name = name;
    return this;
  }

  ChannelBuilder ofGuild(TestGuild guild) {
    _guildId = guild.id;
    return this;
  }

  ChannelBuilder withType(int type) {
    _type = type;
    return this;
  }

  TestChannel build() => TestChannel(
    id: _id ?? generateId(),
    name: _name,
    guildId: _guildId,
    type: _type,
  );
}

/// Fluent builder for [TestMember].
final class MemberBuilder {
  String? _id;
  String? _guildId;
  TestUser? _user;
  final List<TestRole> _roles = [];
  String? _nickname;

  MemberBuilder withId(String id) {
    _id = id;
    return this;
  }

  MemberBuilder ofGuild(TestGuild guild) {
    _guildId = guild.id;
    return this;
  }

  MemberBuilder withUser(TestUser user) {
    _user = user;
    return this;
  }

  MemberBuilder withNickname(String nickname) {
    _nickname = nickname;
    return this;
  }

  MemberBuilder withRole(TestRole role) {
    _roles.add(role);
    return this;
  }

  TestMember build() {
    final guildId = _guildId;
    if (guildId == null) {
      throw StateError('MemberBuilder requires .ofGuild(...)');
    }
    final user = _user ?? UserBuilder().build();
    return TestMember(
      id: _id ?? user.id,
      guildId: guildId,
      user: user,
      roles: List.of(_roles),
      nickname: _nickname,
    );
  }
}
