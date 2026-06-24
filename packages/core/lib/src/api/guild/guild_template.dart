import 'package:mineral/src/api/common/snowflake.dart';

/// A guild template that can be used to create a new guild.
final class GuildTemplate {
  /// The template code (unique identifier).
  final String code;

  /// The name of the template.
  final String name;

  /// The description of the template.
  final String? description;

  /// The number of times this template has been used.
  final int usageCount;

  /// The id of the user who created the template.
  final Snowflake creatorId;

  /// When this template was created.
  final DateTime createdAt;

  /// When this template was last synced to the guild's current state.
  final DateTime updatedAt;

  /// The id of the guild this template is based on.
  final Snowflake sourceGuildId;

  /// The guild snapshot this template contains.
  final Map<String, dynamic> serializedSourceGuild;

  /// Whether the template has unsynced changes.
  final bool? isDirty;

  const GuildTemplate({
    required this.code,
    required this.name,
    required this.usageCount,
    required this.creatorId,
    required this.createdAt,
    required this.updatedAt,
    required this.sourceGuildId,
    required this.serializedSourceGuild,
    this.description,
    this.isDirty,
  });

  factory GuildTemplate.fromJson(Map<String, dynamic> json) {
    return GuildTemplate(
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      usageCount: json['usage_count'] as int,
      creatorId: Snowflake.parse(json['creator_id']),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      sourceGuildId: Snowflake.parse(json['source_guild_id']),
      serializedSourceGuild:
          (json['serialized_source_guild'] as Map<String, dynamic>?) ?? {},
      isDirty: json['is_dirty'] as bool?,
    );
  }
}
