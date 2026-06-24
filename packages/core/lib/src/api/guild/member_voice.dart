import 'package:mineral/contracts.dart';
import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/api/guild/member.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class MemberVoice {
  final EntityContext _ctx;
  MemberPartContract get _memberMethods => _ctx.datastore.member;

  final Member _member;

  MemberVoice(this._member, {required EntityContext ctx}) : _ctx = ctx;

  /// Move the member to a different voice channel.
  ///
  /// ```dart
  /// await member.voice.move(channelId, reason: 'Testing');
  /// ```
  Future<void> move(Snowflake channelId, {String? reason}) async {
    await _memberMethods.update(
      guildId: _member.guildId.value,
      memberId: _member.id.value,
      payload: {'channel_id': channelId},
      reason: reason,
    );
  }

  /// Disconnect the member from the voice channel.
  ///
  /// ```dart
  /// await member.voice.disconnect(reason: 'Testing');
  /// ```
  Future<void> disconnect({String? reason}) async {
    await _memberMethods.update(
      guildId: _member.guildId.value,
      memberId: _member.id.value,
      payload: {'channel_id': null},
      reason: reason,
    );
  }

  /// Mute the member.
  ///
  /// ```dart
  /// await member.voice.mute(reason: 'Testing');
  /// ```
  Future<void> mute({String? reason}) async {
    await _memberMethods.update(
      guildId: _member.guildId.value,
      memberId: _member.id.value,
      payload: {'mute': true},
      reason: reason,
    );
  }

  /// Unmute the member.
  ///
  /// ```dart
  /// await member.voice.unMute(reason: 'Testing');
  /// ```
  Future<void> unMute({String? reason}) async {
    await _memberMethods.update(
      guildId: _member.guildId.value,
      memberId: _member.id.value,
      payload: {'mute': false},
      reason: reason,
    );
  }

  /// Deafen the member.
  ///
  /// ```dart
  /// await member.voice.deafen(reason: 'Testing');
  /// ```
  Future<void> deafen({String? reason}) async {
    await _memberMethods.update(
      guildId: _member.guildId.value,
      memberId: _member.id.value,
      payload: {'deaf': true},
      reason: reason,
    );
  }

  /// UnDeafen the member.
  ///
  /// ```dart
  /// await member.voice.unDeafen(reason: 'Testing');
  /// ```
  Future<void> unDeafen({String? reason}) async {
    await _memberMethods.update(
      guildId: _member.guildId.value,
      memberId: _member.id.value,
      payload: {'deaf': false},
      reason: reason,
    );
  }
}
