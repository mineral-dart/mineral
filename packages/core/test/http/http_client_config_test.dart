import 'package:mineral/src/domains/services/http/http.dart';
import 'package:mineral/src/infrastructure/services/http/http_client_config.dart';
import 'package:test/test.dart';

void main() {
  group('HttpClientConfigImpl', () {
    test('stores uri', () {
      final config = HttpClientConfigImpl(
        uri: Uri.parse('https://discord.com/api/v10'),
      );
      expect(config.uri.host, 'discord.com');
      expect(config.uri.path, '/api/v10');
      expect(config.uri.scheme, 'https');
    });

    test('defaults to empty headers set', () {
      final config = HttpClientConfigImpl(
        uri: Uri.parse('https://discord.com'),
      );
      expect(config.headers, isEmpty);
    });

    test('stores provided headers', () {
      final headers = {
        Header.authorization('Bot token123'),
        Header.userAgent('Mineral/4.2.0'),
      };

      final config = HttpClientConfigImpl(
        uri: Uri.parse('https://discord.com'),
        headers: headers,
      );

      expect(config.headers, hasLength(2));
    });

    test('headers are mutable', () {
      final config = HttpClientConfigImpl(
        uri: Uri.parse('https://discord.com'),
      );
      config.headers.add(Header.authorization('Bot token'));
      expect(config.headers, hasLength(1));
    });
  });
}
