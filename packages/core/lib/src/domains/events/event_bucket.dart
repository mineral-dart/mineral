import 'dart:async';

import 'package:mineral/api.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/common/kernel.dart';
import 'package:mineral/src/domains/events/buckets/guild_bucket.dart';
import 'package:mineral/src/domains/events/buckets/private_bucket.dart';

final class EventBucket {
  final Kernel _kernel;

  late final GuildBucket guild;
  late final PrivateBucket private;

  EventBucket(this._kernel) {
    guild = GuildBucket(this);
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

  void entitlementCreate(
          FutureOr<void> Function(Entitlement entitlement) handle) =>
      _registerEvent(
          event: Event.entitlementCreate,
          handle: (EntitlementCreateArgs p) => handle(p.entitlement));

  void entitlementUpdate(
          FutureOr<void> Function(Entitlement entitlement) handle) =>
      _registerEvent(
          event: Event.entitlementUpdate,
          handle: (EntitlementUpdateArgs p) => handle(p.entitlement));

  void entitlementDelete(
          FutureOr<void> Function(Entitlement entitlement) handle) =>
      _registerEvent(
          event: Event.entitlementDelete,
          handle: (EntitlementDeleteArgs p) => handle(p.entitlement));

  void subscriptionCreate(
          FutureOr<void> Function(Subscription subscription) handle) =>
      _registerEvent(
          event: Event.subscriptionCreate,
          handle: (SubscriptionCreateArgs p) => handle(p.subscription));

  void subscriptionUpdate(
          FutureOr<void> Function(Subscription subscription) handle) =>
      _registerEvent(
          event: Event.subscriptionUpdate,
          handle: (SubscriptionUpdateArgs p) => handle(p.subscription));

  void subscriptionDelete(
          FutureOr<void> Function(Subscription subscription) handle) =>
      _registerEvent(
          event: Event.subscriptionDelete,
          handle: (SubscriptionDeleteArgs p) => handle(p.subscription));

  void _registerEvent<T extends Function>(
          {required Event event, required T handle, String? customId}) =>
      _kernel.eventListener
          .listen(event: event, handle: handle, customId: customId);
}
