import 'package:mineral/src/domains/services/http/http.dart';
import 'package:mineral/src/infrastructure/services/http/request.dart';
import 'package:test/test.dart';

void main() {
  group('Request', () {
    group('Request.json', () {
      test('creates a json request with correct type', () {
        final request = Request.json(endpoint: '/channels/123');
        expect(request.type, RequestType.json);
      });

      test('parses endpoint as URI', () {
        final request = Request.json(endpoint: '/channels/123');
        expect(request.url.path, '/channels/123');
      });

      test('includes Content-Type application/json header', () {
        final request = Request.json(endpoint: '/test');
        final hasContentType = request.headers.any(
          (h) => h.key == 'Content-Type' && h.value == 'application/json',
        );
        expect(hasContentType, isTrue);
      });

      test('stores body', () {
        final request = Request.json(endpoint: '/test', body: {'key': 'value'});
        expect(request.body, {'key': 'value'});
      });

      test('method is null by default', () {
        final request = Request.json(endpoint: '/test');
        expect(request.method, isNull);
      });

      test('stores custom headers', () {
        final request = Request.json(
          endpoint: '/test',
          headers: {Header('X-Custom', 'val')},
        );
        final hasCustom = request.headers.any(
          (h) => h.key == 'X-Custom' && h.value == 'val',
        );
        expect(hasCustom, isTrue);
      });

      test('defaults to empty query parameters', () {
        final request = Request.json(endpoint: '/test');
        expect(request.queryParameters, isEmpty);
      });

      test('stores query parameters', () {
        final request = Request.json(
          endpoint: '/test',
          queryParameters: {'limit': '10'},
        );
        expect(request.queryParameters['limit'], '10');
      });

      test('files list is empty', () {
        final request = Request.json(endpoint: '/test');
        expect(request.files, isEmpty);
      });
    });

    group('Request.formData', () {
      test('creates a formData request with correct type', () {
        final request = Request.formData(endpoint: '/test');
        expect(request.type, RequestType.formData);
      });

      test('includes Content-Type multipart/form-data header', () {
        final request = Request.formData(endpoint: '/test');
        final hasContentType = request.headers.any(
          (h) => h.key == 'Content-Type' && h.value == 'multipart/form-data',
        );
        expect(hasContentType, isTrue);
      });

      test('defaults to empty files', () {
        final request = Request.formData(endpoint: '/test');
        expect(request.files, isEmpty);
      });
    });

    group('Request.auto', () {
      test('returns json request when no files', () {
        final request = Request.auto(endpoint: '/test', body: {'a': 'b'});
        expect(request.type, RequestType.json);
      });

      test('returns json request when files list is empty', () {
        final request = Request.auto(
          endpoint: '/test',
          body: {'a': 'b'},
          files: [],
        );
        expect(request.type, RequestType.json);
      });
    });

    group('copyWith', () {
      test('copies with new method', () {
        final original = Request.json(endpoint: '/test');
        final copy = original.copyWith(method: 'POST');

        expect(copy.method, 'POST');
        expect(original.method, isNull);
      });

      test('copies with new url', () {
        final original = Request.json(endpoint: '/test');
        final newUri = Uri.parse('/other');
        final copy = original.copyWith(url: newUri);

        expect(copy.url.path, '/other');
        expect(original.url.path, '/test');
      });

      test('merges headers', () {
        final original = Request.json(endpoint: '/test');
        final copy = original.copyWith(headers: {Header('X-New', 'val')});

        final hasNew = copy.headers.any(
          (h) => h.key == 'X-New' && h.value == 'val',
        );
        expect(hasNew, isTrue);

        // Original content-type should still be there
        final hasContentType = copy.headers.any((h) => h.key == 'Content-Type');
        expect(hasContentType, isTrue);
      });

      test('merges query parameters', () {
        final original = Request.json(
          endpoint: '/test',
          queryParameters: {'a': '1'},
        );
        final copy = original.copyWith(queryParameters: {'b': '2'});

        expect(copy.queryParameters['a'], '1');
        expect(copy.queryParameters['b'], '2');
      });

      test('preserves original values when not overridden', () {
        final original = Request.json(
          endpoint: '/test',
          method: 'GET',
          body: {'key': 'val'},
        );
        final copy = original.copyWith(method: 'POST');

        expect(copy.body, {'key': 'val'});
        expect(copy.type, RequestType.json);
        expect(copy.url.path, '/test');
      });
    });
  });
}
