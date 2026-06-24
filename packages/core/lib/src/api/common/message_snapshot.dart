import 'package:mineral/src/api/common/embed/message_embed.dart';
import 'package:mineral/src/domains/services/marshaller/marshaller.dart';
import 'package:mineral/src/infrastructure/internals/marshaller/serializers/embed_serializer.dart';

/// A minimal snapshot of a forwarded message, as provided by Discord in the
/// `message_snapshots` array on a forwarded message payload.
///
/// Only the subset of fields that Discord exposes in a snapshot is surfaced
/// here: [content], [timestamp], [editedTimestamp], [flags], [type], and
/// [embeds].
final class MessageSnapshot {
  final String content;
  final DateTime? timestamp;
  final DateTime? editedTimestamp;
  final int? flags;
  final int? type;
  final List<MessageEmbed> embeds;

  const MessageSnapshot({
    required this.content,
    this.timestamp,
    this.editedTimestamp,
    this.flags,
    this.type,
    this.embeds = const [],
  });

  factory MessageSnapshot.fromJson(
    Map<String, dynamic> json, {
    required MarshallerContract marshaller,
  }) {
    final message = json['message'] as Map<String, dynamic>? ?? {};
    final rawEmbeds = message['embeds'] as List<dynamic>? ?? [];

    final embedSerializer = EmbedSerializer(marshaller);
    final embeds = List<MessageEmbed>.unmodifiable(
      rawEmbeds.map(
        (e) => embedSerializer.serialize(e as Map<String, dynamic>),
      ),
    );

    final rawTimestamp = message['timestamp'] as String?;
    final rawEditedTimestamp = message['edited_timestamp'] as String?;

    return MessageSnapshot(
      content: message['content'] as String? ?? '',
      timestamp: rawTimestamp != null ? DateTime.tryParse(rawTimestamp) : null,
      editedTimestamp: rawEditedTimestamp != null
          ? DateTime.tryParse(rawEditedTimestamp)
          : null,
      flags: message['flags'] as int?,
      type: message['type'] as int?,
      embeds: embeds,
    );
  }
}
