import 'dart:async';

import 'package:mineral/api.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/common/kernel.dart';
import 'package:mineral/src/domains/events/buckets/private_bucket.dart';
import 'package:mineral/src/domains/events/buckets/server_bucket.dart';

final class EventBucket {
  final Kernel _kernel;

  late final ServerBucket server;
  late final PrivateBucket private;

  EventBucket(this._kernel) {
    server = ServerBucket(this);
    private = PrivateBucket(this);
  }

  void make<T extends Function>(Event event, T handle, {String? customId}) =>
      _registerEvent<T>(event: event, handle: handle, customId: customId);

  void ready(FutureOr<void> Function(Bot bot) handle) =>
      _registerEvent(event: Event.ready,
          handle: (ReadyArgs p) => handle(p.bot));

  void userUpdate(
          FutureOr<void> Function(User? before, User after) handle) =>
      _registerEvent(event: Event.userUpdate,
          handle: (UserUpdateArgs p) => handle(p.before, p.after));

  void voiceStateUpdate(FutureOr<void> Function(VoiceState state) handle) =>
      _registerEvent(event: Event.voiceStateUpdate,
          handle: (VoiceStateUpdateArgs p) => handle(p.state));

  void voiceConnect(FutureOr<void> Function(VoiceState state) handle) =>
      _registerEvent(event: Event.voiceConnect,
          handle: (VoiceConnectArgs p) => handle(p.state));

  void voiceDisconnect(FutureOr<void> Function(VoiceState state) handle) =>
      _registerEvent(event: Event.voiceDisconnect,
          handle: (VoiceDisconnectArgs p) => handle(p.state));

  void voiceJoin(FutureOr<void> Function(VoiceState state) handle) =>
      _registerEvent(event: Event.voiceJoin,
          handle: (VoiceJoinArgs p) => handle(p.state));

  void voiceLeave(FutureOr<void> Function(VoiceState state) handle) =>
      _registerEvent(event: Event.voiceLeave,
          handle: (VoiceLeaveArgs p) => handle(p.state));

  void voiceMove(
          FutureOr<void> Function(VoiceState? before, VoiceState after)
              handle) =>
      _registerEvent(event: Event.voiceMove,
          handle: (VoiceMoveArgs p) => handle(p.before, p.after));

  void inviteCreate(FutureOr<void> Function(Invite invite) handle) =>
      _registerEvent(event: Event.inviteCreate,
          handle: (InviteCreateArgs p) => handle(p.invite));

  void inviteDelete(
          FutureOr<void> Function(String code, Channel? channel) handle) =>
      _registerEvent(event: Event.inviteDelete,
          handle: (InviteDeleteArgs p) => handle(p.code, p.channel));

  void _registerEvent<T extends Function>(
          {required Event event, required T handle, String? customId}) =>
      _kernel.eventListener
          .listen(event: event, handle: handle, customId: customId);
}
