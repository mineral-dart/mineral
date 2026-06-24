import 'package:test/test.dart';

import '../kernel/test_bot.dart';
import '../matchers/matchers.dart';
import '../payloads/builders.dart';
import '../payloads/test_payloads.dart';

/// Fluent DSL entry points for ergonomic command/event/component testing.
extension TestBotDsl on TestBot {
  CommandSimulationBuilder whenCommand(String name) =>
      CommandSimulationBuilder._(this, name);

  ButtonSimulationBuilder whenButton(String customId) =>
      ButtonSimulationBuilder._(this, customId);

  ModalSimulationBuilder whenModalSubmit(String customId) =>
      ModalSimulationBuilder._(this, customId);

  MemberJoinSimulationBuilder whenMemberJoins(TestGuild guild) =>
      MemberJoinSimulationBuilder._(this, guild);
}

final class CommandSimulationBuilder {
  final TestBot _bot;
  final String _name;
  Map<String, Object?> _options = const {};
  TestUser? _user;
  TestGuild? _guild;

  CommandSimulationBuilder._(this._bot, this._name);

  CommandSimulationBuilder withOptions(Map<String, Object?> options) {
    _options = options;
    return this;
  }

  CommandSimulationBuilder invokedBy(TestUser user) {
    _user = user;
    return this;
  }

  // Named to mirror the matcher-style `simulateCommand(in_:)`.
  // ignore: non_constant_identifier_names
  CommandSimulationBuilder in_(TestGuild guild) {
    _guild = guild;
    return this;
  }

  Future<void> dispatch() => _bot.simulateCommand(
    _name,
    options: _options,
    invokedBy: _user ?? UserBuilder().build(),
    in_: _guild,
  );

  Future<void> expectReply({Object? content, bool? ephemeral}) async {
    await dispatch();
    expect(
      _bot.actions.interactionReplies,
      contains(isInteractionReplied(content: content, ephemeral: ephemeral)),
    );
  }

  Future<void> expectModal({Object? customId, Object? title}) async {
    await dispatch();
    expect(
      _bot.actions.modals,
      contains(isModalShown(customId: customId, title: title)),
    );
  }
}

final class ButtonSimulationBuilder {
  final TestBot _bot;
  final String _customId;
  TestUser? _user;
  TestGuild? _guild;

  ButtonSimulationBuilder._(this._bot, this._customId);

  ButtonSimulationBuilder clickedBy(TestUser user) {
    _user = user;
    return this;
  }

  // ignore: non_constant_identifier_names
  ButtonSimulationBuilder in_(TestGuild guild) {
    _guild = guild;
    return this;
  }

  Future<void> dispatch() => _bot.simulateButton(
    _customId,
    clickedBy: _user ?? UserBuilder().build(),
    in_: _guild,
  );

  Future<void> expectModal({Object? customId, Object? title}) async {
    await dispatch();
    expect(
      _bot.actions.modals,
      contains(isModalShown(customId: customId, title: title)),
    );
  }

  Future<void> expectReply({Object? content, bool? ephemeral}) async {
    await dispatch();
    expect(
      _bot.actions.interactionReplies,
      contains(isInteractionReplied(content: content, ephemeral: ephemeral)),
    );
  }
}

final class ModalSimulationBuilder {
  final TestBot _bot;
  final String _customId;
  Map<String, String> _fields = const {};
  TestUser? _user;
  TestGuild? _guild;

  ModalSimulationBuilder._(this._bot, this._customId);

  ModalSimulationBuilder withFields(Map<String, String> fields) {
    _fields = fields;
    return this;
  }

  ModalSimulationBuilder submittedBy(TestUser user) {
    _user = user;
    return this;
  }

  // ignore: non_constant_identifier_names
  ModalSimulationBuilder in_(TestGuild guild) {
    _guild = guild;
    return this;
  }

  Future<void> dispatch() => _bot.simulateModalSubmit(
    _customId,
    fields: _fields,
    submittedBy: _user ?? UserBuilder().build(),
    in_: _guild,
  );

  Future<void> expectReply({Object? content, bool? ephemeral}) async {
    await dispatch();
    expect(
      _bot.actions.interactionReplies,
      contains(isInteractionReplied(content: content, ephemeral: ephemeral)),
    );
  }
}

final class MemberJoinSimulationBuilder {
  final TestBot _bot;
  final TestGuild _guild;
  TestMember? _member;

  MemberJoinSimulationBuilder._(this._bot, this._guild);

  MemberJoinSimulationBuilder forMember(TestMember member) {
    _member = member;
    return this;
  }

  Future<void> dispatch() => _bot.simulateMemberJoin(
    member: _member ?? MemberBuilder().ofGuild(_guild).build(),
    guild: _guild,
  );

  Future<void> expectRoleAssigned({Object? memberId, Object? roleId}) async {
    await dispatch();
    expect(
      _bot.actions.roleAssignments,
      contains(isRoleAssigned(memberId: memberId, roleId: roleId)),
    );
  }
}
