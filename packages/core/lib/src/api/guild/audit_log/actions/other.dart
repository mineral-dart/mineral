import 'package:mineral/api.dart';
import 'package:mineral/src/api/guild/audit_log/audit_log.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class CreatorMonetizationRequestCreatedAuditLog extends AuditLog {
  final String requestId;

  CreatorMonetizationRequestCreatedAuditLog({
    required Snowflake guildId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.requestId,
  }) : super(
         AuditLogType.creatorMonetizationRequestCreated,
         guildId,
         userId,
         ctx: ctx,
       );
}

final class CreatorMonetizationTermsAcceptedAuditLog extends AuditLog {
  final String termsId;

  CreatorMonetizationTermsAcceptedAuditLog({
    required Snowflake guildId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.termsId,
  }) : super(
         AuditLogType.creatorMonetizationTermsAccepted,
         guildId,
         userId,
         ctx: ctx,
       );
}

final class OnboardingPromptCreateAuditLog extends AuditLog {
  final Snowflake promptId;
  final String promptTitle;

  OnboardingPromptCreateAuditLog({
    required Snowflake guildId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.promptId,
    required this.promptTitle,
  }) : super(AuditLogType.onboardingPromptCreate, guildId, userId, ctx: ctx);
}

final class OnboardingPromptUpdateAuditLog extends AuditLog {
  final Snowflake promptId;
  final List<Change> changes;

  OnboardingPromptUpdateAuditLog({
    required Snowflake guildId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.promptId,
    required this.changes,
  }) : super(AuditLogType.onboardingPromptUpdate, guildId, userId, ctx: ctx);
}

final class OnboardingPromptDeleteAuditLog extends AuditLog {
  final Snowflake promptId;
  final String promptTitle;

  OnboardingPromptDeleteAuditLog({
    required Snowflake guildId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.promptId,
    required this.promptTitle,
  }) : super(AuditLogType.onboardingPromptDelete, guildId, userId, ctx: ctx);
}

final class OnboardingCreateAuditLog extends AuditLog {
  final List<Change> changes;

  OnboardingCreateAuditLog({
    required Snowflake guildId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.changes,
  }) : super(AuditLogType.onboardingCreate, guildId, userId, ctx: ctx);
}

final class OnboardingUpdateAuditLog extends AuditLog {
  final List<Change> changes;

  OnboardingUpdateAuditLog({
    required Snowflake guildId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.changes,
  }) : super(AuditLogType.onboardingUpdate, guildId, userId, ctx: ctx);
}

final class HomeSettingsCreateAuditLog extends AuditLog {
  final List<Change> changes;

  HomeSettingsCreateAuditLog({
    required Snowflake guildId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.changes,
  }) : super(AuditLogType.homeSettingsCreate, guildId, userId, ctx: ctx);
}

final class HomeSettingsUpdateAuditLog extends AuditLog {
  final List<Change> changes;

  HomeSettingsUpdateAuditLog({
    required Snowflake guildId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.changes,
  }) : super(AuditLogType.homeSettingsUpdate, guildId, userId, ctx: ctx);
}
