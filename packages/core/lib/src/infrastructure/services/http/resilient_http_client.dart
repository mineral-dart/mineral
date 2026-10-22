import 'dart:io';
import 'dart:math';

import 'package:mineral/services.dart';

/// Decorator around [HttpClientContract] that retries transient failures
/// (HTTP 500/502/503/504 and [SocketException]) with exponential backoff.
///
/// Only idempotent verbs (GET, PUT, DELETE) are retried. POST and PATCH are
/// never retried, neither on 5xx nor on [SocketException]: the server may
/// already have processed the request, so a retry would duplicate its effect.
/// [send] dispatches on the request method; a null or unknown method is not
/// retried.
///
/// Rate-limit handling (429) is intentionally left to [RequestBucket].
final class ResilientHttpClient implements HttpClientContract {
  final HttpClientContract _inner;
  final int maxRetries;
  final Duration initialBackoff;
  final Duration maxBackoff;

  const ResilientHttpClient(
    this._inner, {
    this.maxRetries = 3,
    this.initialBackoff = const Duration(milliseconds: 500),
    this.maxBackoff = const Duration(seconds: 30),
  });

  @override
  HttpClientStatus get status => _inner.status;

  @override
  HttpInterceptor get interceptor => _inner.interceptor;

  @override
  HttpClientConfig get config => _inner.config;

  @override
  Future<Response<T>> get<T>(RequestContract request) =>
      _withRetry(() => _inner.get<T>(request));

  @override
  Future<Response<T>> post<T>(RequestContract request) =>
      _inner.post<T>(request);

  @override
  Future<Response<T>> put<T>(RequestContract request) =>
      _withRetry(() => _inner.put<T>(request));

  @override
  Future<Response<T>> patch<T>(RequestContract request) =>
      _inner.patch<T>(request);

  @override
  Future<Response<T>> delete<T>(RequestContract request) =>
      _withRetry(() => _inner.delete<T>(request));

  @override
  Future<Response<T>> send<T>(RequestContract request) =>
      switch (request.method?.toUpperCase()) {
        'GET' || 'PUT' || 'DELETE' => _withRetry(() => _inner.send<T>(request)),
        _ => _inner.send<T>(request),
      };

  Future<Response<T>> _withRetry<T>(
    Future<Response<T>> Function() action,
  ) async {
    for (var attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await action();
        if (_isRetryable(response.statusCode) && attempt < maxRetries) {
          await Future.delayed(_backoffFor(attempt));
          continue;
        }
        return response;
      } on SocketException {
        if (attempt >= maxRetries) {
          rethrow;
        }
        await Future.delayed(_backoffFor(attempt));
      }
    }
    // Unreachable: the loop always returns or rethrows before exhausting.
    throw StateError('ResilientHttpClient: retry loop exhausted');
  }

  Duration _backoffFor(int attempt) {
    final raw = initialBackoff * pow(2, attempt).toInt();
    return raw < maxBackoff ? raw : maxBackoff;
  }

  bool _isRetryable(int statusCode) =>
      statusCode == 500 ||
      statusCode == 502 ||
      statusCode == 503 ||
      statusCode == 504;
}
