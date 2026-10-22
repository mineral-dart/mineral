import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/interactions/select_interaction_create_packet.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:mineral/src/testing/fake_logger.dart';
import 'package:test/test.dart';

import '../helpers/fake_entity_context.dart';
import '../helpers/fake_marshaller.dart';

final class _Recorder implements InteractiveComponentManagerContract {
  final List<String> log;
  final List<List> params = [];

  _Recorder(this.log);

  @override
  void Function(
    InteractiveComponent component,
    Object error,
    StackTrace stackTrace,
  )?
  onComponentError;

  @override
  void register(InteractiveComponent component) {}

  @override
  Future<void> dispatch(String customId, List params) async {
    log.add('component');
    this.params.add(params);
  }

  @override
  T get<T extends InteractiveComponent>(String customId) =>
      throw UnimplementedError();
}

final class _UserPart implements UserPartContract {
  final List<Object> requested = [];

  @override
  Future<User?> get(Object id, bool force) async {
    requested.add(id);
    return null;
  }
}

final class _RolePart implements RolePartContract {
  int calls = 0;

  @override
  Future<Role?> get(Object guildId, Object id, bool force) async {
    calls++;
    return null;
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

final class _ChannelPart implements ChannelPartContract {
  int fetches = 0;

  @override
  Future<Map<Snowflake, T>> fetch<T extends Channel>(
    Object guildId,
    bool force,
  ) async {
    fetches++;
    return {};
  }

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

final class _DataStore implements DataStoreContract {
  @override
  final _UserPart user = _UserPart();
  @override
  final _RolePart role = _RolePart();
  @override
  final _ChannelPart channel = _ChannelPart();

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      throw UnimplementedError(invocation.memberName.toString());
}

Map<String, dynamic> _payload({
  required ComponentType type,
  required bool guild,
  Map<String, dynamic> resolved = const {},
  List<String> values = const [],
}) {
  return {
    'id': '1100000000000000001',
    'application_id': '1100000000000000002',
    'type': InteractionType.messageComponent.value,
    'data': {
      'component_type': type.value,
      'custom_id': 'menu',
      'values': values,
      'resolved': resolved,
    },
    'channel_id': '1100000000000000003',
    'token': 'interaction-token',
    'version': 1,
    'message': {'id': '1100000000000000005'},
    if (guild) ...{
      'guild_id': '1100000000000000007',
      'member': {
        'user': {'id': '1100000000000000004'},
      },
    } else
      'user': {'id': '1100000000000000004'},
  };
}

ShardMessage<dynamic> _msg(Map<String, dynamic> payload) => ShardMessage(
  type: 'INTERACTION_CREATE',
  opCode: OpCode.dispatch,
  sequence: 1,
  payload: payload,
);

void main() {
  late List<String> log;
  late _Recorder components;
  late _DataStore dataStore;
  late SelectInteractionCreatePacket packet;
  late List<Event> events;
  late List<Object> payloads;

  void dispatch<T extends Object>({
    required Event event,
    required T payload,
    bool Function(String?)? constraint,
  }) {
    log.add('event');
    events.add(event);
    payloads.add(payload);
  }

  setUp(() {
    log = [];
    events = [];
    payloads = [];
    components = _Recorder(log);
    dataStore = _DataStore();
    final ctx = fakeEntityContext(dataStore: dataStore);
    packet = SelectInteractionCreatePacket(
      logger: FakeLogger(),
      marshaller: FakeMarshaller(),
      dataStore: dataStore,
      interactiveComponent: components,
      entityContext: ctx,
    );
  });

  group('mentionable select', () {
    test('in a DM resolves users only, never touches roles, and dispatches '
        'the private event after the component', () async {
      await packet.listen(
        _msg(
          _payload(
            type: ComponentType.mentionableSelectMenu,
            guild: false,
            values: ['1100000000000000009', '1100000000000000010'],
            resolved: {
              'users': {'1100000000000000009': {}},
              'roles': {'1100000000000000010': {}},
            },
          ),
        ),
        dispatch,
      );

      expect(dataStore.user.requested, ['1100000000000000009']);
      expect(dataStore.role.calls, 0);
      expect(log, ['component', 'event']);
      expect(events, [Event.privateMentionableSelect]);
      expect(
        (payloads.single as PrivateMentionableSelectArgs).ctx,
        isA<PrivateSelectContext>(),
      );
    });

    test('in a guild resolves roles and dispatches the guild event after '
        'the component', () async {
      await packet.listen(
        _msg(
          _payload(
            type: ComponentType.mentionableSelectMenu,
            guild: true,
            values: ['1100000000000000010'],
            resolved: {
              'roles': {'1100000000000000010': {}},
            },
          ),
        ),
        dispatch,
      );

      expect(dataStore.role.calls, 1);
      expect(log, ['component', 'event']);
      expect(events, [Event.guildMentionableSelect]);
    });
  });

  group('channel select', () {
    test('in a DM skips the guild fetch, runs the component with no '
        'channels and dispatches no event', () async {
      await packet.listen(
        _msg(
          _payload(
            type: ComponentType.channelSelectMenu,
            guild: false,
            resolved: {
              'channels': {'1100000000000000020': {}},
            },
          ),
        ),
        dispatch,
      );

      expect(dataStore.channel.fetches, 0);
      expect(log, ['component']);
      expect(components.params.single[1], isEmpty);
      expect(events, isEmpty);
    });

    test('in a guild fetches channels and dispatches the guild event after '
        'the component', () async {
      await packet.listen(
        _msg(
          _payload(
            type: ComponentType.channelSelectMenu,
            guild: true,
            resolved: {
              'channels': {'1100000000000000020': {}},
            },
          ),
        ),
        dispatch,
      );

      expect(dataStore.channel.fetches, 1);
      expect(log, ['component', 'event']);
      expect(events, [Event.guildChannelSelect]);
    });
  });
}
