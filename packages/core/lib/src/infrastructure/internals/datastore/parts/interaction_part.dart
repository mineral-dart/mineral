import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/domains/common/utils/attachment.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/base_part.dart';

final class InteractionPart extends BasePart
    implements InteractionPartContract {
  InteractionPart(super.marshaller, super.dataStore);

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

    await dataStore.requestBucket.post<Map>(req);
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

    await dataStore.requestBucket.patch<Map<String, dynamic>>(req);
  }

  @override
  Future<void> deleteInteraction(Snowflake id, String token) async {
    final req =
        Request.json(endpoint: '/webhooks/$id/$token/messages/@original');
    await dataStore.requestBucket.delete<Map<String, dynamic>>(req);
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

    await dataStore.requestBucket.post<Map<String, dynamic>>(req);
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

    await dataStore.requestBucket.post<Map>(req);
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

    await dataStore.requestBucket.patch<Map>(req);
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

    await dataStore.requestBucket.post<Map>(req);
  }

  @override
  Future<void> deleteFollowup(
      Snowflake botId, String token, Snowflake messageId) async {
    final req =
        Request.json(endpoint: '/webhooks/$botId/$token/messages/$messageId');
    await dataStore.requestBucket.delete<Map<String, dynamic>>(req);
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

    await dataStore.requestBucket.post<Map<String, dynamic>>(req);
  }

  @override
  Future<void> sendAutocompleteResult(
    Snowflake id,
    String token,
    List<Choice> choices,
  ) async {
    final req =
        Request.json(endpoint: '/interactions/$id/$token/callback', body: {
      'type': InteractionCallbackType.applicationCommandAutocompleteResult.value,
      'data': {
        'choices': choices
            .map((c) => {'name': c.name, 'value': c.value})
            .toList(),
      },
    });

    await dataStore.requestBucket.post<Map<String, dynamic>>(req);
  }
}
