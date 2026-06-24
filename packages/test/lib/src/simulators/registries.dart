import 'dart:async';

import 'package:mineral/container.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';

import '../handlers/listener.dart';
import '../payloads/test_payloads.dart';
import '../recorders/handler_error.dart';

/// Registry of test-friendly listeners, exposed via `bot.events`,
/// `bot.commands`, and `bot.components`.
///
/// The simulator routes synthetic events through this registry rather than
/// the real Mineral dispatchers, which keeps the test framework decoupled
/// from heavyweight `Member`/`Guild` construction.
final class ListenerRegistry {
  final List<OnMemberJoinListener> _onMemberJoin = [];
  final Map<String, OnCommandListener> _onCommand = {};
  final Map<String, OnButtonListener> _onButton = {};
  final Map<String, OnModalSubmitListener> _onModalSubmit = {};

  void register(TestBotListener listener) {
    switch (listener) {
      case final OnMemberJoinListener l:
        _onMemberJoin.add(l);
      case final OnCommandListener l:
        _onCommand[l.command] = l;
      case final OnButtonListener l:
        _onButton[l.customId] = l;
      case final OnModalSubmitListener l:
        _onModalSubmit[l.customId] = l;
    }
  }

  Iterable<OnMemberJoinListener> memberJoinListeners() => _onMemberJoin;

  OnCommandListener? commandFor(String name) => _onCommand[name];

  OnButtonListener? buttonFor(String customId) => _onButton[customId];

  OnModalSubmitListener? modalFor(String customId) => _onModalSubmit[customId];
}

/// Simulator — invokes registered listeners, captures any thrown error as a
/// [HandlerError], and produces synthetic interaction ids/tokens so the
/// recording HTTP client can correlate replies with the originating call.
final class Simulator {
  final ListenerRegistry _registry;
  final List<HandlerError> errors;
  int _idCounter = 1;

  Simulator(this._registry, this.errors);

  String _nextId() => 'test-int-${_idCounter++}';

  Future<void> simulateMemberJoin(TestMember member, TestGuild guild) async {
    for (final listener in _registry.memberJoinListeners()) {
      await _runEvent('guildMemberAdd', () => listener.handle(member, guild));
    }
  }

  Future<void> simulateCommand({
    required String name,
    required Map<String, Object?> options,
    required TestUser invokedBy,
    TestGuild? guild,
  }) async {
    final id = _nextId();
    final invocation = CommandInvocation(
      command: name,
      options: options,
      invokedBy: invokedBy,
      guild: guild,
      interactionId: id,
      token: '$id-token',
    );

    final listener = _registry.commandFor(name);
    if (listener == null) {
      return;
    }

    await _runCommand(name, () => listener.handle(invocation));
  }

  Future<void> simulateButton({
    required String customId,
    required TestUser clickedBy,
    TestGuild? guild,
  }) async {
    final id = _nextId();
    final click = ButtonClick(
      customId: customId,
      clickedBy: clickedBy,
      guild: guild,
      interactionId: id,
      token: '$id-token',
    );

    final listener = _registry.buttonFor(customId);
    if (listener == null) {
      return;
    }

    await _runComponent(customId, () => listener.handle(click));
  }

  Future<void> simulateModalSubmit({
    required String customId,
    required Map<String, String> fields,
    required TestUser submittedBy,
    TestGuild? guild,
  }) async {
    final id = _nextId();
    final submission = ModalSubmission(
      customId: customId,
      fields: fields,
      submittedBy: submittedBy,
      guild: guild,
      interactionId: id,
      token: '$id-token',
    );

    final listener = _registry.modalFor(customId);
    if (listener == null) {
      return;
    }

    await _runComponent(customId, () => listener.handle(submission));
  }

  Future<void> _runEvent(
    String eventName,
    FutureOr<void> Function() body,
  ) async {
    try {
      await body();
    } on Object catch (e, st) {
      errors.add(HandlerError(error: e, stackTrace: st, eventName: eventName));
    }
  }

  Future<void> _runCommand(
    String commandName,
    FutureOr<void> Function() body,
  ) async {
    try {
      await body();
    } on Object catch (e, st) {
      errors.add(
        HandlerError(error: e, stackTrace: st, commandName: commandName),
      );
    }
  }

  Future<void> _runComponent(
    String customId,
    FutureOr<void> Function() body,
  ) async {
    try {
      await body();
    } on Object catch (e, st) {
      errors.add(HandlerError(error: e, stackTrace: st, customId: customId));
    }
  }
}

/// Helper used by example listeners to push synthetic interaction replies and
/// modal opens through the recording HTTP client.
final class TestInteractionResponder {
  TestInteractionResponder._();

  static Future<void> reply({
    required String interactionId,
    required String token,
    required String content,
    bool ephemeral = false,
  }) async {
    final dataStore = ioc.resolve<DataStoreContract>();
    const isComponentV2 = 1 << 15;
    const isEphemeral = 1 << 6;
    final flags = isComponentV2 + (ephemeral ? isEphemeral : 0);
    final body = {
      'type': 4,
      'data': {
        'flags': flags,
        'components': [
          {'type': 10, 'content': content},
        ],
      },
    };
    final req = Request.json(
      endpoint: '/interactions/$interactionId/$token/callback',
      body: body,
    );
    await dataStore.client.post(req);
  }

  static Future<void> showModal({
    required String interactionId,
    required String token,
    required String customId,
    String? title,
  }) async {
    final dataStore = ioc.resolve<DataStoreContract>();
    final body = {
      'type': 9,
      'data': {'custom_id': customId, 'title': title},
    };
    final req = Request.json(
      endpoint: '/interactions/$interactionId/$token/callback',
      body: body,
    );
    await dataStore.client.post(req);
  }
}
