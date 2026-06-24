import 'package:mineral/src/infrastructure/services/http/header.dart';
import 'package:mineral/src/infrastructure/services/http/response.dart';

/// A configurable [Response] for use in tests.
final class FakeResponse<T> implements Response<T> {
  @override
  final int statusCode;

  @override
  final Set<Header> headers;

  @override
  final String bodyString;

  @override
  final T body;

  @override
  final Uri uri;

  @override
  final String? reasonPhrase = null;

  @override
  final String method;

  FakeResponse(
    this.statusCode,
    this.body, {
    this.bodyString = '',
    this.method = 'GET',
    this.headers = const {},
    Uri? uri,
  }) : uri = uri ?? Uri.parse('https://discord.com/api/v10/test');

  /// Convenience: a successful 200 response with an empty JSON body.
  static FakeResponse<Map<String, dynamic>> ok([
    Map<String, dynamic> body = const {},
  ]) =>
      FakeResponse(200, body, bodyString: '{}');

  /// Convenience: a 500 response.
  static FakeResponse<Map<String, dynamic>> guildError() =>
      FakeResponse(500, const {}, bodyString: 'Internal Guild Error');
}
