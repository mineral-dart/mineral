import 'package:mineral/src/infrastructure/internals/datastore/route_key.dart';
import 'package:test/test.dart';

void main() {
  group('RouteKey', () {
    test('preserves channel id as major parameter', () {
      final a = RouteKey('GET', '/channels/123456789012345678/messages');
      final b = RouteKey('GET', '/channels/987654321098765432/messages');
      expect(a, isNot(equals(b)));
    });

    test('preserves guild id as major parameter', () {
      final a = RouteKey('GET', '/guilds/123456789012345678/members');
      final b = RouteKey('GET', '/guilds/987654321098765432/members');
      expect(a, isNot(equals(b)));
    });

    test('replaces minor snowflakes with placeholder', () {
      final a = RouteKey(
          'GET', '/channels/111111111111111111/messages/222222222222222222');
      final b = RouteKey(
          'GET', '/channels/111111111111111111/messages/333333333333333333');
      expect(a, equals(b));
    });

    test('different methods produce different keys', () {
      final get = RouteKey('GET', '/channels/111111111111111111');
      final del = RouteKey('DELETE', '/channels/111111111111111111');
      expect(get, isNot(equals(del)));
    });

    test('DELETE message has special bucket', () {
      final delMsg = RouteKey(
          'DELETE', '/channels/111111111111111111/messages/222222222222222222');
      final getMsg = RouteKey(
          'GET', '/channels/111111111111111111/messages/222222222222222222');
      expect(delMsg.normalizedPath, isNot(equals(getMsg.normalizedPath)));
    });

    test('webhook id and token preserved', () {
      final a = RouteKey('POST', '/webhooks/111111111111111111/abctoken');
      final b = RouteKey('POST', '/webhooks/222222222222222222/abctoken');
      expect(a, isNot(equals(b)));
    });

    test('reaction emoji is normalized away', () {
      final a = RouteKey('PUT',
          '/channels/111111111111111111/messages/222222222222222222/reactions/%F0%9F%94%A5/@me');
      final b = RouteKey('PUT',
          '/channels/111111111111111111/messages/333333333333333333/reactions/%F0%9F%92%A1/@me');
      expect(a, equals(b));
    });

    test('strips query string', () {
      final a = RouteKey('GET', '/users/@me?foo=bar');
      final b = RouteKey('GET', '/users/@me');
      expect(a, equals(b));
    });

    test('method is uppercased', () {
      final a = RouteKey('get', '/users/@me');
      final b = RouteKey('GET', '/users/@me');
      expect(a, equals(b));
    });

    test('hashCode is consistent with equality', () {
      final a = RouteKey('GET', '/users/@me');
      final b = RouteKey('GET', '/users/@me');
      expect(a.hashCode, equals(b.hashCode));
    });
  });
}
