import 'package:mineral/src/api/common/types/enhanced_enum.dart';

enum Permission implements EnhancedEnum<int> {
  createInstantInvite(1 << 0),
  kickMembers(1 << 1),
  banMembers(1 << 2),
  administrator(1 << 3),
  manageChannels(1 << 4),
  manageGuilds(1 << 5),
  addReactions(1 << 6),
  viewAuditChannel(1 << 7),
  prioritySpeaker(1 << 8),
  stream(1 << 9),
  viewChannel(1 << 10),
  sendMessages(1 << 11),
  sendTtsMessage(1 << 12),
  manageMessages(1 << 13),
  embedLinks(1 << 14),
  attachFiles(1 << 15),
  readMessageHistory(1 << 16),
  mentionEveryone(1 << 17),
  useExternalEmojis(1 << 18),
  viewGuildInsights(1 << 19),
  connect(1 << 20),
  speak(1 << 21),
  muteMembers(1 << 22),
  deafenMembers(1 << 23),
  moveMembers(1 << 24),
  useVad(1 << 25),
  changeUsername(1 << 26),
  managerUsernames(1 << 27),
  manageRoles(1 << 28),
  manageWebhooks(1 << 29),
  manageEmojisAndStickers(1 << 30),
  useApplicationCommand(1 << 31),
  requestToSpeak(1 << 32),
  manageEvents(1 << 33),
  manageThreads(1 << 34),
  // `usePublicThreads`/`usePrivateThreads` (Discord's original names for
  // these bits) were dropped rather than kept as aliases: two enum members
  // sharing a bit made `bitfieldToList`/`Permissions.fromInt` return both
  // for a single set bit, which corrupted the count going into a raw
  // bitfield (see issue #471, A10). `createPublicThreads`/
  // `createPrivateThreads` are Discord's current names and are kept as the
  // sole members for these bits.
  createPublicThreads(1 << 35),
  createPrivateThreads(1 << 36),
  useExternalStickers(1 << 37),
  sendMessageInThreads(1 << 38),
  startEmbeddedActivities(1 << 39),
  moderateMembers(1 << 40),
  unknown(-1);

  @override
  final int value;

  const Permission(this.value);
}
