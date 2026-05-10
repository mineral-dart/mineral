import 'package:mineral/contracts.dart';
import 'package:mineral/src/infrastructure/internals/packets/listeners/interactions/button_interaction_create_packet.dart';
import 'package:mineral/src/testing/fake_logger.dart';
import 'package:test/test.dart';

final class _NoopInteractiveComponent implements InteractiveComponentManagerContract {
  @override
  void register(InteractiveComponent component) {}
  @override
  void dispatch(String customId, List params) {}
  @override
  T get<T extends InteractiveComponent>(String customId) =>
      throw UnimplementedError();
}

void main() {
  group('ButtonInteractionCreatePacket.findButtonByCustomId', () {
    late ButtonInteractionCreatePacket packet;

    setUp(() {
      packet = ButtonInteractionCreatePacket(
        logger: FakeLogger(),
        interactiveComponent: _NoopInteractiveComponent(),
      );
    });

    test('returns null when customId is not found in components', () {
      final payload = {
        'message': {
          'components': [
            {
              'components': [
                {'custom_id': 'other_button', 'type': 2},
              ]
            }
          ]
        }
      };

      // BEFORE fix: this test never completed (completer was never resolved)
      // AFTER fix: returns null immediately
      final result = packet.findButtonByCustomId(payload, 'missing_id');
      expect(result, isNull);
    });

    test('returns null when components list is null', () {
      final payload = {
        'message': {'components': null}
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
              ]
            }
          ]
        }
      };

      final result = packet.findButtonByCustomId(payload, 'my_button');
      expect(result, isNotNull);
      expect(result!['custom_id'], equals('my_button'));
    });

    test('returns the first matching component when multiple buttons exist',
        () {
      final payload = {
        'message': {
          'components': [
            {
              'components': [
                {'custom_id': 'btn_a', 'type': 2},
                {'custom_id': 'btn_b', 'type': 2},
              ]
            }
          ]
        }
      };

      final result = packet.findButtonByCustomId(payload, 'btn_b');
      expect(result, isNotNull);
      expect(result!['custom_id'], equals('btn_b'));
    });

    test('finds component across multiple action rows', () {
      final payload = {
        'message': {
          'components': [
            {
              'components': [
                {'custom_id': 'row1_btn', 'type': 2},
              ]
            },
            {
              'components': [
                {'custom_id': 'row2_btn', 'type': 2},
              ]
            }
          ]
        }
      };

      final result = packet.findButtonByCustomId(payload, 'row2_btn');
      expect(result, isNotNull);
      expect(result!['custom_id'], equals('row2_btn'));
    });
  });
}
