import 'dart:async';

import 'package:mineral/api.dart';
import 'package:mineral/src/domains/events/event.dart';
import 'package:mineral/src/domains/events/types/base_listenable_event.dart';

typedef UserUpdateArgs = ({User? before, User after});

abstract class UserUpdateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.userUpdate;

  @override
  Function get handler => (UserUpdateArgs p) => handle(p.before, p.after);

  FutureOr<void> handle(User? before, User after);
}

typedef InviteCreateArgs = ({Invite invite});

abstract class InviteCreateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.inviteCreate;

  @override
  Function get handler => (InviteCreateArgs p) => handle(p.invite);
  FutureOr<void> handle(Invite invite);
}

typedef InviteDeleteArgs = ({String code, Channel? channel});

abstract class InviteDeleteEvent extends BaseListenableEvent {
  @override
  Event get event => Event.inviteDelete;

  @override
  Function get handler => (InviteDeleteArgs p) => handle(p.code, p.channel);

  FutureOr<void> handle(String code, Channel? channel);
}

typedef ReadyArgs = ({Bot bot});

abstract class ReadyEvent extends BaseListenableEvent {
  @override
  Event get event => Event.ready;

  @override
  Function get handler => (ReadyArgs p) => handle(p.bot);

  FutureOr<void> handle(Bot bot);
}

typedef TypingArgs = ({Typing typing});

abstract class TypingEvent extends BaseListenableEvent {
  @override
  Event get event => Event.typing;

  @override
  Function get handler => (TypingArgs p) => handle(p.typing);

  FutureOr<void> handle(Typing typing);
}

typedef VoiceConnectArgs = ({VoiceState state});

abstract class VoiceConnectEvent extends BaseListenableEvent {
  @override
  Event get event => Event.voiceConnect;

  @override
  Function get handler => (VoiceConnectArgs p) => handle(p.state);

  FutureOr<void> handle(VoiceState state);
}

typedef VoiceDisconnectArgs = ({VoiceState state});

abstract class VoiceDisconnectEvent extends BaseListenableEvent {
  @override
  Event get event => Event.voiceDisconnect;

  @override
  Function get handler => (VoiceDisconnectArgs p) => handle(p.state);

  FutureOr<void> handle(VoiceState state);
}

typedef VoiceJoinArgs = ({VoiceState state});

abstract class VoiceJoinEvent extends BaseListenableEvent {
  @override
  Event get event => Event.voiceJoin;

  @override
  Function get handler => (VoiceJoinArgs p) => handle(p.state);

  FutureOr<void> handle(VoiceState state);
}

typedef VoiceLeaveArgs = ({VoiceState state});

abstract class VoiceLeaveEvent extends BaseListenableEvent {
  @override
  Event get event => Event.voiceLeave;

  @override
  Function get handler => (VoiceLeaveArgs p) => handle(p.state);

  FutureOr<void> handle(VoiceState state);
}

typedef VoiceMoveArgs = ({VoiceState? before, VoiceState after});

abstract class VoiceMoveEvent extends BaseListenableEvent {
  @override
  Event get event => Event.voiceMove;

  @override
  Function get handler => (VoiceMoveArgs p) => handle(p.before, p.after);

  FutureOr<void> handle(VoiceState? before, VoiceState after);
}

typedef VoiceStateUpdateArgs = ({VoiceState state});

abstract class VoiceStateUpdateEvent extends BaseListenableEvent {
  @override
  Event get event => Event.voiceStateUpdate;

  @override
  Function get handler => (VoiceStateUpdateArgs p) => handle(p.state);

  FutureOr<void> handle(VoiceState state);
}
