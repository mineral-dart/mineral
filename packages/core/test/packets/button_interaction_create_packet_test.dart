import 'package:mineral/api.dart';
import 'package:mineral/contracts.dart';
import 'package:mineral/events.dart';
import 'package:mineral/src/domains/services/wss/constants/op_code.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/interactions/button_interaction_create_packet.dart';
import 'package:mineral/src/infrastructure/internals/wss/shard_message.dart';
import 'package:mineral/src/testing/fake_logger.dart';
import 'package:test/test.dart';

import '../helpers/fake_entity_context.dart';

final class _NoopInteractiveComponent
    implements InteractiveComponentManagerContract {
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
  Future<void> dispatch(String customId, List params) async {}
  @override
  T get<T extends InteractiveComponent>(String customId) =>
      throw UnimplementedError();
}

/// Records every [dispatch] call so tests can assert an
/// [InteractiveButton] would actually have fired.
final class _RecordingInteractiveComponent
    implements InteractiveComponentManagerContract {
  final List<({String customId, List params})> calls = [];

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
    calls.add((customId: customId, params: params));
  }

  @override
  T get<T extends InteractiveComponent>(String customId) =>
      throw UnimplementedError();
}

/// A realistic DM MESSAGE_COMPONENT (button) interaction payload.
///
/// Verified against Discord's Interaction object docs
/// (https://docs.discord.com/developers/interactions/receiving-and-responding):
/// `member` is only present for guild interactions; DM interactions carry a
/// top-level `user` object instead and omit `member`/`guild`/`guild_id`
/// entirely. `channel_id` is present in both cases.
Map<String, dynamic> _dmButtonPayload({String customId = 'confirm_button'}) {
  return {
    'id': '1100000000000000001',
    'application_id': '1100000000000000002',
    'type': InteractionType.messageComponent.value,
    'data': {
      'component_type': ComponentType.button.value,
      'custom_id': customId,
    },
    'channel_id': '1100000000000000003',
    'token': 'interaction-token',
    'version': 1,
    'user': {'id': '1100000000000000004', 'username': 'someuser'},
    'message': {
      'id': '1100000000000000005',
      'channel_id': '1100000000000000003',
      'interaction_metadata': {'id': '1100000000000000006', 'type': 2},
      'components': [
        {
          'type': 1,
          'components': [
            {
              'type': ComponentType.button.value,
              'style': 1,
              'custom_id': customId,
              'label': 'Confirm',
            },
          ],
        },
      ],
    },
  };
}

ShardMessage<dynamic> _dmMsg(Map<String, dynamic> payload) => ShardMessage(
  type: 'INTERACTION_CREATE',
  opCode: OpCode.dispatch,
  sequence: 1,
  payload: payload,
);

void main() {
  group('ButtonInteractionCreatePacket.findButtonByCustomId', () {
    late ButtonInteractionCreatePacket packet;

    setUp(() {
      packet = ButtonInteractionCreatePacket(
        logger: FakeLogger(),
        interactiveComponent: _NoopInteractiveComponent(),
        ctx: fakeEntityContext(),
      );
    });

    test('returns null when customId is not found in components', () {
      final payload = {
        'message': {
          'components': [
            {
              'components': [
                {'custom_id': 'other_button', 'type': 2},
              ],
            },
          ],
        },
      };

      // BEFORE fix: this test never completed (completer was never resolved)
      // AFTER fix: returns null immediately
      final result = packet.findButtonByCustomId(payload, 'missing_id');
      expect(result, isNull);
    });

    test('returns null when components list is null', () {
      final payload = {
        'message': {'components': null},
      };

      final result = packet.findButtonByCustomId(payload, 'any');
      expect(result, isNull);
    });

    test('returns the correct component when customId matches', () {
      final payload = {
        'message': {
          'components': [
            {
              'components': [
                {'custom_id': 'my_button', 'type': 2, 'style': 1},
              ],
            },
          ],
        },
      };

      final result = packet.findButtonByCustomId(payload, 'my_button');
      expect(result, isNotNull);
      expect(result!['custom_id'], equals('my_button'));
    });

    test(
      'returns the first matching component when multiple buttons exist',
      () {
        final payload = {
          'message': {
            'components': [
              {
                'components': [
                  {'custom_id': 'btn_a', 'type': 2},
                  {'custom_id': 'btn_b', 'type': 2},
                ],
              },
            ],
          },
        };

        final result = packet.findButtonByCustomId(payload, 'btn_b');
        expect(result, isNotNull);
        expect(result!['custom_id'], equals('btn_b'));
      },
    );

    test('finds component across multiple action rows', () {
      final payload = {
        'message': {
          'components': [
            {
              'components': [
                {'custom_id': 'row1_btn', 'type': 2},
              ],
            },
            {
              'components': [
                {'custom_id': 'row2_btn', 'type': 2},
              ],
            },
          ],
        },
      };

      final result = packet.findButtonByCustomId(payload, 'row2_btn');
      expect(result, isNotNull);
      expect(result!['custom_id'], equals('row2_btn'));
    });
  });

  group('ButtonInteractionCreatePacket.listen - private (DM) button clicks', () {
    late _RecordingInteractiveComponent componentManager;
    late ButtonInteractionCreatePacket packet;

    setUp(() {
      componentManager = _RecordingInteractiveComponent();
      packet = ButtonInteractionCreatePacket(
        logger: FakeLogger(),
        interactiveComponent: componentManager,
        ctx: fakeEntityContext(),
      );
    });

    // Regression test for defect 1: the enum lookup compared ButtonType
    // against targetButton['custom_id'] (always a mismatch) instead of
    // targetButton['type'], so the handler warned and returned before ever
    // dispatching anything.
    test(
      'dispatches Event.privateButtonClick for a realistic DM button click',
      () async {
        Event? capturedEvent;
        PrivateButtonContext? capturedCtx;

        void dispatch<T extends Object>({
          required Event event,
          required T payload,
          bool Function(String?)? constraint,
        }) {
          capturedEvent = event;
          capturedCtx = (payload as PrivateButtonClickArgs).ctx;
        }

        await packet.listen(_dmMsg(_dmButtonPayload()), dispatch);

        expect(
          capturedEvent,
          equals(Event.privateButtonClick),
          reason:
              'a DM button click with a realistic custom_id must dispatch '
              'Event.privateButtonClick; the enum lookup must compare '
              "against targetButton['type'], not targetButton['custom_id']",
        );
        expect(capturedCtx, isNotNull);
        expect(capturedCtx!.customId, equals('confirm_button'));
      },
    );

    // Regression test for defect 3: Discord omits `member` on DM
    // interactions and sends `user` at the top level instead. The old code
    // cast payload['member'], which is null in a DM and throws.
    test(
      'builds PrivateButtonContext.authorId from payload["user"], not '
      'payload["member"]',
      () async {
        PrivateButtonContext? capturedCtx;

        void dispatch<T extends Object>({
          required Event event,
          required T payload,
          bool Function(String?)? constraint,
        }) {
          capturedCtx = (payload as PrivateButtonClickArgs).ctx;
        }

        await packet.listen(_dmMsg(_dmButtonPayload()), dispatch);

        expect(capturedCtx, isNotNull);
        expect(
          capturedCtx!.authorId,
          equals(Snowflake('1100000000000000004')),
        );
      },
    );

    // Regression test for defect 2: the private handler never called
    // _interactiveComponentManager.dispatch, so a registered
    // InteractiveButton would never fire for a DM button click.
    test('dispatches the click to the interactive component manager', () async {
      void dispatch<T extends Object>({
        required Event event,
        required T payload,
        bool Function(String?)? constraint,
      }) {}

      await packet.listen(_dmMsg(_dmButtonPayload()), dispatch);

      expect(componentManager.calls, hasLength(1));
      expect(componentManager.calls.single.customId, equals('confirm_button'));
      expect(componentManager.calls.single.params, hasLength(1));
      expect(
        componentManager.calls.single.params.single,
        isA<PrivateButtonContext>(),
      );
    });
  });

  group('ButtonInteractionCreatePacket.listen - guild button clicks', () {
    // The guild and private paths share _resolveButtonType and
    // _dispatchButtonClick; this guards that the shared helpers still
    // behave correctly for the guild path (TCtx = GuildButtonContext),
    // since no other test exercises _handleServerButton via listen().
    Map<String, dynamic> guildButtonPayload({String customId = 'confirm'}) {
      return {
        'id': '2100000000000000001',
        'application_id': '2100000000000000002',
        'type': InteractionType.messageComponent.value,
        'data': {
          'component_type': ComponentType.button.value,
          'custom_id': customId,
        },
        'guild': {'id': '2100000000000000003'},
        'token': 'interaction-token',
        'version': 1,
        'message': {
          'id': '2100000000000000004',
          'channel_id': '2100000000000000005',
          'interaction_metadata': {'id': '2100000000000000006', 'type': 2},
          'components': [
            {
              'type': 1,
              'components': [
                {
                  'type': ComponentType.button.value,
                  'style': 1,
                  'custom_id': customId,
                  'label': 'Confirm',
                },
              ],
            },
          ],
        },
      };
    }

    test(
      'dispatches Event.guildButtonClick and notifies the component manager',
      () async {
        final componentManager = _RecordingInteractiveComponent();
        final packet = ButtonInteractionCreatePacket(
          logger: FakeLogger(),
          interactiveComponent: componentManager,
          ctx: fakeEntityContext(),
        );

        Event? capturedEvent;
        GuildButtonContext? capturedCtx;

        void dispatch<T extends Object>({
          required Event event,
          required T payload,
          bool Function(String?)? constraint,
        }) {
          capturedEvent = event;
          capturedCtx = (payload as GuildButtonClickArgs).ctx;
        }

        await packet.listen(_dmMsg(guildButtonPayload()), dispatch);

        expect(capturedEvent, equals(Event.guildButtonClick));
        expect(capturedCtx, isNotNull);
        expect(capturedCtx!.customId, equals('confirm'));
        expect(componentManager.calls, hasLength(1));
        expect(componentManager.calls.single.customId, equals('confirm'));
        expect(
          componentManager.calls.single.params.single,
          isA<GuildButtonContext>(),
        );
      },
    );
  });
}
