import 'package:mineral/src/api/common/channel.dart';
import 'package:mineral/src/api/common/embed/message_embed.dart';
import 'package:mineral/src/api/common/message_snapshot.dart';
import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/api/common/types/message_reference_type.dart';
import 'package:mineral/src/domains/common/utils/helper.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/types/serializer.dart';

final class MessageProperties<T extends Channel> {
  final Snowflake id;
  final String content;
  final Snowflake channelId;
  final Snowflake? authorId;
  final Snowflake? guildId;
  final bool authorIsBot;
  final List<MessageEmbed> embeds;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final MessageReferenceType? referenceType;
  final List<MessageSnapshot> snapshots;

  MessageProperties({
    required this.id,
    required this.content,
    required this.channelId,
    required this.authorId,
    required this.guildId,
    required this.authorIsBot,
    required this.embeds,
    required this.createdAt,
    required this.updatedAt,
    this.referenceType,
    this.snapshots = const [],
  });

  factory MessageProperties.fromJson(
    Map<String, dynamic> json, {
    required SerializerContract<MessageEmbed> embedSerializer,
    List<MessageSnapshot> snapshots = const [],
    MessageReferenceType? referenceType,
  }) {
    final embeds = List<MessageEmbed>.unmodifiable(
      (json['embeds'] as Iterable<dynamic>).map(
        (element) =>
            embedSerializer.serialize(element as Map<String, dynamic>)
                as MessageEmbed,
      ),
    );

    return MessageProperties(
      id: Snowflake.parse(json['id']),
      content: json['content'] as String,
      channelId: Snowflake.parse(json['channel_id']),
      authorId: Snowflake.nullable(json['author_id']),
      guildId: Snowflake.nullable(json['guild_id']),
      authorIsBot: json['author_is_bot'] as bool? ?? false,
      embeds: embeds,
      createdAt: DateTime.parse(json['timestamp'] as String),
      updatedAt: Helper.createOrNull(
        field: json['edited_timestamp'],
        fn: () => DateTime.parse(json['edited_timestamp'] as String),
      ),
      referenceType: referenceType,
      snapshots: snapshots,
    );
  }
}
