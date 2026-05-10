import 'package:collection/collection.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/api/common/types/interaction_type.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/domains/components/modal/contexts/private_modal_context.dart';
import 'package:mineral/src/domains/components/modal/contexts/server_modal_context.dart';
import 'package:mineral/src/domains/events/event.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class ModalInteractionCreatePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.interactionCreate;

  final LoggerContract _logger;
  final MarshallerContract _marshaller;
  final DataStoreContract _dataStore;
  final InteractiveComponentManagerContract _interactiveComponentManager;
  final EntityContext _entityContext;

  ModalInteractionCreatePacket({
    required LoggerContract logger,
    required MarshallerContract marshaller,
    required DataStoreContract dataStore,
    required InteractiveComponentManagerContract interactiveComponent,
    required EntityContext entityContext,
  })  : _logger = logger,
        _marshaller = marshaller,
        _dataStore = dataStore,
        _interactiveComponentManager = interactiveComponent,
        _entityContext = entityContext;

  @override
  Future<void> listen(ShardMessage message, DispatchEvent dispatch) async {
    final type = InteractionType.values
        .firstWhereOrNull((e) => e.value == message.payload['type']);

    final payload = message.payload as Map<String, dynamic>;
    if (type == InteractionType.modal) {
      final interactionContext = InteractionContextType.values.firstWhereOrNull(
        (element) => element.value == payload['context'],
      );

      final Map<String, dynamic> parameters = {};
      final data = payload['data'] as Map<String, dynamic>;
      final components = List.from(data['components'] as Iterable<dynamic>);
      final resolved = data['resolved'];
      final guildId = payload['guild_id'] as String?;
      for (final row in components) {
        final rowMap = row as Map<String, dynamic>;
        if (rowMap['component'] == null) {
          continue;
        }
        final component = rowMap['component'] as Map<String, dynamic>;
        final customId = component['custom_id'] as String;

        if (component.containsKey('values')) {
          // Detect type by customId naming convention (user_select, role_select, channel_select)
          final values = List<String>.from(component['values'] as Iterable<dynamic>? ?? []);
          if (customId.contains('user_select')) {
            // Resolve User instances
            if (guildId != null) {
              // Resolve to Members in server context (match native select behavior)
              parameters[customId] = await Future.wait(values
                  .map((id) => _dataStore.member.get(guildId, id, false)));
            } else {
              parameters[customId] = await Future.wait(
                  values.map((id) => _dataStore.user.get(id, false)));
            }
          } else if (customId.contains('role_select')) {
            parameters[customId] = await Future.wait(
              values.map(
                (id) => _dataStore.role.get(guildId!, id, false),
              ),
            );
          } else if (customId.contains('mentionable_select')) {
            final List<dynamic> mentionables = [];
            final resolvedMap = resolved as Map<String, dynamic>?;
            for (final id in values) {
              final isUser = resolvedMap != null &&
                  resolvedMap['users'] != null &&
                  (resolvedMap['users'] as Map<String, dynamic>)[id] != null;
              final isRole = resolvedMap != null &&
                  resolvedMap['roles'] != null &&
                  (resolvedMap['roles'] as Map<String, dynamic>)[id] != null;

              if (isUser) {
                if (guildId != null) {
                  final member =
                      await _dataStore.member.get(guildId, id, false);
                  if (member != null) {
                    mentionables.add(member);
                  }
                } else {
                  final user = await _dataStore.user.get(id, false);
                  if (user != null) {
                    mentionables.add(user);
                  }
                }
              } else if (isRole && guildId != null) {
                final role = await _dataStore.role.get(guildId, id, false);
                if (role != null) {
                  mentionables.add(role);
                }
              }
            }
            parameters[customId] = mentionables;
          } else if (customId.contains('channel_select')) {
            // Resolve Channel instances
            parameters[customId] = await Future.wait(
                values.map((id) => _dataStore.channel.get(id, false)));
          } else {
            // Default: just pass IDs
            parameters[customId] = values;
          }
        } else {
          parameters[customId] = component['value']?.toString() ?? '';
        }
      }

      final event = switch (interactionContext) {
        InteractionContextType.server => Event.serverModalSubmit,
        InteractionContextType.privateChannel => Event.privateModalSubmit,
        _ => null
      };

      final ctx = await switch (interactionContext) {
        InteractionContextType.server =>
          ServerModalContext.fromMap(_dataStore, _entityContext, payload),
        InteractionContextType.privateChannel =>
          PrivateModalContext.fromMap(_marshaller, _entityContext, payload),
        _ => null
      };

      if ([event, ctx].contains(null)) {
        _logger.warn(
            'Interaction context ${message.payload['context']} not found');
        return;
      }

      // dispatch type varies at runtime
      dispatch(
          event: event!,
          payload: (ctx: ctx, data: parameters),
          constraint: (String? customId) => switch (customId) {
                final String value => value == ctx!.customId,
                _ => true
              });

      _interactiveComponentManager.dispatch(ctx!.customId, [ctx, parameters]);
    }
  }
}
