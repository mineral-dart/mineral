import 'package:mineral/src/infrastructure/services/http/http_client.dart';
import 'package:mineral/src/infrastructure/services/http/http_client_config.dart';
import 'package:test/test.dart';

void main() {
  group('HttpClient constructor', () {
    test('accepts an https:// uri', () {
      final config = HttpClientConfigImpl(
        uri: Uri.parse('https://discord.com/api/v10'),
      );
      expect(() => HttpClient(config: config), returnsNormally);
    });

    test('rejects an http:// uri', () {
      final config = HttpClientConfigImpl(
        uri: Uri.parse('http://discord.com/api/v10'),
      );
      expect(() => HttpClient(config: config), throwsArgumentError);
    });

    test('rejects a non-http scheme', () {
      final config = HttpClientConfigImpl(
        uri: Uri.parse('ws://discord.com/api/v10'),
      );
      expect(() => HttpClient(config: config), throwsArgumentError);
    });
  });
}
