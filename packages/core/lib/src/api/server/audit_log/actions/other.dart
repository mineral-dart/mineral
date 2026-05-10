import 'package:mineral/api.dart';
import 'package:mineral/src/api/server/audit_log/audit_log.dart';
import 'package:mineral/src/domains/common/entity_context.dart';

final class CreatorMonetizationRequestCreatedAuditLog extends AuditLog {
  final String requestId;

  CreatorMonetizationRequestCreatedAuditLog({
    required Snowflake serverId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.requestId,
  }) : super(AuditLogType.creatorMonetizationRequestCreated, serverId, userId,
            ctx: ctx);
}

final class CreatorMonetizationTermsAcceptedAuditLog extends AuditLog {
  final String termsId;

  CreatorMonetizationTermsAcceptedAuditLog({
    required Snowflake serverId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.termsId,
  }) : super(AuditLogType.creatorMonetizationTermsAccepted, serverId, userId,
            ctx: ctx);
}

final class OnboardingPromptCreateAuditLog extends AuditLog {
  final Snowflake promptId;
  final String promptTitle;

  OnboardingPromptCreateAuditLog({
    required Snowflake serverId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.promptId,
    required this.promptTitle,
  }) : super(AuditLogType.onboardingPromptCreate, serverId, userId, ctx: ctx);
}

final class OnboardingPromptUpdateAuditLog extends AuditLog {
  final Snowflake promptId;
  final List<Change> changes;

  OnboardingPromptUpdateAuditLog({
    required Snowflake serverId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.promptId,
    required this.changes,
  }) : super(AuditLogType.onboardingPromptUpdate, serverId, userId, ctx: ctx);
}

final class OnboardingPromptDeleteAuditLog extends AuditLog {
  final Snowflake promptId;
  final String promptTitle;

  OnboardingPromptDeleteAuditLog({
    required Snowflake serverId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.promptId,
    required this.promptTitle,
  }) : super(AuditLogType.onboardingPromptDelete, serverId, userId, ctx: ctx);
}

final class OnboardingCreateAuditLog extends AuditLog {
  final List<Change> changes;

  OnboardingCreateAuditLog({
    required Snowflake serverId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.changes,
  }) : super(AuditLogType.onboardingCreate, serverId, userId, ctx: ctx);
}

final class OnboardingUpdateAuditLog extends AuditLog {
  final List<Change> changes;

  OnboardingUpdateAuditLog({
    required Snowflake serverId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.changes,
  }) : super(AuditLogType.onboardingUpdate, serverId, userId, ctx: ctx);
}

final class HomeSettingsCreateAuditLog extends AuditLog {
  final List<Change> changes;

  HomeSettingsCreateAuditLog({
    required Snowflake serverId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.changes,
  }) : super(AuditLogType.homeSettingsCreate, serverId, userId, ctx: ctx);
}

final class HomeSettingsUpdateAuditLog extends AuditLog {
  final List<Change> changes;

  HomeSettingsUpdateAuditLog({
    required Snowflake serverId,
    required Snowflake userId,
    required EntityContext ctx,
    required this.changes,
  }) : super(AuditLogType.homeSettingsUpdate, serverId, userId, ctx: ctx);
}
