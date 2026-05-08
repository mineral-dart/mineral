import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/domains/common/utils/attachment.dart';

final class InteractionPart implements InteractionPartContract {
  final DataStoreContract _dataStore;

  InteractionPart(this._dataStore);

  HttpClientStatus get status => _dataStore.client.status;

  @override
  Future<void> replyInteraction(Snowflake id, String token,
      MessageBuilder builder, bool ephemeral) async {
    final (components, files) = makeAttachmentFromBuilder(builder);

    int flags = MessageFlagType.isComponentV2.value;
    if (ephemeral) {
      flags += MessageFlagType.ephemeral.value;
    }

    final req = Request.auto(
      endpoint: '/interactions/$id/$token/callback',
      body: {
        'type': InteractionCallbackType.channelMessageWithSource.value,
        'data': {'flags': flags, 'components': components}
      },
      files: files,
    );

    await _dataStore.requestBucket.query<Map>(req).run(_dataStore.client.post);
  }

  @override
  Future<void> editInteraction(Snowflake id, String token,
      MessageBuilder builder, bool ephemeral) async {
    final (components, files) = makeAttachmentFromBuilder(builder);

    int flags = MessageFlagType.isComponentV2.value;
    if (ephemeral) {
      flags += MessageFlagType.ephemeral.value;
    }

    final req = Request.auto(
      endpoint: '/webhooks/$id/$token/messages/@original',
      body: {'flags': flags, 'components': components},
      files: files,
    );

    await _dataStore.requestBucket
        .query<Map<String, dynamic>>(req)
        .run(_dataStore.client.patch);
  }

  @override
  Future<void> deleteInteraction(Snowflake id, String token) async {
    final req =
        Request.json(endpoint: '/webhooks/$id/$token/messages/@original');
    await _dataStore.requestBucket
        .query<Map<String, dynamic>>(req)
        .run(_dataStore.client.delete);
  }

  @override
  Future<void> noReplyInteraction(
      Snowflake id, String token, bool ephemeral) async {
    final req = Request.json(
      endpoint: '/webhooks/$id/$token/messages/@original',
      body: {
        'type': InteractionCallbackType.deferredUpdateMessage.value,
        'data': {if (ephemeral) 'flags': MessageFlagType.ephemeral.value}
      },
    );

    await _dataStore.requestBucket
        .query<Map<String, dynamic>>(req)
        .run(_dataStore.client.post);
  }

  @override
  Future<void> createFollowup(Snowflake id, String token,
      MessageBuilder builder, bool ephemeral) async {
    final (components, files) = makeAttachmentFromBuilder(builder);

    int flags = MessageFlagType.isComponentV2.value;
    if (ephemeral) {
      flags += MessageFlagType.ephemeral.value;
    }

    final req = Request.auto(
      endpoint: '/webhooks/$id/$token',
      body: {
        'type': InteractionCallbackType.channelMessageWithSource.value,
        'data': {'flags': flags, 'components': components}
      },
      files: files,
    );

    await _dataStore.requestBucket.query<Map>(req).run(_dataStore.client.post);
  }

  @override
  Future<void> editFollowup(Snowflake botId, String token, Snowflake messageId,
      MessageBuilder builder, bool ephemeral) async {
    final (components, files) = makeAttachmentFromBuilder(builder);

    int flags = MessageFlagType.isComponentV2.value;
    if (ephemeral) {
      flags += MessageFlagType.ephemeral.value;
    }

    final req = Request.auto(
      endpoint: '/webhooks/$botId/$token/messages/$messageId',
      body: {'flags': flags, 'components': components},
      files: files,
    );

    await _dataStore.requestBucket.query<Map>(req).run(_dataStore.client.patch);
  }

  @override
  Future<void> waitInteraction(Snowflake id, String token) async {
    final req = Request.json(
      endpoint: '/webhooks/$id/$token',
      body: {
        'type': InteractionCallbackType.deferredUpdateMessage.value,
        'data': {'flags': MessageFlagType.ephemeral.value}
      },
    );

    await _dataStore.requestBucket.query<Map>(req).run(_dataStore.client.post);
  }

  @override
  Future<void> deleteFollowup(
      Snowflake botId, String token, Snowflake messageId) async {
    final req =
        Request.json(endpoint: '/webhooks/$botId/$token/messages/$messageId');
    await _dataStore.requestBucket
        .query<Map<String, dynamic>>(req)
        .run(_dataStore.client.delete);
  }

  @override
  Future<void> sendModal(
    Snowflake id,
    String token,
    ModalBuilder modal,
  ) async {
    final req =
        Request.json(endpoint: '/interactions/$id/$token/callback', body: {
      'type': InteractionCallbackType.modal.value,
      'data': modal.build(),
    });

    await _dataStore.requestBucket
        .query<Map<String, dynamic>>(req)
        .run(_dataStore.client.post);
  }
}
