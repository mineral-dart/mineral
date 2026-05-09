import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/services.dart';
import 'package:mineral/src/infrastructure/internals/datastore/parts/base_part.dart';
import 'package:mineral/src/infrastructure/internals/http/discord_header.dart';

final class InvitePart extends BasePart implements InvitePartContract {
  InvitePart(super.marshaller, super.dataStore);

  @override
  Future<Invite?> get(String code, bool force) async {
    final String key = marshaller.cacheKey.invite(code);

    final cachedInvite = await marshaller.cache?.get(key);
    if (!force && cachedInvite != null) {
      final invite =
          await marshaller.serializers.invite.serialize(cachedInvite);

      return invite;
    }

    final req = Request.json(endpoint: '/invites/$code');
    final result = await dataStore.requestBucket.get<Map<String, dynamic>>(req);

    final raw = await marshaller.serializers.invite.normalize(result);
    final invite = await marshaller.serializers.invite.serialize(raw);

    return invite;
  }

  @override
  Future<InviteMetadata?> getExtrasMetadata(String code, bool force) async {
    final req = Request.json(endpoint: '/invites/$code', queryParameters: {
      'with_counts': 'true',
      'with_expiration': 'true',
    });

    final result = await dataStore.requestBucket.get<Map<String, dynamic>>(req);

    final metadata = InviteMetadata(
      approximateMemberCount: result['approximate_member_count'] as int,
      approximatePresenceCount: result['approximate_presence_count'] as int,
    );

    return metadata;
  }

  @override
  Future<void> delete(String code, String? reason) async {
    final req = Request.json(
        endpoint: '/invites/$code',
        headers: {DiscordHeader.auditLogReason(reason)});

    await dataStore.requestBucket.delete<Map<String, dynamic>>(req);
  }
}
