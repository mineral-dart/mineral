import 'package:collection/collection.dart';
import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/common/entity_context.dart';
import 'package:mineral/src/infrastructure/internals/packets/listenable_packet.dart';
import 'package:mineral/src/infrastructure/internals/packets/packet_type.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';

final class SelectInteractionCreatePacket implements ListenablePacket {
  @override
  PacketType get packetType => PacketType.interactionCreate;

  final LoggerContract _logger;
  final MarshallerContract _marshaller;
  final DataStoreContract _dataStore;
  final InteractiveComponentManagerContract _interactiveComponentManager;
  final EntityContext _entityContext;

  SelectInteractionCreatePacket({
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
    final payload = message.payload as Map<String, dynamic>;
    final data = payload['data'] as Map<String, dynamic>;
    final type = InteractionType.values
        .firstWhereOrNull((e) => e.value == payload['type']);

    final componentType = ComponentType.values
        .firstWhereOrNull((e) => e.value == data['component_type']);

    if (type == InteractionType.messageComponent &&
        ComponentType.selectMenus.contains(componentType)) {
      final selectMenuType = ComponentType.values
          .firstWhereOrNull((e) => e.value == data['component_type']);

      final guildId = Snowflake.nullable(payload['guild_id'] as String?);
      final SelectContext ctx = await switch (guildId) {
        String() => GuildSelectContext.fromMap(
                _dataStore, _entityContext, payload)
            as Future<SelectContext>,
        _ => PrivateSelectContext.fromMap(
                _marshaller, _dataStore, _entityContext, payload)
            as Future<SelectContext>,
      };

      switch (selectMenuType) {
        case ComponentType.channelSelectMenu:
          await _dispatchChannelSelectMenu(ctx, payload, dispatch);
        case ComponentType.roleSelectMenu:
          await _dispatchRoleSelectMenu(ctx, payload, dispatch);
        case ComponentType.userSelectMenu:
          await _dispatchUserSelectMenu(ctx, payload, dispatch);
        case ComponentType.mentionableSelectMenu:
          await _dispatchMentionableSelectMenu(ctx, payload, dispatch);
        case ComponentType.textSelectMenu:
          await _dispatchTextSelectMenu(ctx, payload, dispatch);
        default:
          _logger.warn('Select menu type $selectMenuType not found');
      }
    }
  }

  Future<void> _dispatchChannelSelectMenu(SelectContext ctx,
      Map<String, dynamic> payload, DispatchEvent dispatch) async {
    final guildChannels =
        await _dataStore.channel.fetch(payload['guild_id'] as String, false);

    final data = payload['data'] as Map<String, dynamic>;
    final resolvedData = data['resolved'] as Map<String, dynamic>;
    final channelIds =
        Map.from(resolvedData['channels'] as Map<dynamic, dynamic>).keys;

    final channels =
        channelIds.map((id) => guildChannels[id]).whereType<GuildChannel>();

    _interactiveComponentManager.dispatch(ctx.customId, [ctx, channels]);

    return switch (ctx) {
      GuildSelectContext() => dispatch<GuildChannelSelectArgs>(
          event: Event.guildChannelSelect,
          payload: (
            ctx: ctx,
            channels: channels.whereType<GuildChannel>().toList()
          ),
          constraint: (String? customId) => customId == ctx.customId),
      PrivateSelectContext() => null,
      _ => _logger.warn('Select context $ctx not found'),
    };
  }

  Future<void> _dispatchRoleSelectMenu(SelectContext ctx,
      Map<String, dynamic> payload, DispatchEvent dispatch) async {
    final guildRoles =
        await _dataStore.role.fetch(payload['guild_id'] as String, false);

    final data = payload['data'] as Map<String, dynamic>;
    final resolvedData = data['resolved'] as Map<String, dynamic>;
    final roleIds =
        Map.from(resolvedData['roles'] as Map<dynamic, dynamic>).keys;

    final resolvedRoles = roleIds.map((id) => guildRoles[id]);

    dispatch<GuildRoleSelectArgs>(
        event: Event.guildRoleSelect,
        payload: (
          ctx: ctx as GuildSelectContext,
          roles: resolvedRoles.whereType<Role>().toList()
        ),
        constraint: (String? customId) => customId == ctx.customId);

    _interactiveComponentManager.dispatch(ctx.customId, [ctx, resolvedRoles]);
  }

  Future<void> _dispatchUserSelectMenu(SelectContext ctx,
      Map<String, dynamic> payload, DispatchEvent dispatch) async {
    final data = payload['data'] as Map<String, dynamic>;
    final resolvedData = data['resolved'] as Map<String, dynamic>;
    final userIds =
        Map.from(resolvedData['users'] as Map<dynamic, dynamic>).keys;

    final event = switch (ctx) {
      GuildSelectContext() => Event.guildMemberSelect,
      PrivateSelectContext() => Event.privateUserSelect,
      _ => null,
    };

    if (event == null) {
      _logger.warn('Select context $ctx not found');
      return;
    }

    final resolvedResource = await switch (ctx) {
      GuildSelectContext() => Future.wait(userIds.map((id) {
          return _dataStore.member
              .get(payload['guild_id'] as String, id as String, false);
        })),
      PrivateSelectContext() => Future.wait(
          userIds.map((id) => _dataStore.user.get(id as String, false))),
      _ => Future.value([]),
    };

    _interactiveComponentManager
        .dispatch(ctx.customId, [ctx, resolvedResource]);

    return switch (ctx) {
      GuildSelectContext() => dispatch(
          event: event,
          payload: (
            ctx: ctx,
            members: resolvedResource.whereType<Member>().toList()
          ),
          constraint: (String? customId) => customId == ctx.customId),
      PrivateSelectContext() => dispatch(
          event: event,
          payload: (
            ctx: ctx,
            users: resolvedResource.whereType<User>().toList()
          ),
          constraint: (String? customId) => customId == ctx.customId),
      _ => null,
    };
  }

  Future<void> _dispatchMentionableSelectMenu(
    SelectContext ctx,
    Map<String, dynamic> payload,
    DispatchEvent dispatch,
  ) async {
    final data = payload['data'] as Map<String, dynamic>;
    final resolvedData = data['resolved'] as Map<String, dynamic>;
    final values =
        List<String>.from(data['values'] as Iterable<dynamic>? ?? []);
    final guildId = payload['guild_id'] as String?;

    final List<dynamic> mentionables = [];
    for (final id in values) {
      final users = resolvedData['users'] as Map<String, dynamic>?;
      final roles = resolvedData['roles'] as Map<String, dynamic>?;
      if (users != null && users[id] != null) {
        final user = await _dataStore.user.get(id, false);
        if (user != null) {
          mentionables.add(user);
        }
      } else if (roles != null && roles[id] != null) {
        final role = await _dataStore.role.get(guildId!, id, false);
        if (role != null) {
          mentionables.add(role);
        }
      }
    }

    _interactiveComponentManager.dispatch(ctx.customId, [ctx, mentionables]);

    dispatch<GuildMentionableSelectArgs>(
      event: Event.guildMentionableSelect,
      payload: (ctx: ctx as GuildSelectContext, mentionables: mentionables),
      constraint: (String? customId) => customId == ctx.customId,
    );
  }

  Future<void> _dispatchTextSelectMenu(SelectContext ctx,
      Map<String, dynamic> payload, DispatchEvent dispatch) async {
    final List<String> resolvedText = List.from((payload['data']
        as Map<String, dynamic>)['values'] as Iterable<dynamic>);

    _interactiveComponentManager.dispatch(ctx.customId, [ctx, resolvedText]);

    return switch (ctx) {
      GuildSelectContext() => dispatch<GuildTextSelectArgs>(
          event: Event.guildTextSelect,
          payload: (ctx: ctx, values: resolvedText),
          constraint: (String? customId) => customId == ctx.customId),
      PrivateSelectContext() => dispatch<PrivateTextSelectArgs>(
          event: Event.privateTextSelect,
          payload: (ctx: ctx, values: resolvedText),
          constraint: (String? customId) => customId == ctx.customId),
      _ => _logger.warn('Select context $ctx not found'),
    };
  }
}
