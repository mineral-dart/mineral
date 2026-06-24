import 'dart:async';

import 'package:mineral/src/api/common/color.dart';
import 'package:mineral/src/api/common/embed/message_embed.dart';
import 'package:mineral/src/api/common/embed/message_embed_assets.dart';
import 'package:mineral/src/api/common/embed/message_embed_field.dart';
import 'package:mineral/src/api/common/embed/message_embed_provider.dart';
import 'package:mineral/src/api/common/embed/message_embed_type.dart';
import 'package:mineral/src/domains/common/utils/helper.dart';
import 'package:mineral/src/domains/common/utils/utils.dart';
import 'package:mineral/src/domains/services/marshaller/marshaller.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/types/serializer.dart';

final class EmbedSerializer implements SerializerContract<MessageEmbed> {
  final MarshallerContract _marshaller;

  EmbedSerializer(this._marshaller);

  @override
  Future<Map<String, dynamic>> normalize(Map<String, dynamic> json) async {
    final payload = {
      'title': json['title'],
      'description': json['description'],
      'type': json['type'],
      'url': json['url'],
      'timestamp': json['timestamp'],
      'assets': json['assets'],
      'provider': json['provider'],
      'fields': json['fields'],
      'color': json['color'],
    };

    final cacheKey = _marshaller.cacheKey.embed(json['id'] as String);
    await _marshaller.cache?.put(cacheKey, payload);

    return payload;
  }

  @override
  MessageEmbed serialize(Map<String, dynamic> json) {
    return MessageEmbed(
      title: json['title'] as String?,
      description: json['description'] as String?,
      type: Helper.createOrNull(
        field: json['type'],
        fn: () => findInEnum(
          MessageEmbedType.values,
          json['type'],
          orElse: MessageEmbedType.unknown,
        ),
      ),
      url: json['url'] as String?,
      timestamp: Helper.createOrNull(
        field: json['timestamp'],
        fn: () => DateTime.tryParse(json['timestamp'] as String),
      ),
      assets: Helper.createOrNull(
        field: json['assets'],
        fn: () =>
            MessageEmbedAssets.fromJson(json['assets'] as Map<String, dynamic>),
      ),
      provider: Helper.createOrNull(
        field: json['provider'],
        fn: () => MessageEmbedProvider.fromJson(
          json['provider'] as Map<String, dynamic>,
        ),
      ),
      fields: Helper.createOrNull(
        field: json['fields'],
        fn: () => List.from(json['fields'] as Iterable<dynamic>)
            .map(
              (element) =>
                  MessageEmbedField.fromJson(element as Map<String, dynamic>),
            )
            .toList(),
      ),
      color: Helper.createOrNull(
        field: json['color'],
        fn: () => Color.of(json['color'] as int),
      ),
    );
  }

  @override
  Map<String, dynamic> deserialize(MessageEmbed embed) {
    final assets = embed.assets?.toJson();

    return {
      'title': embed.title,
      'description': embed.description,
      'type': embed.type,
      'url': embed.url,
      'timestamp': embed.timestamp?.toIso8601String(),
      'fields': embed.fields?.map((field) => field.toJson()).toList(),
      'color': embed.color?.toInt(),
      ...?assets,
    };
  }
}
