import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:mineral/src/infrastructure/services/http/header.dart';

abstract interface class Response<T> {
  abstract final int statusCode;
  abstract final Set<Header> headers;
  abstract final String bodyString;
  abstract final T body;

  Uri get uri;

  String? get reasonPhrase;

  String get method;
}

final class ResponseImpl<T> implements Response<T> {
  @override
  final int statusCode;

  @override
  final Set<Header> headers;

  @override
  final String bodyString;

  @override
  final Uri uri;

  @override
  final String? reasonPhrase;

  @override
  final String method;

  /// The successfully JSON-decoded body (a `Map`, `List`, or JSON scalar).
  /// `null` whenever [_decodeError] is set.
  final Object? _decoded;

  /// Set when [bodyString] could not be parsed as JSON — e.g. an HTML error
  /// page or a plain-text ban message served by Cloudflare in front of
  /// Discord. Decoding is never allowed to throw while building this
  /// response: [statusCode]/[headers]/[bodyString] stay usable (the retry
  /// and error-reporting paths only need those), and the failure is only
  /// surfaced, as a typed exception, if something actually reads [body].
  final FormatException? _decodeError;

  ResponseImpl._({
    required this.statusCode,
    required this.headers,
    required this.bodyString,
    required Object? decoded,
    required FormatException? decodeError,
    required this.uri,
    required this.reasonPhrase,
    required this.method,
  }) : _decoded = decoded,
       _decodeError = decodeError;

  @override
  T get body {
    final decodeError = _decodeError;
    if (decodeError != null) {
      if (null is T) {
        return null as T;
      }

      throw HttpException(
        'Could not decode response body as JSON for $method $uri '
        '(status $statusCode): ${decodeError.message}',
        uri: uri,
      );
    }

    try {
      final decoded = _decoded;
      if (decoded is List) {
        return decoded.cast<Map<String, dynamic>>() as T;
      }
      return decoded as T;
      // ignore: avoid_catching_errors, fall back to null for nullable T instead of a raw cast TypeError
    } on TypeError {
      if (null is T) {
        return null as T;
      }
      rethrow;
    }
  }

  static ResponseImpl<T> fromHttpResponse<T>(http.Response response) {
    Object? decoded;
    FormatException? decodeError;

    if (response.body.isEmpty) {
      decoded = <String, dynamic>{};
    } else {
      try {
        decoded = jsonDecode(response.body);
      } on FormatException catch (e) {
        decodeError = e;
      }
    }

    return ResponseImpl<T>._(
      statusCode: response.statusCode,
      headers: response.headers.entries
          .map((entry) => Header(entry.key, entry.value))
          .toSet(),
      bodyString: response.body,
      decoded: decoded,
      decodeError: decodeError,
      uri: response.request!.url,
      reasonPhrase: response.reasonPhrase,
      method: response.request!.method,
    );
  }
}
