import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class ChannelMethods {
  final EntityContext _ctx;
  DataStoreContract get _datastore => _ctx.datastore;
  final Snowflake? _guildId;

  final Snowflake id;

  ChannelMethods(this._guildId, this.id, {required EntityContext ctx})
    : _ctx = ctx;

  Future<void> setName(String name, String? reason) async {
    final builder = ChannelBuilder(null)..setName(name);
    await _datastore.channel.update(
      id.value,
      builder,
      guildId: _guildId?.value,
      reason: reason,
    );
  }

  Future<void> setDescription(String value, String? reason) async {
    final builder = ChannelBuilder(null)..setTopic(value);
    await _datastore.channel.update(
      id.value,
      builder,
      guildId: _guildId?.value,
      reason: reason,
    );
  }

  Future<void> setCategory(String value, String? reason) async {
    final builder = ChannelBuilder(null)..setParentId(value);
    await _datastore.channel.update(
      id.value,
      builder,
      guildId: _guildId?.value,
      reason: reason,
    );
  }

  Future<void> setPosition(int value, String? reason) async {
    final builder = ChannelBuilder(null)..setPosition(value);
    await _datastore.channel.update(
      id.value,
      builder,
      guildId: _guildId?.value,
      reason: reason,
    );
  }

  Future<void> setNsfw(bool value, String? reason) async {
    final builder = ChannelBuilder(null)..setNsfw(value);
    await _datastore.channel.update(
      id.value,
      builder,
      guildId: _guildId?.value,
      reason: reason,
    );
  }

  Future<void> setRateLimitPerUser(Duration value, String? reason) async {
    final builder = ChannelBuilder(null)..setRateLimitPerUser(value);
    await _datastore.channel.update(
      id.value,
      builder,
      guildId: _guildId?.value,
      reason: reason,
    );
  }

  Future<void> setDefaultAutoArchiveDuration(
    Duration value,
    String? reason,
  ) async {
    final builder = ChannelBuilder(null)..setDefaultAutoArchiveDuration(value);
    await _datastore.channel.update(
      id.value,
      builder,
      guildId: _guildId?.value,
      reason: reason,
    );
  }

  Future<void> setDefaultThreadRateLimitPerUser(
    Duration value,
    String? reason,
  ) async {
    final builder = ChannelBuilder(null)
      ..setDefaultThreadRateLimitPerUser(value);
    await _datastore.channel.update(
      id.value,
      builder,
      guildId: _guildId?.value,
      reason: reason,
    );
  }

  Future<void> setBitrate(int value, String? reason) async {
    final builder = ChannelBuilder(null)..setBitrate(value);
    await _datastore.channel.update(
      id.value,
      builder,
      guildId: _guildId?.value,
      reason: reason,
    );
  }

  Future<void> setUserLimit(int value, String? reason) async {
    final builder = ChannelBuilder(null)..setUserLimit(value);
    await _datastore.channel.update(
      id.value,
      builder,
      guildId: _guildId?.value,
      reason: reason,
    );
  }

  Future<void> setRtcRegion(String value, String? reason) async {
    final builder = ChannelBuilder(null)..setRtcRegion(value);
    await _datastore.channel.update(
      id.value,
      builder,
      guildId: _guildId?.value,
      reason: reason,
    );
  }

  Future<void> setVideoQuality(VideoQuality value, String? reason) async {
    final builder = ChannelBuilder(null)..setVideoQualityMode(value);
    await _datastore.channel.update(
      id.value,
      builder,
      guildId: _guildId?.value,
      reason: reason,
    );
  }

  Future<T> send<T extends Message>({
    required MessageBuilder builder,
    Snowflake? guildId,
  }) async {
    return _datastore.message.send(guildId?.value, id.value, builder);
  }

  Future<T> sendPoll<T extends Message>(Poll poll) async {
    return _datastore.message.sendPoll<T>(id.value, poll);
  }

  Future<void> delete(String? reason) async {
    await _datastore.channel.delete(id.value, reason);
  }
}
