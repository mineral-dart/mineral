import 'package:mineral/contracts.dart';
import 'package:mineral/src/api/common/snowflake.dart';
import 'package:mineral/src/api/private/user.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/components/component_context_base.dart';
import 'package:mineral/src/domains/components/modal/modal_context.dart';

final class PrivateModalContext extends ComponentContextBase
    implements ModalContext {
  final User user;

  PrivateModalContext({
    required super.id,
    required super.applicationId,
    required super.token,
    required super.version,
    required super.customId,
    required super.ctx,
    required this.user,
  });

  static Future<PrivateModalContext> fromMap(
    MarshallerContract marshaller,
    EntityContext ctx,
    Map<String, dynamic> payload,
  ) async {
    final data = payload['data'] as Map<String, dynamic>;
    return PrivateModalContext(
      ctx: ctx,
      customId: data['custom_id'] as String,
      id: Snowflake.parse(payload['id']),
      applicationId: Snowflake.parse(payload['application_id']),
      token: payload['token'] as String,
      version: payload['version'] as int,
      user: await marshaller.serializers.user.serialize(
        payload['user'] as Map<String, dynamic>,
      ),
    );
  }
}
