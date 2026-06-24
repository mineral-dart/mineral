import 'package:mineral/contracts.dart';
import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/api/guild/member.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/components/component_context_base.dart';
import 'package:mineral/src/domains/components/modal/modal_context.dart';

final class GuildModalContext extends ComponentContextBase
    implements ModalContext {
  final Member member;

  GuildModalContext({
    required super.id,
    required super.applicationId,
    required super.token,
    required super.version,
    required super.customId,
    required super.ctx,
    required this.member,
  });

  static Future<GuildModalContext> fromMap(DataStoreContract datastore,
      EntityContext ctx, Map<String, dynamic> payload) async {
    final data = payload['data'] as Map<String, dynamic>;
    final memberMap = payload['member'] as Map<String, dynamic>;
    final memberUser = memberMap['user'] as Map<String, dynamic>;
    return GuildModalContext(
      ctx: ctx,
      customId: data['custom_id'] as String,
      id: Snowflake.parse(payload['id']),
      applicationId: Snowflake.parse(payload['application_id']),
      token: payload['token'] as String,
      version: payload['version'] as int,
      member: (await datastore.member.get(
        payload['guild_id'] as String,
        memberUser['id'] as String,
        false,
      ))!,
    );
  }
}
