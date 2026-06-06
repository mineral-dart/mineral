import 'package:collection/collection.dart';
import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class ButtonInteractionCreatePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.interactionCreate;

  final LoggerContract _logger;
  final InteractiveComponentManagerContract _interactiveComponentManager;
  final EntityContext _ctx;

  ButtonInteractionCreatePacket({
    required LoggerContract logger,
    required InteractiveComponentManagerContract interactiveComponent,
    required EntityContext ctx,
  })  : _logger = logger,
        _interactiveComponentManager = interactiveComponent,
        _ctx = ctx;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final type = InteractionType.values
        .firstWhereOrNull((e) => e.value == message.payload['type']);

    final componentType = ComponentType.values.firstWhereOrNull(
        (e) => e.value == message.payload['data']['component_type']);

    final payload = message.payload as Map<String, dynamic>;
    if (type == InteractionType.messageComponent &&
        componentType == ComponentType.button) {
      final serverId = Snowflake.nullable((payload['guild'] as Map<String, dynamic>?)?['id'] as String?);

      final type = ComponentType.values.firstWhereOrNull(
          (e) => e.value == (payload['data'] as Map<String, dynamic>)['component_type']);

      if (type == null) {
        _logger.warn(
            'Component type ${(payload['data'] as Map<String, dynamic>)['component_type']} not found');
        return;
      }

      return switch (serverId) {
        String() => _handleServerButton(payload, dispatch),
        _ => _handlePrivateButton(payload, dispatch),
      };
    }
  }

  Future<void> _handleServerButton(
      Map<String, dynamic> payload, DispatchEvent dispatch) async {
    final metadata = payload['message']['interaction_metadata'];
    final targetButton =
        findButtonByCustomId(payload, (payload['data'] as Map<String, dynamic>)['custom_id'] as String);
    final type = ButtonType.values
        .firstWhereOrNull((e) => e.value == targetButton?['type']);

    if (type == null) {
      _logger.warn('Button type ${(metadata as Map<String, dynamic>)['type']} not found');
      return;
    }

    final ctx = ServerButtonContext(
      ctx: _ctx,
      id: Snowflake.parse(payload['id']),
      applicationId: Snowflake.parse(payload['application_id']),
      version: payload['version'] as int,
      token: payload['token'] as String,
      customId: (payload['data'] as Map<String, dynamic>)['custom_id'] as String,
      channelId: Snowflake.parse((payload['message'] as Map<String, dynamic>)['channel_id']),
      messageId: Snowflake.parse((payload['message'] as Map<String, dynamic>)['id']),
    );

    dispatch<ServerButtonClickArgs>(
        event: Event.serverButtonClick,
        payload: (ctx: ctx),
        constraint: (String? customId) => customId == ctx.customId);

    _interactiveComponentManager.dispatch(ctx.customId, [ctx]);
  }

  Future<void> _handlePrivateButton(
      Map<String, dynamic> payload, DispatchEvent dispatch) async {
    final metadata = payload['message']['interaction_metadata'];
    final targetButton =
        findButtonByCustomId(payload, (payload['data'] as Map<String, dynamic>)['custom_id'] as String);
    final type = ButtonType.values
        .firstWhereOrNull((e) => e.value == targetButton?['custom_id']);

    if (type == null) {
      _logger.warn('Button type ${(metadata as Map<String, dynamic>)['type']} not found');
      return;
    }

    final ctx = PrivateButtonContext(
      ctx: _ctx,
      id: Snowflake.parse(payload['id']),
      applicationId: Snowflake.parse(payload['application_id']),
      version: payload['version'] as int,
      token: payload['token'] as String,
      customId: (payload['data'] as Map<String, dynamic>)['custom_id'] as String,
      authorId: Snowflake.parse(((payload['member'] as Map<String, dynamic>)['user'] as Map<String, dynamic>)['id']),
      channelId: Snowflake.parse(payload['channel_id']),
      messageId: Snowflake.parse((payload['message'] as Map<String, dynamic>)['id']),
    );

    dispatch<PrivateButtonClickArgs>(
        event: Event.privateButtonClick,
        payload: (ctx: ctx),
        constraint: (String? customId) => customId == ctx.customId);
  }

  Map<String, dynamic>? findButtonByCustomId(
      Map<String, dynamic> payload, String customId) {
    final components = payload['message']['components'] as List<dynamic>?;
    if (components == null) {
      return null;
    }

    for (final component in components) {
      final subComponents = component['components'] as List<dynamic>?;
      if (subComponents == null) {
        continue;
      }
      for (final subComponent in subComponents) {
        if (subComponent['custom_id'] == customId) {
          return subComponent as Map<String, dynamic>;
        }
      }
    }
    return null;
  }
}
