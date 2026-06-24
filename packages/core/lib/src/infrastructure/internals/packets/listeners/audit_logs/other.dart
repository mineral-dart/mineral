import 'package:mineral/api.dart';
import 'package:mineral/src/api/guild/audit_log/actions/other.dart';
import 'package:mineral/src/api/guild/audit_log/audit_log.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

Future<AuditLog> creatorMonetizationRequestCreatedAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return CreatorMonetizationRequestCreatedAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    requestId: json['target_id'] as String,
    ctx: ctx,
  );
}

Future<AuditLog> creatorMonetizationTermsAcceptedAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return CreatorMonetizationTermsAcceptedAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    termsId: json['target_id'] as String,
    ctx: ctx,
  );
}

Future<AuditLog> onboardingPromptCreateAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return OnboardingPromptCreateAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    promptId: Snowflake.parse(json['target_id']),
    promptTitle: ((json['changes'] as List<dynamic>)[0] as Map<String, dynamic>)['new_value'] as String,
    ctx: ctx,
  );
}

Future<AuditLog> onboardingPromptUpdateAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return OnboardingPromptUpdateAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    promptId: Snowflake.parse(json['target_id']),
    changes: List<Map<String, dynamic>>.from(json['changes'] as Iterable<dynamic>)
        .map(Change.fromJson)
        .toList(),
    ctx: ctx,
  );
}

Future<AuditLog> onboardingPromptDeleteAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return OnboardingPromptDeleteAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    promptId: Snowflake.parse(json['target_id']),
    promptTitle: ((json['changes'] as List<dynamic>)[0] as Map<String, dynamic>)['old_value'] as String,
    ctx: ctx,
  );
}

Future<AuditLog> onboardingCreateAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return OnboardingCreateAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    changes: List<Map<String, dynamic>>.from(json['changes'] as Iterable<dynamic>)
        .map(Change.fromJson)
        .toList(),
    ctx: ctx,
  );
}

Future<AuditLog> onboardingUpdateAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return OnboardingUpdateAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    changes: List<Map<String, dynamic>>.from(json['changes'] as Iterable<dynamic>)
        .map(Change.fromJson)
        .toList(),
    ctx: ctx,
  );
}

Future<AuditLog> homeSettingsCreateAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return HomeSettingsCreateAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    changes: List<Map<String, dynamic>>.from(json['changes'] as Iterable<dynamic>)
        .map(Change.fromJson)
        .toList(),
    ctx: ctx,
  );
}

Future<AuditLog> homeSettingsUpdateAuditLogHandler(
    Map<String, dynamic> json, EntityContext ctx) async {
  return HomeSettingsUpdateAuditLog(
    guildId: Snowflake.parse(json['guild_id']),
    userId: Snowflake.parse(json['user_id']),
    changes: List<Map<String, dynamic>>.from(json['changes'] as Iterable<dynamic>)
        .map(Change.fromJson)
        .toList(),
    ctx: ctx,
  );
}
