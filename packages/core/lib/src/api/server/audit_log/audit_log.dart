import 'package:mineral/api.dart';
import 'package:mineral/container.dart';
import 'package:mineral/contracts.dart';

abstract class AuditLog {
  // TODO(phase1.3-polish): migrate audit log entities + their action subclasses
  // to take EntityContext via constructor. Pending because each handler in
  // packets/listeners/audit_logs/* would need to thread ctx through, and many
  // subclasses have non-trivial constructor surfaces. Tracked separately.
  DataStoreContract get _datastore => ioc.resolve<DataStoreContract>();

  AuditLogType type;
  Snowflake serverId;
  Snowflake? userId;

  AuditLog(this.type, this.serverId, this.userId);

  Future<Server> resolveServer({bool force = false}) {
    return _datastore.server.get(serverId.value, force);
  }
}

final class Change<B, A> {
  final String key;
  final B before;
  final A? after;

  Change(this.key, this.before, this.after);

  factory Change.fromJson(Map<String, dynamic> json) {
    return Change(json['key'] as String, json['old_value'] as B, json['new_value'] as A?);
  }
}

enum AuditLogType implements EnhancedEnum<int> {
  unknown(-1),
  guildUpdate(1),
  channelCreate(10),
  channelUpdate(11),
  channelDelete(12),
  channelOverwriteCreate(13),
  channelOverwriteUpdate(14),
  channelOverwriteDelete(15),
  memberKick(20),
  memberPrune(21),
  memberBanAdd(22),
  memberBanRemove(23),
  memberUpdate(24),
  memberRoleUpdate(25),
  memberMove(26),
  memberDisconnect(27),
  botAdd(28),
  roleCreate(30),
  roleUpdate(31),
  roleDelete(32),
  inviteCreate(40),
  inviteUpdate(41),
  inviteDelete(42),
  webhookCreate(50),
  webhookUpdate(51),
  webhookDelete(52),
  emojiCreate(60),
  emojiUpdate(61),
  emojiDelete(62),
  messageDelete(72),
  messageBulkDelete(73),
  messagePin(74),
  messageUnpin(75),
  integrationCreate(80),
  integrationUpdate(81),
  integrationDelete(82),
  stageInstanceCreate(83),
  stageInstanceUpdate(84),
  stageInstanceDelete(85),
  stickerCreate(90),
  stickerUpdate(91),
  stickerDelete(92),
  guildScheduledEventCreate(100),
  guildScheduledEventUpdate(101),
  guildScheduledEventDelete(102),
  threadCreate(110),
  threadUpdate(111),
  threadDelete(112),
  applicationCommandPermissionUpdate(121),
  autoModerationRuleCreate(140),
  autoModerationRuleUpdate(141),
  autoModerationRuleDelete(142),
  autoModerationBlockMessage(143),
  autoModerationFlagToChannel(144),
  autoModerationUserCommunicationDisabled(145),
  creatorMonetizationRequestCreated(150),
  creatorMonetizationTermsAccepted(151),
  onboardingPromptCreate(163),
  onboardingPromptUpdate(164),
  onboardingPromptDelete(165),
  onboardingCreate(166),
  onboardingUpdate(167),
  homeSettingsCreate(190),
  homeSettingsUpdate(191);

  @override
  final int value;

  const AuditLogType(this.value);
}
