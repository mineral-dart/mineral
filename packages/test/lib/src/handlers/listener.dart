import 'dart:async';

import '../payloads/test_payloads.dart';

/// Marker interface for test-friendly bot listeners.
///
/// Real Mineral listeners extend `ListenableEvent` and receive fully
/// constructed domain types (`Member`, `Guild`, ...). Materializing those
/// types in a test requires every Discord field — overkill for unit-style
/// tests of bot behaviour.
///
/// This package provides lightweight equivalents (see [TestBotListener]
/// subclasses) that accept the test payloads ([TestMember], [TestGuild], ...)
/// directly. Behaviour that depends on the [DataStoreContract]
/// (sending messages, banning members, assigning roles) goes through the
/// IoC-resolved data store, so the recording HTTP client still observes it.
abstract interface class TestBotListener {
  String get name;
}

/// Listener invoked when a member joins a guild.
abstract class OnMemberJoinListener implements TestBotListener {
  @override
  String get name => 'guildMemberAdd';

  FutureOr<void> handle(TestMember member, TestGuild guild);
}

/// Listener invoked when a slash command (or sub-command path) is dispatched.
abstract class OnCommandListener implements TestBotListener {
  /// Command path, e.g. `'ping'` or `'mod.ban'`.
  String get command;

  @override
  String get name => 'command:$command';

  FutureOr<void> handle(CommandInvocation invocation);
}

/// Listener invoked when a button matching [customId] is clicked.
abstract class OnButtonListener implements TestBotListener {
  String get customId;

  @override
  String get name => 'button:$customId';

  FutureOr<void> handle(ButtonClick click);
}

/// Listener invoked when a modal matching [customId] is submitted.
abstract class OnModalSubmitListener implements TestBotListener {
  String get customId;

  @override
  String get name => 'modal:$customId';

  FutureOr<void> handle(ModalSubmission submission);
}

/// Test-friendly view of a slash command invocation.
final class CommandInvocation {
  final String command;
  final Map<String, Object?> options;
  final TestUser invokedBy;
  final TestGuild? guild;

  /// Synthetic interaction id — useful for asserting that replies are tied
  /// to this invocation.
  final String interactionId;

  /// Synthetic interaction token used by replies.
  final String token;

  const CommandInvocation({
    required this.command,
    required this.options,
    required this.invokedBy,
    required this.guild,
    required this.interactionId,
    required this.token,
  });
}

/// Test-friendly view of a button click.
final class ButtonClick {
  final String customId;
  final TestUser clickedBy;
  final TestGuild? guild;
  final String interactionId;
  final String token;

  const ButtonClick({
    required this.customId,
    required this.clickedBy,
    required this.guild,
    required this.interactionId,
    required this.token,
  });
}

/// Test-friendly view of a modal submission.
final class ModalSubmission {
  final String customId;
  final Map<String, String> fields;
  final TestUser submittedBy;
  final TestGuild? guild;
  final String interactionId;
  final String token;

  const ModalSubmission({
    required this.customId,
    required this.fields,
    required this.submittedBy,
    required this.guild,
    required this.interactionId,
    required this.token,
  });
}
