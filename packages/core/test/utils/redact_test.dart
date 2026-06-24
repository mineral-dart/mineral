import 'package:mineral/src/domains/common/utils/redact.dart';
import 'package:test/test.dart';

void main() {
  group('redactSensitiveFields', () {
    tearDown(resetSensitiveKeys);

    test('redacts default keys (token, password, secret, authorization)', () {
      final out = redactSensitiveFields({
        'token': 'abc',
        'password': 'p',
        'secret': 's',
        'authorization': 'Bot xyz',
        'safe': 'kept',
      });
      expect(out['token'], '***');
      expect(out['password'], '***');
      expect(out['secret'], '***');
      expect(out['authorization'], '***');
      expect(out['safe'], 'kept');
    });

    test(
      'redacts the new additions (api_key, refresh_token, client_secret, webhook_url)',
      () {
        final out = redactSensitiveFields({
          'api_key': 'k',
          'refresh_token': 'r',
          'access_token': 'a',
          'client_secret': 'cs',
          'webhook_url': 'https://hook',
          'private_key': 'pk',
        });
        expect(out.values, everyElement('***'));
      },
    );

    test('matches keys case-insensitively', () {
      final out = redactSensitiveFields({
        'Token': 'a',
        'AUTHORIZATION': 'b',
        'Refresh_Token': 'c',
      });
      expect(out['Token'], '***');
      expect(out['AUTHORIZATION'], '***');
      expect(out['Refresh_Token'], '***');
    });

    test('regex pattern matches *_token / *_secret / *_key suffixes', () {
      final out = redactSensitiveFields({
        'discord_token': 'a',
        'webhook_secret': 'b',
        'signing_key': 'c',
        'tokenizer': 'safe',
        'key_id': 'safe',
      });
      expect(out['discord_token'], '***');
      expect(out['webhook_secret'], '***');
      expect(out['signing_key'], '***');
      expect(out['tokenizer'], 'safe');
      expect(out['key_id'], 'safe');
    });

    test('regex pattern matches x-*-signature headers', () {
      final out = redactSensitiveFields({
        'x-signature-ed25519': 'sig',
        'x-discord-signature': 'sig',
        'x-request-id': 'safe',
      });
      expect(out['x-signature-ed25519'], '***');
      expect(out['x-discord-signature'], '***');
      expect(out['x-request-id'], 'safe');
    });

    test('recurses into nested maps', () {
      final out = redactSensitiveFields({
        'outer': {
          'inner': {'token': 'leak', 'safe': 'kept'},
        },
      });
      final inner = (out['outer'] as Map)['inner'] as Map;
      expect(inner['token'], '***');
      expect(inner['safe'], 'kept');
    });

    test('recurses into lists of maps', () {
      final out = redactSensitiveFields({
        'items': [
          {'token': 'a', 'safe': 'kept'},
          {'password': 'b'},
        ],
      });
      final items = out['items'] as List;
      expect((items[0] as Map)['token'], '***');
      expect((items[0] as Map)['safe'], 'kept');
      expect((items[1] as Map)['password'], '***');
    });

    test('addSensitiveKey extends the default list', () {
      addSensitiveKey('custom_field');
      final out = redactSensitiveFields({'custom_field': 'x', 'other': 'kept'});
      expect(out['custom_field'], '***');
      expect(out['other'], 'kept');
    });

    test('addSensitivePattern extends the default patterns', () {
      addSensitivePattern(RegExp(r'^prefix_'));
      final out = redactSensitiveFields({
        'prefix_anything': 'x',
        'other': 'kept',
      });
      expect(out['prefix_anything'], '***');
      expect(out['other'], 'kept');
    });

    test('resetSensitiveKeys removes added entries', () {
      addSensitiveKey('temp');
      resetSensitiveKeys();
      final out = redactSensitiveFields({'temp': 'kept'});
      expect(out['temp'], 'kept');
    });
  });
}
