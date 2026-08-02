import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mineral/src/infrastructure/services/http/response.dart';
import 'package:test/test.dart';

http.Response _rawResponse(
  String body,
  int statusCode, {
  Map<String, String> headers = const {},
  String? reasonPhrase,
}) {
  return http.Response(
    body,
    statusCode,
    headers: headers,
    reasonPhrase: reasonPhrase,
    request: http.Request(
      'DELETE',
      Uri.parse('https://discord.com/api/v10/channels/1/messages/2'),
    ),
  );
}

void main() {
  group('ResponseImpl.fromHttpResponse', () {
    test('204 with an empty body yields a typed empty map, not a throw', () {
      final response = ResponseImpl.fromHttpResponse<Map<String, dynamic>>(
        _rawResponse('', 204),
      );

      expect(response.statusCode, 204);
      expect(response.body, equals(<String, dynamic>{}));
    });

    test('200 with an empty body yields a typed empty map, not a throw', () {
      final response = ResponseImpl.fromHttpResponse<Map<String, dynamic>>(
        _rawResponse('', 200),
      );

      expect(response.body, equals(<String, dynamic>{}));
    });

    test('decodes a JSON object body', () {
      final response = ResponseImpl.fromHttpResponse<Map<String, dynamic>>(
        _rawResponse('{"id": "123", "name": "test"}', 200),
      );

      expect(response.body, equals({'id': '123', 'name': 'test'}));
    });

    test('decodes a JSON array body into a list of maps', () {
      final response =
          ResponseImpl.fromHttpResponse<List<Map<String, dynamic>>>(
            _rawResponse('[{"id": "1"}, {"id": "2"}]', 200),
          );

      expect(
        response.body,
        equals([
          {'id': '1'},
          {'id': '2'},
        ]),
      );
    });

    test('building the response from an HTML error body never throws', () {
      expect(
        () => ResponseImpl.fromHttpResponse<Map<String, dynamic>>(
          _rawResponse(
            '<html><body><h1>502 Bad Gateway</h1></body></html>',
            502,
          ),
        ),
        returnsNormally,
      );
    });

    test('statusCode and bodyString stay usable when the body is HTML', () {
      const html = '<html><body><h1>502 Bad Gateway</h1></body></html>';
      final response = ResponseImpl.fromHttpResponse<Map<String, dynamic>>(
        _rawResponse(html, 502),
      );

      expect(response.statusCode, 502);
      expect(response.bodyString, html);
    });

    test(
      'reading .body on a plain-text (non-JSON) response throws an '
      'HttpException carrying status/method/uri, not a bare FormatException',
      () {
        final response = ResponseImpl.fromHttpResponse<Map<String, dynamic>>(
          _rawResponse('You are being rate limited.', 429),
        );

        expect(
          () => response.body,
          throwsA(
            isA<HttpException>()
                .having((e) => e.message, 'message', contains('429'))
                .having((e) => e.message, 'message', contains('DELETE'))
                .having(
                  (e) => e.uri.toString(),
                  'uri',
                  contains('/channels/1/messages/2'),
                ),
          ),
        );
      },
    );

    test(
      'reading .body on a non-JSON response returns null when T is nullable',
      () {
        final response = ResponseImpl.fromHttpResponse<Map<String, dynamic>?>(
          _rawResponse('plain text ban message', 403),
        );

        expect(response.body, isNull);
      },
    );
  });
}
